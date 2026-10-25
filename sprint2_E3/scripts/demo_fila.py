#!/usr/bin/env python3
"""demo_fila.py — Muestra en pantalla una fila de la tabla integrada E1+E2+E3, en vertical y legible.
Uso (desde la raíz del repo):  python sprint2_E3/scripts/demo_fila.py C003
Sólo lee el CSV ya generado por run_e3.sh; no modifica nada."""
import csv, sys
F = "sprint2_E3/out/commons-collections/INTEGRATED_E1_E2_E3_commons-collections_2025-04-19_mf50.csv"
SHOW = [("LLAVE", ["project", "artifact_id", "decision_time", "path"]),
        ("E1 · cómo está el código (SonarQube 26.6, snapshot CIMPS 4.5.0)",
         ["e1_ncloc", "e1_complexity", "e1_code_smells", "e1_sqale_index", "e1_bugs"]),
        ("E2 · historia del archivo (hasta el decision_time)",
         ["e2_prior_commits", "e2_distinct_contributors", "e2_days_since_last_change_corregido"]),
        ("E3 · con quién cambia (mis medidas)",
         ["e3_n_commits_e3", "e3_n_commits_excluded_large", "e3_ccd_k2", "e3_max_conf_k2", "e3_top_partner"]),
        ("CONTROL", ["check_e2_minus_e3", "check_e2_vs_e3_history"])]
aid = (sys.argv[1] if len(sys.argv) > 1 else "C003").upper()
with open(F, newline="", encoding="utf-8") as fh:
    row = next((r for r in csv.DictReader(fh) if r["artifact_id"] == aid), None)
if row is None:
    sys.exit(f"No encontré {aid} en {F}")
for title, cols in SHOW:
    print(f"\n{title}")
    for c in cols:
        print(f"  {c:<38} {row.get(c, '')}")
