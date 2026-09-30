# Guion de demostración reproducible

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Gate:** G1A · punto 17 del checklist

Objetivo: ejecutar una parte completa del pipeline de extremo a extremo —
`repositorio → historial → identidad → extracción → dataset temporal →
resultado verificable` — sin depender de instrucciones verbales.

**Duración estimada:** ~15 minutos (sin contar el clon inicial).

---

## Paso 0 — Preparación

```bash
git clone https://github.com/PanConLeche45/Longitudinal-technical-debt-yatana.git
cd Longitudinal-technical-debt-yatana
mkdir -p repos
git clone https://github.com/apache/commons-collections.git repos/commons-collections
```

Verificar el entorno:

```bash
git --version     # se requiere >= 2.x
java -version     # se requiere >= 17 (para el paso 4)
```

---

## Paso 1 — Repositorio → historial

Confirmar que el commit de referencia existe y es el declarado.

```bash
git -C repos/commons-collections log -1 --format='%H | %cd | %s' --date=short \
  e96986a5c61e8fc9e7a180579ef793253161b7c3
```

**Salida esperada:**
```
e96986a5c61e8fc9e7a180579ef793253161b7c3 | 2025-11-09 | Fix issue links in the generated site's release history page
```

---

## Paso 2 — Historial → identidad de entidad

Seguir un archivo a través de sus cambios de ruta.

```bash
bash scripts/build_artifact_identity.sh \
     repos/commons-collections \
     docs/D3_SELECCION_IDENTIDAD.txt \
     /tmp/verificacion_identidad.csv
```

**Salida esperada:** `Eventos registrados: 21`

Comprobar el caso demostrativo:

```bash
grep CollectionUtils /tmp/verificacion_identidad.csv | cut -d, -f1,3,4,5,6
```

**Salida esperada:** tres filas — el nacimiento en 2001-04-24, el `MOVE_EXACTO`
(R100) del 2012-03-08 y el `RENAME_CON_CAMBIOS` (R099) del 2013-04-17.

Contrastar con Git directamente:

```bash
git -C repos/commons-collections log --follow --name-status --diff-filter=AR \
  --format='%h %ad %s' --date=short \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java
```

---

## Paso 3 — Extracción → dataset temporal

Regenerar el dataset de evolución completo.

```bash
bash scripts/build_evolution_dataset.sh \
     repos/commons-collections \
     2025-11-12 \
     e96986a5c \
     /tmp
```

**Salida esperada:**
```
archivos con historial previo al corte: 359
Filas            : 30
```

Comprobar que coincide con el dataset entregado:

```bash
diff <(sort /tmp/D3_EVOLUTION_DATASET.csv) <(sort D3_EVOLUTION_DATASET.csv) \
  && echo "IDÉNTICO"
```

### Verificación manual de un valor concreto

`CollectionUtils` debe tener 225 commits previos y 22 contribuidores distintos:

```bash
git -C repos/commons-collections log --before=2025-11-12 --oneline --follow \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java | wc -l
# esperado: 225

git -C repos/commons-collections log --before=2025-11-12 --follow --format='%an' \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java | sort -u | wc -l
# esperado: 22
```

---

## Paso 4 — Corrección del sesgo por eventos globales

```bash
bash scripts/add_corrected_recency.sh \
     repos/commons-collections \
     D3_EVOLUTION_DATASET.csv \
     50 \
     /tmp/D3_CORREGIDO.csv
```

**Salida esperada:**
```
commits masivos encontrados: 84
Archivos contaminados: 26 de 30
Sesgo maximo (dias)  : 2509
```

Comprobar el commit responsable:

```bash
git -C repos/commons-collections show --stat --format='%h %ad %s' --date=short 8ee475dcc | tail -3
# esperado: 711 files changed, 711 insertions(+), 711 deletions(-)
```

Y el caso extremo:

```bash
git -C repos/commons-collections log --before=2025-11-12 --follow \
  --format='%h %ad %s' --date=short \
  -- src/main/java/org/apache/commons/collections4/queue/SynchronizedQueue.java | head -3
# la primera línea es el commit de licencia; la segunda, el último cambio real (2018-07-07)
```

---

## Paso 5 — RefactoringMiner → resultado verificable

*(Paso más largo: ~10–20 minutos de cómputo.)*

```bash
mkdir -p tools && cd tools
curl -sSL -o rm.zip \
  https://github.com/tsantalis/RefactoringMiner/releases/download/3.0.10/RefactoringMiner-3.0.10.zip
unzip -q rm.zip && cd ..

./tools/RefactoringMiner-3.0.10/bin/RefactoringMiner -bc \
  repos/commons-collections \
  7f7fb0244abc940a2e9dd28b67508c0483a58c3e \
  e96986a5c61e8fc9e7a180579ef793253161b7c3 \
  -json /tmp/refactorings.json
```

**Salida esperada al final del log:**
```
Total count: [Commits: 115, Errors: 0, Refactorings: 1979]
```

Normalizar:

```bash
python3 scripts/parse_refactoring_events.py /tmp/refactorings.json \
        repos/commons-collections /tmp
```

**Salida esperada:** `Eventos normalizados: 1979` y, en el desglose de tipos,
`Change Method Access Modifier` con 1,836 (92.77%).

### Verificación del hallazgo central

```bash
tail -n +2 D4_REFACTORING_EVENTS_RAW.csv | awk -F, '{print $3}' \
  | sort | uniq -c | sort -rn | head -3
# esperado:
#   1424 d1a4c56c3
#    401 48afb43fa
#    109 3d737b007

for c in d1a4c56c3 48afb43fa 3d737b007; do
  git -C repos/commons-collections log -1 --format='%h %ad %s' --date=short $c
done
# los tres son "Use JUnit 5 convention for ... visibility", 2025-06-07/08
```

1,424 + 401 + 109 = **1,934** de 1,979 = **97.73%**.

---

## Paso 6 — Integridad

```bash
sha256sum -c HASHES.txt
```

Todas las líneas deben terminar en `OK`.

---

## Pasos manuales (declarados)

El checklist exige documentar cualquier paso manual. En este pipeline hay dos:

1. **Selección de los 10 archivos para el análisis de identidad.** Es una
   elección razonada (5 anteriores a 2010 / 5 posteriores) registrada en
   `docs/D3_SELECCION_IDENTIDAD.txt` con su criterio escrito. No es aleatoria y
   no se genera por script.
2. **Elección del umbral de 50 archivos** para declarar un commit masivo.
   Decisión de diseño documentada en la bitácora (D-04), no derivada de los
   datos.

Todo lo demás es determinista: mismos comandos, mismos datos, misma salida.
