#!/usr/bin/env python3
"""
extract_cochange.py — Extractor de co-change (familia de evidencia E3)
Proyecto: Gestión de la Deuda Técnica (continuidad post-CIMPS) — línea hotspot/co-change
Autora: Yatana Roa

Qué hace
--------
Para un proyecto y un decision_time (definido por un commit/tag exacto), recorre
ÚNICAMENTE los commits ancestros de ese commit (es decir, la historia disponible
en ese momento) y cuenta, para cada archivo seleccionado (artifact_id), con qué
otros archivos cambió en el mismo commit y cuántas veces.

Salidas (en --out):
  E3_COCHANGE_PAIRS_<tag>.csv     project, artifact_id, decision_time, path,
                                  cochanged_file, cochange_count, n_commits_focal, confidence
  E3_COCHANGE_FEATURES_<tag>.csv  project, artifact_id, decision_time, path, n_commits_e3,
                                  ccd_k2 (M1), max_conf_k2 (M2), top_partner
  E3_COMMITS_USED_<tag>.csv       lista de commits usados (sha, fechas, nº de archivos)
  E3_RUN_MANIFEST_<tag>.json      provenance: versiones, comandos, parámetros, rangos, verificación temporal

Decisiones de diseño (todas fijadas ANTES de ver resultados; ver README):
  D1  Transacción = un commit (no ventanas de tiempo).
  D2  Se excluyen merges (--no-merges): un merge repite cambios ya contados.
  D3  Universo = archivos .java bajo src/main/java que existen en el árbol del decision commit.
      Los tests se excluyen por defecto (el par Clase↔ClaseTest co-cambia por convención).
  D4  Commits con más de --max-files archivos del universo se excluyen del conteo (eventos
      globales: cambio de licencia, migraciones). Umbral por defecto 50 (decisión D-04 de G1A);
      100 (D'Ambros et al., 2009) se corre como análisis de sensibilidad.
  D5  Renombres/movimientos: rename detection de Git (-M) y mapeo de rutas antiguas a la
      ruta vigente en el decision commit.
  D6  Umbral mínimo de repetición k = 2 para las medidas M1/M2 (un par visto una sola vez
      se reporta en PAIRS pero no cuenta como acoplamiento).
"""
import argparse, csv, json, os, platform, subprocess, sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from itertools import combinations


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], check=True,
                          capture_output=True, text=True).stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, help="ruta al clon local (solo lectura)")
    ap.add_argument("--project", required=True)
    ap.add_argument("--decision-ref", required=True, help="tag o SHA que define el decision_time")
    ap.add_argument("--artifacts", required=True, help="CSV con columnas artifact_id,path")
    ap.add_argument("--out", required=True)
    ap.add_argument("--decision-time", help="etiqueta YYYY-MM-DD de la llave (por defecto, fecha del decision commit)")
    ap.add_argument("--max-files", type=int, default=50,
                    help="umbral de commit masivo; 50 = decisión D-04 de G1A, 100 = D'Ambros et al. (sensibilidad)")
    ap.add_argument("--k", type=int, default=2)
    ap.add_argument("--include-tests", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    sha = git(a.repo, "rev-list", "-1", a.decision_ref).strip()
    dt_iso = git(a.repo, "log", "-1", "--format=%cI", sha).strip()
    decision_dt = datetime.fromisoformat(dt_iso)
    decision_day = a.decision_time or decision_dt.date().isoformat()
    if decision_dt.date().isoformat() > decision_day:
        sys.exit("El decision commit es posterior a la etiqueta --decision-time")
    tag = f"{a.project}_{decision_day}_mf{a.max_files}"

    # Universo: archivos vivos en el decision commit
    tree = git(a.repo, "ls-tree", "-r", "--name-only", sha).splitlines()
    roots = ("src/main/java/",) + (("src/test/java/",) if a.include_tests else ())
    universe = {p for p in tree if p.endswith(".java") and p.startswith(roots)}

    # Artefactos focales
    artifacts = []
    with open(a.artifacts, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            aid = r.get("artifact_id") or r.get("entity_id")
            path = r.get("path") or r.get("file_path")
            artifacts.append((aid, path))
    ids = [x[0] for x in artifacts]
    if len(ids) != len(set(ids)):
        dup = sorted({i for i in ids if ids.count(i) > 1})
        sys.exit(f"artifact_id no único {dup}: la llave project+artifact_id+decision_time sería ambigua")

    # Historia disponible: SOLO ancestros del decision commit (orden: más reciente primero)
    log_cmd = ["log", "--no-merges", "-M", "--name-status",
               "--format=@@%H|%cI|%aI", sha]
    raw = git(a.repo, *log_cmd)

    commits = []  # (sha, cdate, adate, [(status, paths...)])
    cur = None
    for line in raw.splitlines():
        if line.startswith("@@"):
            h, cd, ad = line[2:].split("|")
            cur = [h, cd, ad, []]
            commits.append(cur)
        elif line.strip() and cur is not None:
            parts = line.split("\t")
            cur[3].append((parts[0], parts[1:]))

    # D5: mapeo de rutas históricas -> ruta vigente en el decision commit
    canon = {}
    def c(p):
        return canon.get(p, p)

    pair_count = Counter()
    n_commits = Counter()
    n_large = Counter()   # commits masivos excluidos que tocaron cada archivo
    used, excluded_large = [], []
    for h, cd, ad, entries in commits:          # de más reciente a más antiguo
        touched = set()
        for st, paths in entries:
            if st.startswith("R") or st.startswith("C"):
                old, new = paths[0], paths[1]
                cn = c(new)
                touched.add(cn)
                if st.startswith("R"):
                    canon[old] = cn            # commits más antiguos verán 'old' como 'cn'
            else:
                touched.add(c(paths[0]))
        s = touched & universe
        if not s:
            continue
        if len(s) > a.max_files:
            excluded_large.append((h, cd, len(s)))
            for f in s:
                n_large[f] += 1
            continue
        used.append((h, cd, ad, len(s)))
        for f in s:
            n_commits[f] += 1
        for f, g in combinations(sorted(s), 2):
            pair_count[(f, g)] += 1

    # Verificación temporal (criterio de cierre)
    max_cdate = max(datetime.fromisoformat(u[1]) for u in used)
    max_adate = max(datetime.fromisoformat(u[2]) for u in used)
    temporal_ok = max_cdate <= decision_dt and max_adate <= decision_dt \
        and max_cdate.date().isoformat() <= decision_day
    newer = git(a.repo, "rev-list", "--count", "--no-merges", f"{sha}..HEAD").strip()

    partners = defaultdict(Counter)
    for (f, g), n in pair_count.items():
        partners[f][g] = n
        partners[g][f] = n

    # PAIRS
    pairs_path = os.path.join(a.out, f"E3_COCHANGE_PAIRS_{tag}.csv")
    feats_path = os.path.join(a.out, f"E3_COCHANGE_FEATURES_{tag}.csv")
    with open(pairs_path, "w", newline="", encoding="utf-8") as fp, \
         open(feats_path, "w", newline="", encoding="utf-8") as ff:
        wp, wf = csv.writer(fp), csv.writer(ff)
        wp.writerow(["project", "artifact_id", "decision_time", "path", "cochanged_file",
                     "cochange_count", "n_commits_focal", "confidence"])
        wf.writerow(["project", "artifact_id", "decision_time", "path", "exists_at_decision",
                     "n_commits_e3", "n_commits_excluded_large", "n_partners_any", f"ccd_k{a.k}", f"max_conf_k{a.k}",
                     "top_partner", "top_partner_count"])
        for aid, path in artifacts:
            exists = path in universe
            n = n_commits.get(path, 0)
            plist = sorted(partners[path].items(), key=lambda x: (-x[1], x[0]))
            for g, cnt in plist:
                wp.writerow([a.project, aid, decision_day, path, g, cnt, n,
                             round(cnt / n, 4) if n else ""])
            strong = [(g, cnt) for g, cnt in plist if cnt >= a.k]
            m1 = len(strong)
            m2 = round(strong[0][1] / n, 4) if strong else 0.0
            top = strong[0] if strong else ("", 0)
            wf.writerow([a.project, aid, decision_day, path, int(exists), n, n_large.get(path, 0), len(plist),
                         m1, m2, top[0], top[1]])

    with open(os.path.join(a.out, f"E3_COMMITS_USED_{tag}.csv"), "w", newline="",
              encoding="utf-8") as fu:
        w = csv.writer(fu)
        w.writerow(["sha", "committer_date", "author_date", "n_universe_files", "status"])
        for h, cd, ad, k in used:
            w.writerow([h, cd, ad, k, "used"])
        for h, cd, k in excluded_large:
            w.writerow([h, cd, "", k, f"excluded_>{a.max_files}_files"])

    manifest = {
        "script": "scripts/extract_cochange.py",
        "command": " ".join(sys.argv),
        "git_log_command": "git " + " ".join(log_cmd),
        "execution_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "git_version": subprocess.run(["git", "--version"], capture_output=True, text=True).stdout.strip(),
        "python_version": platform.python_version(),
        "repo_remote": git(a.repo, "remote", "get-url", "origin").strip(),
        "repo_head_at_run": git(a.repo, "rev-parse", "HEAD").strip(),
        "project": a.project,
        "decision_ref": a.decision_ref,
        "decision_sha": sha,
        "decision_time": decision_day,
        "decision_commit_date": dt_iso,
        "params": {"max_files": a.max_files, "k": a.k, "include_tests": a.include_tests,
                   "no_merges": True, "rename_detection": "-M"},
        "universe_size": len(universe),
        "range": {"first_commit_used": used[-1][0], "first_commit_date": used[-1][1],
                  "last_commit_used": used[0][0], "last_commit_date": used[0][1]},
        "n_commits_in_history": len(commits),
        "n_commits_used": len(used),
        "n_commits_excluded_large": len(excluded_large),
        "temporal_check": {
            "max_committer_date_used": max_cdate.isoformat(),
            "max_author_date_used": max_adate.isoformat(),
            "all_dates_le_decision_time": temporal_ok,
            "only_ancestors_of_decision_commit": True,
            "commits_after_decision_in_clone_not_used": int(newer),
        },
    }
    with open(os.path.join(a.out, f"E3_RUN_MANIFEST_{tag}.json"), "w", encoding="utf-8") as fm:
        json.dump(manifest, fm, indent=2, ensure_ascii=False)

    print(json.dumps({k: manifest[k] for k in
                      ("decision_sha", "decision_time", "n_commits_used",
                       "n_commits_excluded_large", "temporal_check")}, indent=2))
    if not temporal_ok:
        sys.exit("FALLA TEMPORAL: se usó un commit posterior al decision_time")


if __name__ == "__main__":
    main()
