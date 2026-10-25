# Sprint 1 — Baseline longitudinal y evolución del estudio CIMPS

**Estudiante:** Yatana Roa Moreno — Matrícula **ZS23020600**
**Universidad Veracruzana — Facultad de Ingeniería — Ingeniería de Software**
**Línea de investigación:** Ruta B — archivos que concentran cambios (*hotspots*) y contexto de commits, issues y pull requests
**Proyecto piloto:** `apache/commons-collections`
**Gate:** G1A · **Fecha:** 2026-09-30

> **Sprint 2 (en curso, rama `sprint2-e3`):** línea E3 hotspot/co-change en
> [`sprint2_E3/`](sprint2_E3/README.md). Incluye hallazgos que afectan a G1A
> (H-04 linaje de `--follow`, E-06 llave no única).

---

## 1. Identificación de la entrega

| Elemento | Valor |
|---|---|
| Repositorio | `https://github.com/PanConLeche45/Longitudinal-technical-debt-yatana` |
| Tag de esta entrega | `g1a-2026-10-05` |
| `decision_time` | **2025-11-12** |
| Commit de referencia del piloto | `e96986a5c61e8fc9e7a180579ef793253161b7c3` (2025-11-09) |
| Release vigente en esa fecha | `rel/commons-collections-4.5.0` |
| **Autoevaluación G1A** | **INCONCLUSIVE** (ver `Autoevaluacion_G1A.md`) |

Todo lo mostrado en la presentación existe en la versión etiquetada. El tag
anterior `g1a-2026-09-30` corresponde a la entrega sin D5 y se conserva.

---

## 2. Trabajo en paralelo

Este entregable es el trabajo individual de Yatana Roa Moreno dentro del
proyecto de continuidad post-CIMPS. Se desarrolla **en paralelo** y con la
**misma metodología (Ruta B)** que el entregable de **William Tehuatle Sosa**,
sobre el mismo corpus de ocho proyectos Java, con **proyecto piloto distinto**:

| | Piloto | `decision_time` |
|---|---|---|
| W. Tehuatle Sosa | `commons-lang` | 2025-11-12 |
| **Y. Roa Moreno (este repositorio)** | **`commons-collections`** | **2025-11-12** |

El `decision_time` común hace comparables los resultados; el piloto distinto
permite distinguir hallazgos locales de hallazgos sistémicos del corpus. La §9
documenta dónde **coinciden** y dónde **divergen** los dos pilotos.

---

## 3. Pregunta de investigación

> ¿Es metodológicamente factible reconstruir la evolución temporal de los
> proyectos del corpus CIMPS de forma trazable —siguiendo la misma entidad a
> través del historial y sin utilizar información posterior al momento de
> decisión— de manera que se pueda diseñar sobre ella un estudio experimental de
> deuda técnica?

Documento completo: `Objetivo_Investigacion.md`.

**CIMPS funciona como línea base, no como evidencia longitudinal:** analizó
ocho proyectos en un único snapshot, y un snapshot no permite afirmar
evolución, acumulación, persistencia ni predicción.

---

## 4. Entorno de ejecución

**Declaración honesta.** Los artefactos de datos de esta entrega se generaron en
un contenedor Linux (entorno de trabajo asistido), no en el equipo personal de
la autora. Esto no afecta a la validez —el historial de Git de
`commons-collections` es idéntico en cualquier clon y todos los scripts son
deterministas— pero debe constar. `PROVENANCE_INTEGRIDAD.md` §5 contiene la
batería de comandos de verificación independiente.

| Elemento | Entorno de generación | Equipo de la autora |
|---|---|---|
| Sistema operativo | Linux 6.18.44 (contenedor) | Windows 10, Git Bash / MINGW64 |
| Git | 2.43.0 | 2.54.0.windows.1 |
| Java | OpenJDK 21.0.10 | OpenJDK 25.0.3 LTS |
| RefactoringMiner | 3.0.10 | pendiente de ejecución local |

---

## 5. D2 — Inventario de observabilidad del corpus

D2 no mide deuda técnica: inventaría **qué tan observable** es cada repositorio
para un estudio longitudinal. Generado por
`scripts/build_observability_inventory.sh`.

