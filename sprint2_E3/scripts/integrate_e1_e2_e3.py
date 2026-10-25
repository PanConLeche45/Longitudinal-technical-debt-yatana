#!/usr/bin/env python3
"""
integrate_e1_e2_e3.py — Tabla integrada E1 + E2 + E3 (trabajo conjunto)
Llave de integración: project + artifact_id + decision_time

Entradas
  --e2   CSV de Willian (D3_EVOLUTION_DATASET.csv): artifact_id, decision_time, path, ...
  --e3   CSV de features de co-change (E3_COCHANGE_FEATURES_<tag>.csv)
  --e3-manifest  JSON del extractor (para la verificación temporal)
  --e1   (opcional) CSV con métricas estáticas de CIMPS, columnas: project, artifact_id
         (o path), decision_time, <métricas...>
         Si NO se entrega, se calcula un E1 PROVISIONAL (líneas físicas y no vacías del
         archivo en el decision commit, leído con `git show <sha>:<path>`), sólo para
         probar la integración. Debe reemplazarse por las métricas E1 reales de CIMPS.
Salida
  INTEGRATED_E1_E2_E3_<tag>.csv  +  INTEGRATION_CHECKS_<tag>.json
"""
import argparse, csv, json, os, subprocess, sys


def read_csv(p):
    with open(p, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--e2", required=True)
    ap.add_argument("--e3", required=True)
    ap.add_argument("--e3-manifest", required=True)
    ap.add_argument("--e1")
    ap.add_argument("--artifact-map", help="CSV artifact_id,path cuando E2 no trae un id único")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    man = json.load(open(a.e3_manifest, encoding="utf-8"))
    sha, dt = man["decision_sha"], man["decision_time"][:10]
    tag = f'{a.project}_{dt}_mf{man["params"]["max_files"]}'
    amap = {}
    if a.artifact_map:
        for r in read_csv(a.artifact_map):
            amap[r["path"]] = r["artifact_id"]

    e2 = {}
    for r in read_csv(a.e2):
        r.setdefault("path", r.get("file_path"))
        # E2 puede traer el decision_time con hora (p. ej. 2025-04-19T13:58:14+00:00):
        # la llave usa sólo la fecha; la hora queda en e2_decision_cut para trazabilidad.
        r["e2_decision_cut"] = r["decision_time"]
        r["decision_time"] = r["decision_time"][:10]
        aid = amap.get(r["path"]) or r.get("artifact_id")
        r["artifact_id"] = aid
        e2[(a.project, aid, r["decision_time"])] = r
    e3 = {(r["project"], r["artifact_id"], r["decision_time"]): r for r in read_csv(a.e3)}
    e1 = {}
    e1_source = "provisional_git_show"
    if a.e1:
        e1_source = os.path.basename(a.e1)
        for r in read_csv(a.e1):
            e1[(r["project"], r["artifact_id"], r["decision_time"])] = r

    checks = {"decision_sha": sha, "decision_time": dt, "e1_source": e1_source,
              "keys_e2": len(e2), "keys_e3": len(e3), "issues": []}
    if not man["temporal_check"]["all_dates_le_decision_time"]:
        checks["issues"].append("E3 usa commits posteriores al decision_time")

    rows = []
    for key in sorted(set(e2) | set(e3)):
        r2, r3 = e2.get(key), e3.get(key)
        if r2 is None or r3 is None:
            checks["issues"].append(f"llave sin pareja: {key} (E2={'sí' if r2 else 'no'}, E3={'sí' if r3 else 'no'})")
            continue
        if r2["decision_time"] != dt:
            checks["issues"].append(f"{key}: decision_time de E2 ≠ decision commit ({dt})")
        cref = (r2.get("commit_ref") or "").strip()
        if cref and not (sha.startswith(cref) or cref.startswith(sha)):
            checks["issues"].append(f"{key}: commit de E2 ({cref[:9]}) ≠ commit de E3 ({sha[:9]})")
        path = r2["path"]
        if path != r3["path"]:
            checks["issues"].append(f"{key}: ruta distinta entre E2 y E3")
        row = {"project": key[0], "artifact_id": key[1], "decision_time": key[2], "path": path}
        # ---- E1
        if a.e1:
            src = e1.get(key)
            if src is None:
                checks["issues"].append(f"{key}: sin métricas E1 en {e1_source}")
                src = {}
            for k, v in src.items():
                if k not in ("project", "artifact_id", "decision_time", "path"):
                    row[f"e1_{k}"] = v
        else:
            txt = subprocess.run(["git", "-C", a.repo, "show", f"{sha}:{path}"],
                                 capture_output=True, text=True).stdout
            lines = txt.splitlines()
            row["e1_prov_loc_physical"] = len(lines)
            row["e1_prov_loc_nonblank"] = sum(1 for l in lines if l.strip())
        # ---- E2 (Willian)
        for k in ("estrato", "prior_commits", "churn", "days_since_last_change",
                  "days_since_last_change_corregido", "distinct_contributors"):
            if k in r2:
                row[f"e2_{k}"] = r2[k]
        # ---- E3 (Yatana)
        for k in ("n_commits_e3", "n_commits_excluded_large", "ccd_k2", "max_conf_k2", "top_partner", "top_partner_count"):
            row[f"e3_{k}"] = r3[k]
        # ---- chequeo cruzado de identidad E2 vs E3 (no corrige, sólo marca)
        # E2 cuenta también los commits masivos; se suman para comparar lo comparable
        pc = int(r2["prior_commits"])
        n3 = int(r3["n_commits_e3"]) + int(r3.get("n_commits_excluded_large", 0))
        row["check_e2_minus_e3"] = pc - n3
        flag = n3 > 0 and pc > 1.25 * n3 and pc - n3 >= 5
        row["check_e2_vs_e3_history"] = "REVISAR_LINAJE" if flag else "ok"
        rows.append(row)

    os.makedirs(a.out, exist_ok=True)
    outp = os.path.join(a.out, f"INTEGRATED_E1_E2_E3_{tag}.csv")
    with open(outp, "w", newline="", encoding="utf-8") as fh:
        cols = []
        for r in rows:
            cols += [k for k in r if k not in cols]
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader(); w.writerows(rows)
    checks["rows"] = len(rows)
    checks["flagged_lineage"] = [r["artifact_id"] for r in rows if r["check_e2_vs_e3_history"] != "ok"]
    json.dump(checks, open(os.path.join(a.out, f"INTEGRATION_CHECKS_{tag}.json"), "w",
                           encoding="utf-8"), indent=2, ensure_ascii=False)
    print(json.dumps(checks, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
