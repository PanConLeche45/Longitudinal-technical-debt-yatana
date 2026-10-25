#!/usr/bin/env bash
# run_e1_sonar.sh — E1 por archivo con SonarQube local, de principio a fin, en un solo comando.
#
# Ejecutar desde la raíz del repositorio (carpeta "proyecto"), con SonarQube ya encendido:
#   bash sprint2_E3/scripts/run_e1_sonar.sh
#
# Qué hace:
#   1. Pide el token de SonarQube SIN mostrarlo en pantalla (no se guarda en ningún archivo).
#   2. Extrae una copia limpia del snapshot CIMPS (7f7fb0244) en ../snapshots/cc-4.5.0 (no toca el repo original).
#   3. Compila y analiza con SonarQube (mvn sonar:sonar).
#   4. Espera a que SonarQube termine de procesar el análisis.
#   5. Exporta las métricas por archivo → sprint2_E3/data/E1_FILE_METRICS_commons-collections_2025-04-19.csv
#   6. Re-ejecuta run_e3.sh, que integra E1 real en la tabla E1+E2+E3.
set -euo pipefail

SONAR_URL=${SONAR_URL:-http://localhost:9000}
KEY=commons-collections_4.5.0_7f7fb0244
SHA=7f7fb0244abc940a2e9dd28b67508c0483a58c3e
ROOT=$(pwd)
SNAP="$ROOT/../snapshots/cc-4.5.0"
PY=$(command -v python3 || command -v python || true)

[ -d sprint2_E3 ] || { echo "Corre este script desde la carpeta 'proyecto' (la raíz del repositorio)."; exit 1; }
[ -n "$PY" ] || { echo "No encontré Python. Instálalo (python.org) y vuelve a correr el script."; exit 1; }
curl -s -o /dev/null "$SONAR_URL/api/system/status" || { echo "SonarQube no responde en $SONAR_URL. Arranca StartSonar.bat y espera 'SonarQube is operational'."; exit 1; }

if [ -z "${SONAR_TOKEN:-}" ]; then
  read -r -s -p "Pega tu token de SonarQube (empieza con sqa_; no se verá en pantalla) y presiona Enter: " SONAR_TOKEN
  echo
fi
export SONAR_TOKEN
[ "$(curl -s -u "$SONAR_TOKEN:" "$SONAR_URL/api/authentication/validate")" = '{"valid":true}' ] \
  || { echo "El token no es válido. Genera uno nuevo en My Account → Security."; exit 1; }
echo "[1/5] Token válido."

echo "[2/5] Copia limpia del snapshot CIMPS (7f7fb0244)..."
if [ ! -f "$SNAP/pom.xml" ]; then
  mkdir -p "$SNAP"
  git -C repos/commons-collections archive "$SHA" | tar -x -C "$SNAP"
fi

echo "[3/5] Compilando y analizando con SonarQube (unos minutos)..."
( cd "$SNAP" && mvn -B -q -DskipTests -Drat.skip=true -Djapicmp.skip=true -Danimal.sniffer.skip=true \
    compile org.sonarsource.scanner.maven:sonar-maven-plugin:5.8.0.7211:sonar \
    -Dsonar.host.url="$SONAR_URL" -Dsonar.token="$SONAR_TOKEN" \
    -Dsonar.projectKey="$KEY" -Dsonar.projectName="commons-collections 4.5.0 (snapshot CIMPS)" \
    -Dsonar.projectVersion=4.5.0 -Dsonar.scm.disabled=true ) | tee ../e1_sonar_mvn.log | tail -5

echo "[4/5] Esperando a que SonarQube procese el análisis..."
for i in $(seq 1 60); do
  st=$(curl -s -u "$SONAR_TOKEN:" "$SONAR_URL/api/ce/component?component=$KEY")
  case "$st" in
    *'"queue":[]'*'"status":"SUCCESS"'*) echo "      listo."; break ;;
    *'"status":"FAILED"'*) echo "      SonarQube marcó el análisis como FALLIDO (revisa logs/ce.log; puede ser disco lleno)."; exit 1 ;;
  esac
  sleep 5
done

echo "[5/5] Exportando métricas por archivo e integrando E1+E2+E3..."
"$PY" sprint2_E3/scripts/export_sonar_file_metrics.py --sonar-url "$SONAR_URL" --project-key "$KEY" \
  --project commons-collections --decision-time 2025-04-19 --decision-sha "$SHA" \
  --artifacts sprint2_E3/data/ARTIFACTS_commons-collections.csv --out sprint2_E3/data
bash sprint2_E3/scripts/run_e3.sh > ../e1_run_e3.log 2>&1 && tail -3 ../e1_run_e3.log

unset SONAR_TOKEN
echo
echo "LISTO. Revisa: sprint2_E3/data/E1_FILE_METRICS_commons-collections_2025-04-19.csv"
echo "Para subirlo:  git add -A && git commit -m \"E1 real con SonarQube en 4.5.0\" && git push"