| Proyecto | Rama | Commits | Primer commit | Último | Tags | Estructura | Tracker |
|---|---|---|---|---|---|---|---|
| checkstyle | master | 19,742 | 2001-06-22 | 2026-09-30 | 225 | mono-módulo | GitHub Issues |
| **commons-collections** | **master** | **5,696** | **2001-04-14** | **2026-09-29** | **59** | **mono-módulo** | **JIRA (COLLECTIONS)** |
| commons-lang | master | 10,507 | 2002-07-19 | 2026-09-29 | 116 | mono-módulo | JIRA (LANG) |
| commons-math | master | 8,351 | 2003-05-12 | 2026-09-24 | 67 | multi-módulo profundo | JIRA (MATH) |
| httpcomponents-client | master | 5,117 | 2005-12-21 | 2026-09-28 | 216 | multi-módulo profundo | JIRA (HTTPCLIENT) |
| junit4 | main | 2,710 | 2000-12-03 | 2026-08-13 | 28 | mono-módulo | GitHub Issues |
| maven | master | 20,250 | 2003-09-01 | 2026-09-30 | 115 | multi-módulo profundo | JIRA (MNG) + GitHub Issues |
| pdfbox | trunk | 23,827 | 2008-02-10 | 2026-09-29 | 84 | multi-módulo profundo | JIRA (PDFBOX) |

*Ningún proyecto fue excluido: el objetivo de D2 es conocer la observabilidad,
no seleccionar.*

**Nota sobre las cifras.** Los conteos corresponden a la extracción del
2026-09-30. El entregable paralelo reporta cifras menores para los mismos
proyectos porque su extracción se realizó entre el 15 y el 21 de septiembre: la
diferencia es la actividad ocurrida entre ambas fechas, no una discrepancia de
método.

**Hallazgos:**

1. **El contexto de un cambio no vive en el mismo sitio en todos los proyectos.**
   Hay tres modelos: cinco proyectos concentran el contexto en JIRA con la
   pestaña Issues de GitHub desactivada, dos lo tienen en GitHub Issues, y
   `maven` usa ambos sistemas de forma simultánea. Para la Ruta B esto significa
   que la recolección de contexto no solo debe adaptarse por proyecto, sino que
   en al menos un caso deberá unificar dos fuentes y resolver los posibles
   duplicados entre ellas.
2. **La estructura del código varía mucho:** tres mono-módulo con
   `src/main/java` limpio y cinco multi-módulo profundo. Condiciona lo fácil que
   es seguir un archivo en el tiempo.
3. **Conviven tres nombres de rama principal** (`master`, `main`, `trunk`),
   señal de migraciones — `pdfbox` procede de Subversion.
4. **`junit4` está en modo mantenimiento** (desarrollo migrado a JUnit 5); su
   historial cerrado sigue siendo material útil.

> **Nota de bitácora (E-01):** la primera versión del script clasificó
> erróneamente `checkstyle` y `junit4` como usuarios de JIRA, por falsos
> positivos con `UTF-8` y `GHSA-xxxx`. Corregido con lista de exclusión y umbral
> mínimo. Ver `BITACORA_ERRORES_DECISIONES.md`.

> **Nota de bitácora (E-02):** la primera versión de D2 clasificó `maven`
> únicamente como JIRA, porque el script detecta el tracker a partir de los
> prefijos de ticket en los mensajes de commit y `maven` los usa. La
> verificación directa del repositorio mostró además la pestaña Issues de
> GitHub activa. Corregido a doble fuente. Ver
> `BITACORA_ERRORES_DECISIONES.md`.

---

## 6. Selección del proyecto piloto

Se eligió **`commons-collections`** por cuatro criterios:

- **Historial accesible y largo:** 5,696 commits desde 2001, 59 releases.
- **Estructura Java clara:** mono-módulo con `src/main/java` estándar.
- **Actividad suficiente:** activo hasta 2026-09-29, no está en mantenimiento.
- **Tamaño manejable:** mediano, frente a checkstyle, maven o pdfbox.

Criterio adicional: **ser distinto del piloto del entregable paralelo**, para
poder contrastar hallazgos. *Alternativa descartada: `junit4`.*

---

## 7. D3 — Identidad de artefactos y dataset de evolución

