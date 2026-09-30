#!/usr/bin/env bash
# =============================================================================
# build_observability_inventory.sh
#
# D2 - Inventario de observabilidad del corpus CIMPS
#
# Proposito: para cada repositorio del corpus, registrar los elementos minimos
# que determinan si el proyecto es OBSERVABLE para un estudio longitudinal.
# No mide deuda tecnica: mide si el historial permite reconstruir la evolucion.
#
# Uso:
#   bash scripts/build_observability_inventory.sh <dir_repos> <archivo_salida.csv>
#
# Ejemplo:
#   bash scripts/build_observability_inventory.sh repos D2_CIMPS8_OBSERVABILIDAD.csv
#
# Autor: Yatana Roa Moreno (ZS23020600)
# Proyecto: Continuidad post-CIMPS - Ruta B - Gate G1A
# =============================================================================

set -u

REPOS_DIR="${1:-repos}"
OUT="${2:-D2_CIMPS8_OBSERVABILIDAD.csv}"

if [ ! -d "$REPOS_DIR" ]; then
  echo "ERROR: no existe el directorio de repositorios: $REPOS_DIR" >&2
  exit 1
fi

# Cabecera del CSV
echo "proyecto,rama_principal,total_commits,primer_commit,ultimo_commit,num_tags,estructura_java,ruta_java_principal,prefijo_jira,commits_con_jira,observaciones" > "$OUT"

for repo_path in "$REPOS_DIR"/*/; do
  repo=$(basename "$repo_path")

  if [ ! -d "$repo_path/.git" ]; then
    echo "  [skip] $repo no es un repositorio Git" >&2
    continue
  fi

  echo "  [D2] procesando $repo ..." >&2
  cd "$repo_path" || continue

  # --- Rama principal ---------------------------------------------------
  # Se toma la rama HEAD del remoto, que es la rama de desarrollo real.
  rama=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")

  # --- Volumen de historial --------------------------------------------
  total_commits=$(git rev-list --all --count)

  # --- Ventana temporal observable -------------------------------------
  primer_commit=$(git log --reverse --format=%cd --date=short 2>/dev/null | head -1)
  ultimo_commit=$(git log -1 --format=%cd --date=short)

  # --- Releases / tags --------------------------------------------------
  num_tags=$(git tag | wc -l | tr -d ' ')

  # --- Estructura del codigo Java ---------------------------------------
  # Determina si el proyecto es mono-modulo (un solo src/main/java en raiz)
  # o multi-modulo (varios src/main/java en subdirectorios).
  num_src=$(find . -type d -path "*/src/main/java" -not -path "./.git/*" 2>/dev/null | wc -l | tr -d ' ')
  ruta_java=$(find . -type d -path "*/src/main/java" -not -path "./.git/*" 2>/dev/null | head -1 | sed 's|^\./||')

  if [ -d "src/main/java" ] && [ "$num_src" -le 2 ]; then
    estructura="mono-modulo"
  elif [ "$num_src" -eq 0 ]; then
    estructura="sin-src-main-java"
    ruta_java="N/A"
  elif [ "$num_src" -le 3 ]; then
    estructura="multi-modulo"
  else
    estructura="multi-modulo-profundo"
  fi

  # --- Deteccion de tracker externo (JIRA) ------------------------------
  # Se busca el prefijo de ticket mas frecuente en los mensajes de commit.
  # Un prefijo dominante indica que el contexto del cambio vive en JIRA y
  # no en GitHub Issues: dato critico para la Ruta B.
  #
  # NOTA (error corregido, ver bitacora E-01): la primera version de este
  # bloque produjo falsos positivos. Cadenas como "UTF-8" o identificadores
  # de avisos de seguridad "GHSA-xxxx" coinciden con el patron PREFIJO-NUMERO
  # sin ser tickets de JIRA. Se aplican dos filtros:
  #   (a) lista de exclusion de prefijos conocidos que no son trackers;
  #   (b) umbral minimo de 50 commits para considerar que un prefijo
  #       representa realmente al tracker del proyecto.
  # Un proyecto que no supera el umbral se clasifica como GITHUB_ISSUES.
  EXCLUIDOS='^(UTF|GHSA|ISO|RFC|SHA|MD|AES|RSA|HTTP|HTTPS|API|JDK|JRE|PR|CVE)$'

  prefijo=$(git log --format=%s 2>/dev/null \
    | grep -oE '\b[A-Z][A-Z0-9]{2,15}-[0-9]+' \
    | sed 's/-[0-9]*$//' \
    | grep -vE "$EXCLUIDOS" \
    | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

  if [ -z "$prefijo" ]; then
    prefijo="GITHUB_ISSUES"
    commits_jira=0
  else
    commits_jira=$(git log --format=%s 2>/dev/null | grep -cE "\b${prefijo}-[0-9]+" || echo 0)
    # Umbral: por debajo de 50 commits el prefijo no es el tracker del proyecto
    if [ "$commits_jira" -lt 50 ]; then
      prefijo="GITHUB_ISSUES"
      commits_jira=0
    fi
  fi

  # --- Observacion cualitativa ------------------------------------------
  obs=""
  if [ "$rama" = "trunk" ]; then
    obs="rama trunk sugiere migracion desde Subversion"
  elif [ "$rama" = "main" ]; then
    obs="rama main (renombrada desde master)"
  fi
  if [ "$estructura" = "multi-modulo-profundo" ]; then
    obs="${obs}${obs:+; }estructura profunda complica seguimiento de identidad"
  fi
  [ -z "$obs" ] && obs="sin observaciones"

  cd - > /dev/null || exit 1

  echo "${repo},${rama},${total_commits},${primer_commit},${ultimo_commit},${num_tags},${estructura},${ruta_java},${prefijo},${commits_jira},\"${obs}\"" >> "$OUT"
done

echo ""
echo "Inventario generado: $OUT"
echo "Filas: $(($(wc -l < "$OUT") - 1))"
