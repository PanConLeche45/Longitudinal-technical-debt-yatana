#!/usr/bin/env bash
# =============================================================================
# build_evolution_dataset.sh
#
# D3 (parte 2) - Dataset de evolucion con control de fuga temporal
#
# Proposito: producir una tabla donde cada fila es un archivo observado en un
# momento de decision (decision_time), con metricas calculadas EXCLUSIVAMENTE
# a partir de informacion anterior a ese momento.
#
# REGLA TEMPORAL OBLIGATORIA:
#   feature_timestamp <= decision_time
# Todas las invocaciones a `git log` llevan --before="$DECISION_TIME".
# Ningun dato proviene de commits posteriores. Esta regla es lo que separa
# un dataset longitudinal valido de uno contaminado por informacion futura.
#
# Muestreo estratificado: se ordenan los archivos Java por numero de commits
# previos y se toman 10 del estrato alto (hotspots), 10 del medio y 10 del
# bajo (tranquilos). El objetivo es que el dataset cubra los tres regimenes
# de actividad y no solo los archivos mas ruidosos.
#
# Metricas calculadas (6):
#   prior_commits            commits que tocaron el archivo antes del corte
#   lines_added              lineas agregadas acumuladas
#   lines_deleted            lineas eliminadas acumuladas
#   churn                    lines_added + lines_deleted
#   days_since_last_change   dias entre el ultimo cambio y decision_time
#   distinct_contributors    autores distintos que tocaron el archivo
#
# Uso:
#   bash scripts/build_evolution_dataset.sh <repo> <decision_time> <commit_ref> <salida_dir>
#
# Ejemplo:
#   bash scripts/build_evolution_dataset.sh repos/commons-collections 2025-11-12 e96986a5c .
#
# Autor: Yatana Roa Moreno (ZS23020600)
# Proyecto: Continuidad post-CIMPS - Ruta B - Gate G1A
# =============================================================================

set -u

REPO="${1:?Falta la ruta del repositorio}"
DECISION_TIME="${2:?Falta decision_time en formato YYYY-MM-DD}"
COMMIT_REF="${3:?Falta el commit de referencia}"
OUTDIR="${4:-.}"

OUTDIR_ABS="$(cd "$OUTDIR" && pwd)"
DATASET="$OUTDIR_ABS/D3_EVOLUTION_DATASET.csv"
SELECCION="$OUTDIR_ABS/D3_SELECCION_30.txt"

cd "$REPO" || exit 1
PROJECT_ID=$(basename "$(pwd)")

echo "Repositorio     : $PROJECT_ID"
echo "decision_time   : $DECISION_TIME"
echo "commit_ref      : $COMMIT_REF"
echo ""

# -----------------------------------------------------------------------------
# PASO 1 - Universo de archivos: solo codigo fuente principal, .java, y que
# existan en el commit de referencia (no archivos ya borrados).
# -----------------------------------------------------------------------------
echo "[1/3] Construyendo universo de archivos Java vivos en $COMMIT_REF ..."

TMP_RANK=$(mktemp)
git ls-tree -r --name-only "$COMMIT_REF" -- 'src/main/java' 2>/dev/null \
  | grep '\.java$' \
  | while IFS= read -r f; do
      n=$(git log --before="$DECISION_TIME" --oneline --follow -- "$f" 2>/dev/null | wc -l | tr -d ' ')
      [ "$n" -gt 0 ] && echo "$n|$f"
    done | sort -t'|' -k1,1nr > "$TMP_RANK"

TOTAL=$(wc -l < "$TMP_RANK" | tr -d ' ')
echo "      archivos con historial previo al corte: $TOTAL"

# -----------------------------------------------------------------------------
# PASO 2 - Muestreo estratificado 10 / 10 / 10
# -----------------------------------------------------------------------------
echo "[2/3] Muestreo estratificado (10 hotspots / 10 medios / 10 tranquilos) ..."

TERCIO=$((TOTAL / 3))