### 7.1 Identidad longitudinal

Se siguieron **10 archivos** con `git log --follow --name-status`, registrando
**21 eventos** en `D3_ARTIFACT_IDENTITY.csv`. Selección contrastada: 5 nacidos
antes de 2010, 5 después.

**Caso demostrativo — `CollectionUtils.java`:**

```
src/java/org/apache/commons/collections/CollectionUtils.java
        │  nace 2001-04-24 (256420016) "adding CollectionUtils and tests for it"
        │
        │  8ffb78ec5 (2012-03-08) "MOve to standard Maven layout"     → R100
        ▼
src/main/java/org/apache/commons/collections/CollectionUtils.java
        │
        │  a8d1066b5 (2013-04-17) "[COLLECTIONS-452] Change package
        │                          to o.a.c.collections4."            → R099
        ▼
src/main/java/org/apache/commons/collections4/CollectionUtils.java
```

La identidad se sostiene en **dos evidencias independientes**: el código de
similitud calculado por Git y el mensaje de commit, que cita el ticket
**COLLECTIONS-452**. Cadena `archivo → commit → movimiento → ticket JIRA`.

**Hallazgo — la similitud no siempre es 100%.** El cambio de layout dio R100
(movió sin tocar contenido); el cambio de paquete dio **R095–R099**, porque
modificó la declaración `package` y los `import` en el mismo commit. Un criterio
de identidad que exigiera R100 perdería los 5 archivos antiguos de este piloto.

**Hallazgo — la fecha de nacimiento predice la complejidad de identidad:**

| Grupo | Renombres |
|---|---|
| Nacidos antes de 2012-03-08 (5 archivos) | 2 cada uno |
| Nacido entre ambas migraciones — `PassiveExpiringMap` | 1 |
| Nacidos después de 2013-04-17 (4 archivos) | 0 |

Los renombres **no son actividad de los archivos**: son eventos globales que
arrastraron a todos los archivos vivos a la vez.

### 7.2 Dataset de evolución

`D3_EVOLUTION_DATASET.csv` — 30 archivos × 6 métricas, muestreo estratificado
(10 hotspots / 10 medios / 10 tranquilos) sobre un universo de 359 archivos
`.java` vivos en el commit de referencia.

**Regla temporal obligatoria:** `feature_timestamp <= decision_time`. Todas las
invocaciones a `git log` llevan `--before="2025-11-12"`. Generado por
`scripts/build_evolution_dataset.sh`.

Diccionario de datos: `docs/DICCIONARIO_DATOS.md`.

### 7.3 Verificación manual

| Archivo | Estrato | `prior_commits` | `distinct_contributors` | ¿Coincide? |
|---|---|---|---|---|
| `CollectionUtils` | ALTO | 225 | 22 | Sí |
| `ChainedTransformer` | MEDIO | 51 | 12 | Sí |
| `IteratorOperations` | BAJO | 2 | 2 | Sí |

### 7.4 El hallazgo central — contaminación por eventos globales

25 de 30 archivos tenían **la misma fecha de último cambio**: 2025-05-20. La
causa es el commit `8ee475dcc` (*"Update Apache License URL to HTTPS"*), que
modificó **711 archivos** cambiando **una línea** en cada uno.

Al recalcular ignorando los **84 commits masivos** (≥ 50 archivos) del
proyecto: **26 de 30 archivos contaminados**.

| Archivo | Recencia reportada | Último cambio real | Sesgo |
|---|---|---|---|
| `SynchronizedQueue` | 176 días | 2018-07-07 | **2,509 días** |
| `trie/package-info` | 176 días | 2024-01-27 | 479 días |
| `PredicatedCollection` | 176 días | 2024-07-10 | 314 días |

`SynchronizedQueue` llevaba **casi siete años** sin cambios sustantivos y la
métrica ingenua lo presenta como modificado hace menos de seis meses.

Mitigación: `scripts/add_corrected_recency.sh` →
`D3_EVOLUTION_DATASET_CORREGIDO.csv`.

---

## 8. D4 — RefactoringMiner

| Elemento | Valor |
|---|---|
| Versión | RefactoringMiner **3.0.10** |
| Rango | `rel/commons-collections-4.5.0` → `decision_time` (119 commits) |
| Procesados | **115 commits, 0 errores** |
| Refactorings detectados | **1,979** |

