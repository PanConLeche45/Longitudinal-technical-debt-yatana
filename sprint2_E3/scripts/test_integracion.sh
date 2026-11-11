#!/usr/bin/env bash
# test_integracion.sh — pruebas positiva y negativas de la integración E1+E2+E3
# Proyecto: Gestión de la Deuda Técnica (continuidad post-CIMPS) — línea E3
#
# Comprueba que el integrador FALLA de forma explícita ante entradas inválidas y
# que no deja un CSV de apariencia correcta cuando aborta.
#
#   N1  llave duplicada en E3            -> debe salir != 0 y no escribir CSV
#   N2  archivo inexistente en el corte  -> debe registrarse en issues
#   P1  entradas correctas               -> debe salir 0 y producir las filas esperadas
#
# Uso:
#   bash sprint2_E3/scripts/test_integracion.sh <ruta_clon_commons-collections>
set -u
REPO="${1:-repos/commons-collections}"
BASE="sprint2_E3"
E2="$BASE/data/E2_commons-collections_2025-04-19/D3_EVOLUTION_DATASET_CORREGIDO.csv"
E3="$BASE/out/commons-collections/E3_COCHANGE_FEATURES_commons-collections_2025-04-19_mf50.csv"
MAN="$BASE/out/commons-collections/E3_RUN_MANIFEST_commons-collections_2025-04-19_mf50.json"
E1="$BASE/data/E1_FILE_METRICS_commons-collections_2025-04-19.csv"
MAP="$BASE/data/ARTIFACTS_commons-collections_sel_2025-04-19.csv"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FALLOS=0

integra() {  # $1 = csv E3, $2 = carpeta de salida
  python3 "$BASE/scripts/integrate_e1_e2_e3.py" \
    --project commons-collections --repo "$REPO" \
    --e2 "$E2" --e3 "$1" --e3-manifest "$MAN" --e1 "$E1" --artifact-map "$MAP" \
    --out "$2" >"$TMP/salida.txt" 2>"$TMP/error.txt"
}

echo "== N1: llave duplicada en E3 (debe abortar) =="
head -1 "$E3" >"$TMP/dup.csv"; sed -n '2p' "$E3" >>"$TMP/dup.csv"; sed -n '2p' "$E3" >>"$TMP/dup.csv"
mkdir -p "$TMP/n1"; integra "$TMP/dup.csv" "$TMP/n1"; rc=$?
n_csv=$(find "$TMP/n1" -name '*.csv' | wc -l)
if [ "$rc" -ne 0 ] && [ "$n_csv" -eq 0 ]; then
  echo "   PASA  (código $rc, 0 CSV escritos)"; head -1 "$TMP/error.txt" | sed 's/^/         /'
else
  echo "   FALLA (código $rc, $n_csv CSV escritos: debió abortar sin escribir)"; FALLOS=$((FALLOS+1))
fi

echo "== N2: archivo inexistente en el corte (debe quedar en issues) =="
python3 - "$E3" "$TMP/noexist.csv" <<'PY'
import csv, sys
rs = list(csv.DictReader(open(sys.argv[1], encoding="utf-8")))
rs[0]["exists_at_decision"] = "0"
w = csv.DictWriter(open(sys.argv[2], "w", newline="", encoding="utf-8"), fieldnames=list(rs[0]))
w.writeheader(); w.writerows(rs)
PY
mkdir -p "$TMP/n2"; integra "$TMP/noexist.csv" "$TMP/n2"
if grep -q "no existe en el árbol" "$TMP/n2"/INTEGRATION_CHECKS_*.json 2>/dev/null; then
  echo "   PASA  (registrado en issues)"
else
  echo "   FALLA (no se registró el archivo inexistente)"; FALLOS=$((FALLOS+1))
fi

echo "== P1: entradas correctas (debe integrar sin incidencias) =="
mkdir -p "$TMP/p1"; integra "$E3" "$TMP/p1"; rc=$?
filas=$(( $(wc -l < "$TMP/p1"/INTEGRATED_E1_E2_E3_*.csv 2>/dev/null || echo 1) - 1 ))
if [ "$rc" -eq 0 ] && [ "$filas" -gt 0 ]; then
  echo "   PASA  (código 0, $filas filas)"
else
  echo "   FALLA (código $rc, $filas filas)"; FALLOS=$((FALLOS+1))
fi

echo
if [ "$FALLOS" -eq 0 ]; then echo "RESULTADO: 3/3 pruebas pasan"; exit 0
else echo "RESULTADO: $FALLOS prueba(s) fallaron"; exit 1; fi
