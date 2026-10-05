#!/usr/bin/env bash
# run_e3.sh — Reproduce TODA la evidencia E3 del Sprint 1 (ejecutar desde la raíz del repositorio)
#   bash sprint1_E3/scripts/run_e3.sh
# Requiere: git, python >= 3.8 (solo biblioteca estándar). No modifica los repositorios analizados.
set -euo pipefail
S=sprint1_E3
CC=repos/commons-collections
CL=repos/commons-lang
[ -d "$CC" ] || git clone https://github.com/apache/commons-collections.git "$CC"
[ -d "$CL" ] || git clone https://github.com/apache/commons-lang.git "$CL"
PY=$(command -v python3 || command -v python)
OCC=$S/out/commons-collections
OCL=$S/out/commons-lang

# ---- Piloto propio: commons-collections (E2 = mi D3 corregido) -------------------------
ACC=$S/data/ARTIFACTS_commons-collections.csv
for ref in rel/commons-collections-4.5.0-M3 rel/commons-collections-4.5.0; do       # T_a, T_b
  $PY $S/scripts/extract_cochange.py --repo $CC --project commons-collections \
      --decision-ref $ref --artifacts $ACC --out $OCC
done
for mf in 50 100; do                                                                 # T_c (decision_time) + sensibilidad
  $PY $S/scripts/extract_cochange.py --repo $CC --project commons-collections \
      --decision-ref e96986a5c61e8fc9e7a180579ef793253161b7c3 --decision-time 2025-11-12 \
      --max-files $mf --artifacts $ACC --out $OCC
done
$PY $S/scripts/integrate_e1_e2_e3.py --project commons-collections --repo $CC \
    --artifact-map $ACC --e2 D3_EVOLUTION_DATASET_CORREGIDO.csv \
    --e3 $OCC/E3_COCHANGE_FEATURES_commons-collections_2025-11-12_mf50.csv \
    --e3-manifest $OCC/E3_RUN_MANIFEST_commons-collections_2025-11-12_mf50.json --out $OCC

# ---- Piloto de Willian: commons-lang (E2 = su D3) ---------------------------------------
ACL=$S/data/E2_commons-lang_Willian_D3_EVOLUTION_DATASET.csv
for v in 3.18.0 3.19.0; do
  $PY $S/scripts/extract_cochange.py --repo $CL --project commons-lang \
      --decision-ref rel/commons-lang-$v --artifacts $ACL --out $OCL
done
for mf in 50 100; do
  $PY $S/scripts/extract_cochange.py --repo $CL --project commons-lang \
      --decision-ref rel/commons-lang-3.20.0 --max-files $mf --artifacts $ACL --out $OCL
done
$PY $S/scripts/integrate_e1_e2_e3.py --project commons-lang --repo $CL --e2 $ACL \
    --e3 $OCL/E3_COCHANGE_FEATURES_commons-lang_2025-11-12_mf50.csv \
    --e3-manifest $OCL/E3_RUN_MANIFEST_commons-lang_2025-11-12_mf50.json --out $OCL

$PY $S/scripts/check_temporal.py $OCC $OCL