### El 97.73% de los refactorings son un barrido mecánico

| Commit | Fecha | Mensaje | Refactorings |
|---|---|---|---|
| `d1a4c56c3` | 2025-06-07 | *Use JUnit 5 convention for @Test method visibility* | 1,424 |
| `48afb43fa` | 2025-06-07 | *Use JUnit 5 convention for test method visibility* | 401 |
| `3d737b007` | 2025-06-08 | *Use JUnit 5 convention for class visibility* | 109 |

**1,934 de 1,979 = 97.73%** provienen de estos tres commits. Solo **45 eventos
(2.27%)** corresponden a trabajo de diseño individual.

> RefactoringMiner no se equivoca: cambiar un modificador de acceso **es**
> formalmente un refactoring. El problema es de interpretación. Un estudio que
> use el conteo bruto como proxy de "pago de deuda" concluiría que este periodo
> fue de intensa refactorización; lo que ocurrió fue que un desarrollador
> actualizó la convención de visibilidad de las pruebas en dos días.

Análisis completo: `D4_Analisis_Refactorings.md`.

---

## 9. Convergencia y divergencia con el entregable paralelo

| Aspecto | `commons-lang` (W. Tehuatle) | `commons-collections` (este trabajo) | |
|---|---|---|---|
| Barrido de licencia 2025-05-20 | 511 archivos | **711 archivos** | **CONVERGE** |
| Migraciones globales que arrastran archivos | 2 (paquete + layout) | 2 (layout + paquete) | **CONVERGE** |
| Nacidos después de las migraciones sin renombres | sí | sí | **CONVERGE** |
| Similitud del cambio de paquete | R100 | **R095–R099** | **DIVERGE** |

**Interpretación de la convergencia:** el barrido de licencia del 2025-05-20 es
el mismo evento de la Apache Software Foundation aplicado a componentes
distintos. El sesgo por eventos globales **no es una rareza de un proyecto: es
sistémico del corpus.**

**Interpretación de la divergencia:** `commons-lang` separó el renombre de
directorio del cambio de declaración en commits distintos; `commons-collections`
lo hizo en uno solo. La conclusión *"la identidad se establece con R100"* **no
es generalizable**: depende de cómo cada proyecto ejecutó su migración.

---

## 10. Estado de los entregables

| # | Punto del checklist | Estado |
|---|---|---|
| 1 | Objetivo de investigación | COMPLETADO |
| 2 | Baseline CIMPS | COMPLETADO |
| 3 | Estado del arte | **EN PROCESO** (2 de 8 artículos leídos) |
| 4 | Gap científico | COMPLETADO |
| 5 | Corpus longitudinal | COMPLETADO |
| 6 | Identidad longitudinal | COMPLETADO |
| 7 | Snapshots temporales | **NO INICIADO** |
| 8 | Dataset evolutivo | COMPLETADO |
| 9 | RefactoringMiner | COMPLETADO |
| 10 | Control de leakage | **EN PROCESO** (6 de 7 riesgos mitigados) |
| 11 | Separación temporal | **EN PROCESO** (diseñada, no ejecutada) |
| 12 | Reproducibilidad | COMPLETADO |
| 13 | Provenance e integridad | COMPLETADO |
| 14 | Resultados reales | COMPLETADO |
| 15 | Bitácora | COMPLETADO |
| 16 | Repositorio actual | COMPLETADO |
| 17 | Demostración reproducible | COMPLETADO |
| 18 | Autoevaluación G1A | COMPLETADO → **INCONCLUSIVE** |
| 19 | Siguiente sprint | **PROPUESTA PRELIMINAR** en D5 §7; formalización condicionada al PASS de G1A |

**Entregable del sprint (numeración independiente del checklist):**

| Entregable | Estado |
|---|---|
| D5 — Plan de evolución CIMPS → estudio longitudinal | COMPLETADO (`D5_PLAN_EVOLUCION_CIMPS.md`) |

---

## 11. Estructura del repositorio

