#!/usr/bin/env python3
"""
check_temporal.py — Verificación temporal de E3 (criterio de cierre)
Uso: python check_temporal.py <dir_out_proyecto> [<dir_out_proyecto> ...]

Comprueba, para cada proyecto:
  1. Cada manifest declara all_dates_le_decision_time = true y sólo ancestros del decision commit.
  2. Monotonía: con el mismo umbral, n_commits_e3 y ccd_k2 nunca disminuyen al avanzar el
     decision_time (si bajaran, un momento anterior habría "visto" algo que el posterior no).
  3. Archivos que aún no existen en un decision_time anterior (exists_at_decision = 0).
Escribe TEMPORAL_CHECK.json en cada directorio y termina con error si algo falla.
"""
import csv, glob, json, os, sys

ok_all = True
for d in sys.argv[1:]:
    res = {"manifests": [], "monotonicity_violations": [], "not_born_yet": []}
    for m in sorted(glob.glob(os.path.join(d, "E3_RUN_MANIFEST_*.json"))):
        j = json.load(open(m, encoding="utf-8"))
        t = j["temporal_check"]
        good = t["all_dates_le_decision_time"] and t["only_ancestors_of_decision_commit"]
        ok_all &= good
        res["manifests"].append({"file": os.path.basename(m), "decision_time": j["decision_time"],
                                 "max_committer_date_used": t["max_committer_date_used"],
                                 "commits_used": j["n_commits_used"], "ok": good})
    feats = sorted(glob.glob(os.path.join(d, "E3_COCHANGE_FEATURES_*_mf50.csv")))
    series = {}
    for f in feats:                                   # nombres ordenados = orden temporal (YYYY-MM-DD)
        for r in csv.DictReader(open(f, encoding="utf-8")):
            series.setdefault(r["artifact_id"], []).append(
                (r["decision_time"], int(r["n_commits_e3"]), int(r["ccd_k2"]), r["exists_at_decision"]))
    for aid, s in series.items():
        for (t0, n0, c0, _), (t1, n1, c1, _) in zip(s, s[1:]):
            if n1 < n0 or c1 < c0:
                res["monotonicity_violations"].append([aid, t0, t1])
        res["not_born_yet"] += [[aid, t] for t, _, _, e in s if e == "0"]
    ok_all &= not res["monotonicity_violations"]
    json.dump(res, open(os.path.join(d, "TEMPORAL_CHECK.json"), "w", encoding="utf-8"),
              indent=2, ensure_ascii=False)
    print(d, "| manifests ok:", all(x["ok"] for x in res["manifests"]),
          "| violaciones de monotonía:", len(res["monotonicity_violations"]),
          "| aún no nacidos:", res["not_born_yet"])
sys.exit(0 if ok_all else "VERIFICACIÓN TEMPORAL FALLIDA")
