#!/usr/bin/env bash
# run_e3.sh — Reproduce TODA la evidencia E3 del Sprint 1 (ejecutar desde la raíz del repositorio)
#   bash sprint1_E3/scripts/run_e3.sh
# Requiere: git, python >= 3.8 (solo biblioteca estándar). No modifica los repositorios analizados.
#
# Diseño temporal (decisión D-13, 2026-10-15):
#   commons-collections — decision_time PRINCIPAL = snapshot CIMPS: rel/commons-collections-4.5.0
#                         (7f7fb0244, 2025-04-19). Artefactos = muestra seleccionada CON información
#                         ≤ ese corte (data/ARTIFACTS_commons-collections_sel_2025-04-19.csv).
#                         Momentos adicionales para la misma muestra: 4.5.0-M3 (pasado) y 2025-11-12 (posterior).
#                         Integración secundaria: muestra de G1A en 2025-11-12.
#   commons-lang        — decision_time = snapshot CIMPS 3.20.0 (598dfc163, 2025-11-12) + T3, T4 de Willian.
set -euo pipefail
S=sprint1_E3
CC=repos/commons-collections
CL=repos/commons-lang
[ -d "$CC" ] || git clone https://github.com/apache/commons-collections.git "$CC"
[ -d "$CL" ] || git clone https://github.com/apache/commons-lang.git "$CL"
PY=$(command -v python3 || command -v python)
X="$PY $S/scripts/extract_cochange.py"
I="$PY $S/scripts/integrate_e1_e2_e3.py"

# ---- commons-collections: muestra CIMPS (principal) -------------------------------------
OCC=$S/out/commons-collections
ACC=$S/data/ARTIFACTS_commons-collections_sel_2025-04-19.csv
$X --repo $CC --project commons-collections --decision-ref rel/commons-collections-4.5.0-M3 --artifacts $ACC --out $OCC
for mf in 50 100; do
  $X --repo $CC --project commons-collections --decision-ref rel/commons-collections-4.5.0 \
     --max-files $mf --artifacts $ACC --out $OCC
done
$X --repo $CC --project commons-collections --decision-ref e96986a5c61e8fc9e7a180579ef793253161b7c3 \
   --decision-time 2025-11-12 --artifacts $ACC --out $OCC
E2CC=$S/data/E2_commons-collections_2025-04-19/D3_EVOLUTION_DATASET_CORREGIDO.csv
E1ARG=""; [ -f "$S/data/E1_FILE_METRICS_commons-collections_2025-04-19.csv" ] && \
  E1ARG="--e1 $S/data/E1_FILE_METRICS_commons-collections_2025-04-19.csv"
$I --project commons-collections --repo $CC --artifact-map $ACC --e2 $E2CC $E1ARG \
   --e3 $OCC/E3_COCHANGE_FEATURES_commons-collections_2025-04-19_mf50.csv \
   --e3-manifest $OCC/E3_RUN_MANIFEST_commons-collections_2025-04-19_mf50.json --out $OCC

# ---- commons-collections: muestra de G1A en 2025-11-12 (secundaria) ---------------------
OG=$S/out/commons-collections_G1A
AG=$S/data/ARTIFACTS_commons-collections_sel_G1A_2025-11-12.csv
$X --repo $CC --project commons-collections --decision-ref e96986a5c61e8fc9e7a180579ef793253161b7c3 \
   --decision-time 2025-11-12 --artifacts $AG --out $OG
$I --project commons-collections --repo $CC --artifact-map $AG --e2 D3_EVOLUTION_DATASET_CORREGIDO.csv \
   --e3 $OG/E3_COCHANGE_FEATURES_commons-collections_2025-11-12_mf50.csv \
   --e3-manifest $OG/E3_RUN_MANIFEST_commons-collections_2025-11-12_mf50.json --out $OG

# ---- commons-lang (piloto de Willian) ----------------------------------------------------
OCL=$S/out/commons-lang
ACL=$S/data/E2_commons-lang_Willian_D3_EVOLUTION_DATASET.csv
for v in 3.18.0 3.19.0; do
  $X --repo $CL --project commons-lang --decision-ref rel/commons-lang-$v --artifacts $ACL --out $OCL
done
for mf in 50 100; do
  $X --repo $CL --project commons-lang --decision-ref rel/commons-lang-3.20.0 --max-files $mf \
     --artifacts $ACL --out $OCL
done
$I --project commons-lang --repo $CL --e2 $ACL \
   --e3 $OCL/E3_COCHANGE_FEATURES_commons-lang_2025-11-12_mf50.csv \
   --e3-manifest $OCL/E3_RUN_MANIFEST_commons-lang_2025-11-12_mf50.json --out $OCL

$PY $S/scripts/check_temporal.py $OCC $OG $OCL