```
Longitudinal-technical-debt-yatana/
├── README.md                             (este archivo)
├── Objetivo_Investigacion.md             punto 1
├── D1_Estado_Arte_Gap.md                 puntos 3 y 4
├── D2_CIMPS8_OBSERVABILIDAD.csv          puntos 2 y 5
├── D3_ARTIFACT_IDENTITY.csv              punto 6 — 21 eventos
├── D3_EVOLUTION_DATASET.csv              punto 8 — 30 x 6
├── D3_EVOLUTION_DATASET_CORREGIDO.csv    punto 8 — con recencia corregida
├── D3_SELECCION_30.txt                   muestra estratificada
├── D3_Analisis_Evolucion.md              análisis de D3
├── D4_REFACTORING_EVENTS_RAW.json        punto 9 — salida cruda (1.9 MB)
├── D4_REFACTORING_EVENTS_RAW.csv         punto 9 — normalizada, 1,979 eventos
├── D4_REFACTORING_TIPOS.csv              desglose masivo / individual
├── D4_REFACTORING_AUDIT_30.csv           auditoría de 30 eventos
├── D4_Analisis_Refactorings.md           análisis de D4
├── D4_TEMPORAL_LEAKAGE.md                punto 10 — ledger de 7 riesgos
├── D5_PLAN_EVOLUCION_CIMPS.md            plan de evolución — deriva de D1–D4
├── D_Separacion_Temporal.md              punto 11
├── SNAPSHOTS_TEMPORALES.md               punto 7 — regla definida
├── PROVENANCE_INTEGRIDAD.md              punto 13 — cadena + hashes
├── BITACORA_ERRORES_DECISIONES.md        punto 15
├── D_Guion_Demostracion.md               punto 17
├── Autoevaluacion_G1A.md                 punto 18
├── HASHES.txt                            integridad SHA-256
├── docs/
│   ├── DICCIONARIO_DATOS.md
│   ├── D3_SELECCION_IDENTIDAD.txt
│   └── D4_refactoringminer_run.log
├── scripts/
│   ├── build_observability_inventory.sh
│   ├── build_artifact_identity.sh
│   ├── build_evolution_dataset.sh
│   ├── add_corrected_recency.sh
│   └── parse_refactoring_events.py
└── repos/                                (excluido por .gitignore — área de trabajo)
```

---

## 12. Reproducción

Guion completo paso a paso: **`D_Guion_Demostracion.md`**.

Versión mínima:

```bash
git clone https://github.com/apache/commons-collections.git repos/commons-collections

bash scripts/build_evolution_dataset.sh repos/commons-collections 2025-11-12 e96986a5c .
# esperado: 359 archivos en el universo, 30 filas

bash scripts/add_corrected_recency.sh repos/commons-collections \
     D3_EVOLUTION_DATASET.csv 50 D3_EVOLUTION_DATASET_CORREGIDO.csv
# esperado: 84 commits masivos, 26 de 30 contaminados, sesgo máximo 2509
```

Verificación de un valor concreto (debe dar 225 y 22):

```bash
git -C repos/commons-collections log --before=2025-11-12 --oneline --follow \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java | wc -l

git -C repos/commons-collections log --before=2025-11-12 --follow --format='%an' \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java | sort -u | wc -l
```

---

## 13. Distinciones que el proceso mantiene

Para no sobre-interpretar la evidencia:

- análisis estático **≠** deuda técnica total
- alta frecuencia de cambio **≠** deuda técnica
- refactoring detectado **≠** pago de deuda
- asociación **≠** causalidad
- script escrito **≠** resultado obtenido

---

## 14. Qué falta

1. **Construir la serie T0…Tn** (punto 7). Es la carencia estructural.
2. **Completar D1** a 8 artículos primarios, incluyendo Herzig, Just & Zeller
   (2016) sobre *tangled changes*.
3. **Cerrar L-05** (etiquetas con información futura) para desbloquear el
   entrenamiento.
4. **Verificar el sesgo por eventos globales** en los seis proyectos restantes.
5. **Cruzar** `D4_REFACTORING_EVENTS_RAW.csv` con `D3_EVOLUTION_DATASET.csv` por
   `(entity_id, commit)`.
6. **Análisis de sensibilidad** al umbral de 50 archivos.

El orden de ejecución propuesto para estos puntos está en
`D5_PLAN_EVOLUCION_CIMPS.md` §6.7.
