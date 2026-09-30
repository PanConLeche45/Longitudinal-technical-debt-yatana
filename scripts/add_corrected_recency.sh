#!/usr/bin/env bash
# =============================================================================
# add_corrected_recency.sh
#
# D3 (parte 3) - Correccion de la metrica de recencia por commits masivos
#
# PROBLEMA DETECTADO (ver bitacora E-02):
# La metrica `days_since_last_change` calculada de forma ingenua toma el ultimo
# commit que toco el archivo, sin distinguir si ese commit represento trabajo
# real sobre el archivo o si fue un barrido automatico que modifico cientos de
# archivos a la vez (actualizacion de licencia, formateo global, bump de
# dependencias). En commons-collections, el commit 8ee475dcc
# ("Update Apache License URL to HTTPS", 2025-05-20) modifico 711 archivos
# cambiando UNA linea en cada uno.
#
# CONSECUENCIA: 26 de los 30 archivos del dataset aparecen como "modificados
# recientemente" cuando en realidad llevaban meses o anos sin cambios
# sustantivos. Un modelo entrenado con esta variable aprenderia ruido.
#
# SOLUCION: se define un umbral de commit masivo (por defecto 50 archivos).
# Todo commit que toque mas archivos que el umbral se considera un EVENTO
# GLOBAL DEL PROYECTO y no actividad individual del archivo. La metrica
# corregida ignora esos commits.
#
# Uso:
#   bash scripts/add_corrected_recency.sh <repo> <dataset.csv> <umbral> <salida.csv>
#
# Autor: Yatana Roa Moreno (ZS23020600)
# Proyecto: Continuidad post-CIMPS - Ruta B - Gate G1A
# =============================================================================

set -u

REPO="${1:?Falta la ruta del repositorio}"
DATASET="${2:?Falta el dataset de entrada}"
UMBRAL="${3:-50}"
OUT="${4:?Falta el archivo de salida}"

DATASET_ABS="$(cd "$(dirname "$DATASET")" && pwd)/$(basename "$DATASET")"
OUT_ABS="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"

cd "$REPO" || exit 1

# -----------------------------------------------------------------------------
# PASO 1 - Identificar todos los commits masivos anteriores al corte
# -----------------------------------------------------------------------------
DECISION_TIME=$(tail -n +2 "$DATASET_ABS" | head -1 | cut -d, -f5)
echo "Umbral de commit masivo: $UMBRAL archivos"
echo "decision_time          : $DECISION_TIME"
echo ""
echo "[1/2] Identificando commits masivos ..."

MASIVOS=$(mktemp)
git log --before="$DECISION_TIME" --no-merges --format="COMMIT|%h|%ad|%s" --date=short --name-only 2>/dev/null \
  | awk -v umbral="$UMBRAL" '
      /^COMMIT\|/ {
        if (hash != "" && n >= umbral) printf "%s\t%s\t%d\t%s\n", hash, fecha, n, msg;
        split($0, c, "|"); hash = c[2]; fecha = c[3]; msg = c[4];
        gsub(/\t/, " ", msg); n = 0; next
      }
      NF > 0 { n++ }
      END { if (hash != "" && n >= umbral) printf "%s\t%s\t%d\t%s\n", hash, fecha, n, msg }
    ' | sort -k3,3nr > "$MASIVOS"

echo "      commits masivos encontrados: $(wc -l < "$MASIVOS")"
echo ""
echo "      Top 10 por numero de archivos tocados:"
head -10 "$MASIVOS" | awk -F'\t' '{printf "        %s  %s  %5d archivos  %s\n", $1, $2, $3, substr($4,1,60)}'
echo ""

# Lista de hashes masivos para el filtro
HASHES_MASIVOS=$(cut -f1 "$MASIVOS" | tr '\n' '|' | sed 's/|$//')

# -----------------------------------------------------------------------------
# PASO 2 - Recalcular la recencia ignorando commits masivos
# -----------------------------------------------------------------------------
echo "[2/2] Recalculando recencia sin commits masivos ..."

DECISION_EPOCH=$(date -d "$DECISION_TIME" +%s)

head -1 "$DATASET_ABS" | sed 's/$/,days_since_last_change_corregido,last_change_date_corregida,sesgo_recencia_dias,contaminado_por_commit_masivo/' > "$OUT_ABS"

tail -n +2 "$DATASET_ABS" | while IFS=, read -r proj eid fpath estrato dt cref pc la ld ch dsl dc lcd; do
  [ -z "$fpath" ] && continue

  # Ultimo commit que NO sea masivo
  real=$(git log --before="$DECISION_TIME" --follow --format="%h|%ad" --date=short -- "$fpath" 2>/dev/null \
         | grep -vE "^(${HASHES_MASIVOS})\|" | head -1)

  if [ -n "$real" ]; then
    rd=$(echo "$real" | cut -d'|' -f2)
    r_epoch=$(date -d "$rd" +%s)
    dias_corr=$(( (DECISION_EPOCH - r_epoch) / 86400 ))
    sesgo=$(( dias_corr - dsl ))
    if [ "$rd" != "$lcd" ]; then contaminado="SI"; else contaminado="NO"; fi
  else
    rd="NA"; dias_corr="NA"; sesgo="NA"; contaminado="NA"
  fi

  echo "${proj},${eid},${fpath},${estrato},${dt},${cref},${pc},${la},${ld},${ch},${dsl},${dc},${lcd},${dias_corr},${rd},${sesgo},${contaminado}" >> "$OUT_ABS"
done

echo ""
echo "Dataset corregido: $OUT_ABS"
CONT=$(tail -n +2 "$OUT_ABS" | awk -F, '$17=="SI"' | wc -l | tr -d ' ')
TOT=$(($(wc -l < "$OUT_ABS") - 1))
echo "Archivos contaminados: $CONT de $TOT"
echo "Sesgo maximo (dias)  : $(tail -n +2 "$OUT_ABS" | awk -F, '$16!="NA"{print $16}' | sort -n | tail -1)"

rm -f "$MASIVOS"