{
  echo "# Seleccion estratificada de 30 archivos - $PROJECT_ID"
  echo "# decision_time: $DECISION_TIME | commit_ref: $COMMIT_REF"
  echo "# Universo: $TOTAL archivos Java vivos con historial previo al corte"
  echo "#"
  echo "# ESTRATO ALTO (hotspots) - los 10 archivos con mas commits previos"
  head -10 "$TMP_RANK" | cut -d'|' -f2 | sed 's/^/ALTO  /'
  echo "#"
  echo "# ESTRATO MEDIO - 10 archivos alrededor de la mediana"
  sed -n "$((TERCIO + 1)),$((TERCIO + 10))p" "$TMP_RANK" | cut -d'|' -f2 | sed 's/^/MEDIO /'
  echo "#"
  echo "# ESTRATO BAJO (tranquilos) - 10 archivos con menos commits previos"
  tail -10 "$TMP_RANK" | cut -d'|' -f2 | sed 's/^/BAJO  /'
} > "$SELECCION"

# -----------------------------------------------------------------------------
# PASO 3 - Calculo de metricas, siempre con --before="$DECISION_TIME"
# -----------------------------------------------------------------------------
echo "[3/3] Calculando metricas con corte temporal ..."

echo "project_id,entity_id,file_path,estrato,decision_time,commit_ref,prior_commits,lines_added,lines_deleted,churn,days_since_last_change,distinct_contributors,last_change_date" > "$DATASET"

DECISION_EPOCH=$(date -d "$DECISION_TIME" +%s 2>/dev/null || date -jf "%Y-%m-%d" "$DECISION_TIME" +%s)

procesar_estrato() {
  local etiqueta="$1"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    entity_id=$(basename "$f" .java)

    # --- prior_commits: cuantas veces se toco el archivo antes del corte ---
    prior_commits=$(git log --before="$DECISION_TIME" --oneline --follow -- "$f" 2>/dev/null | wc -l | tr -d ' ')

    # --- churn: lineas agregadas y eliminadas acumuladas antes del corte ---
    # --no-merges evita contar dos veces las lineas ya contabilizadas en los
    # commits originales de una fusion (amenaza a la validez documentada).
    read -r added deleted <<< "$(git log --before="$DECISION_TIME" --follow --no-merges \
        --numstat --format="" -- "$f" 2>/dev/null \
      | awk '{ if ($1 != "-") a += $1; if ($2 != "-") d += $2 } END { print (a+0), (d+0) }')"
    churn=$((added + deleted))

    # --- days_since_last_change: recencia respecto al momento de decision ---
    last_date=$(git log --before="$DECISION_TIME" -1 --follow --format=%ad --date=short -- "$f" 2>/dev/null)
    if [ -n "$last_date" ]; then
      last_epoch=$(date -d "$last_date" +%s 2>/dev/null || date -jf "%Y-%m-%d" "$last_date" +%s)
      days_since=$(( (DECISION_EPOCH - last_epoch) / 86400 ))
    else
      last_date="NA"; days_since="NA"
    fi

    # --- distinct_contributors: autores distintos antes del corte ---
    contributors=$(git log --before="$DECISION_TIME" --follow --format="%an" -- "$f" 2>/dev/null \
      | sort -u | wc -l | tr -d ' ')

    echo "${PROJECT_ID},${entity_id},${f},${etiqueta},${DECISION_TIME},${COMMIT_REF},${prior_commits},${added},${deleted},${churn},${days_since},${contributors},${last_date}" >> "$DATASET"
  done
}

head -10 "$TMP_RANK" | cut -d'|' -f2 | procesar_estrato "ALTO"
sed -n "$((TERCIO + 1)),$((TERCIO + 10))p" "$TMP_RANK" | cut -d'|' -f2 | procesar_estrato "MEDIO"
tail -10 "$TMP_RANK" | cut -d'|' -f2 | procesar_estrato "BAJO"

rm -f "$TMP_RANK"

echo ""
echo "Dataset generado : $DATASET"
echo "Seleccion        : $SELECCION"
echo "Filas            : $(($(wc -l < "$DATASET") - 1))"
