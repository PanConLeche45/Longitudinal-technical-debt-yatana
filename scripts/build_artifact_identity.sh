#!/usr/bin/env bash
# =============================================================================
# build_artifact_identity.sh
#
# D3 (parte 1) - Identidad longitudinal de artefactos
#
# Proposito: demostrar, con evidencia verificable, que un archivo puede
# seguirse a traves del historial aunque cambie de ruta (rename / move).
# Sin esta garantia no es posible afirmar que dos observaciones en momentos
# distintos corresponden a la MISMA entidad, y por tanto no hay estudio
# longitudinal posible.
#
# Metodo: `git log --follow --name-status` sigue la cadena de renombres que
# Git detecta por similitud de contenido. Un evento R100 significa rename con
# 100% de similitud (el archivo es identico, solo cambio de ruta); valores
# menores (R095, R087...) indican que hubo cambios simultaneos al movimiento.
#
# Uso:
#   bash scripts/build_artifact_identity.sh <ruta_repo> <lista_archivos> <salida.csv>
#
# Autor: Yatana Roa Moreno (ZS23020600)
# Proyecto: Continuidad post-CIMPS - Ruta B - Gate G1A
# =============================================================================

set -u

REPO="${1:?Falta la ruta del repositorio}"
LISTA="${2:?Falta el archivo con la lista de rutas a seguir}"
OUT="${3:-D3_ARTIFACT_IDENTITY.csv}"

# Se resuelven rutas absolutas: el script hace `cd` al repositorio y las
# rutas relativas dejarian de ser validas a partir de ese punto.
OUT_ABS="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
LISTA_ABS="$(cd "$(dirname "$LISTA")" && pwd)/$(basename "$LISTA")"

echo "entity_id,ruta_actual,tipo_evento,similitud,commit,fecha,ruta_origen,ruta_destino,mensaje_commit" > "$OUT_ABS"

cd "$REPO" || exit 1

while IFS= read -r archivo; do
  # Saltar lineas vacias y comentarios
  [ -z "$archivo" ] && continue
  case "$archivo" in \#*) continue ;; esac

  entity_id=$(basename "$archivo" .java)
  echo "  [D3-identidad] siguiendo $entity_id ..." >&2

  # --follow sigue los renombres; --name-status imprime el codigo de evento
  # (A=Added, M=Modified, R###=Renamed con % de similitud)
  git log --follow --name-status --diff-filter=AR \
      --format="COMMIT|%h|%ad|%s" --date=short -- "$archivo" 2>/dev/null \
  | awk -v eid="$entity_id" -v actual="$archivo" '
      /^COMMIT\|/ {
        split($0, c, "|");
        hash = c[2]; fecha = c[3];
        # El mensaje puede contener "|", se reconstruye desde el campo 4
        msg = c[4];
        for (i = 5; i <= length(c); i++) if (c[i] != "") msg = msg " " c[i];
        gsub(/,/, ";", msg);
        gsub(/"/, "", msg);
        if (length(msg) > 90) msg = substr(msg, 1, 90) "...";
        next
      }
      /^A\t/ {
        split($0, f, "\t");
        printf "%s,%s,NACIMIENTO,,%s,%s,,%s,\"%s\"\n", eid, actual, hash, fecha, f[2], msg;
        next
      }
      /^R[0-9]+\t/ {
        split($0, f, "\t");
        sim = substr(f[1], 2);
        tipo = (sim == "100") ? "MOVE_EXACTO" : "RENAME_CON_CAMBIOS";
        printf "%s,%s,%s,%s,%s,%s,%s,%s,\"%s\"\n", eid, actual, tipo, sim, hash, fecha, f[2], f[3], msg;
        next
      }
    ' >> "$OUT_ABS"

done < "$LISTA_ABS"

echo ""
echo "Tabla de identidad generada: $OUT_ABS"
echo "Eventos registrados: $(($(wc -l < "$OUT_ABS") - 1))"
