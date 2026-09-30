# Autoevaluación del Gate G1A

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Piloto:** `apache/commons-collections` · **Fecha:** 2026-09-30

---

## Veredicto

> # G1A = **INCONCLUSIVE**

No se declara PASS CANDIDATE. Tres puntos del checklist no están satisfechos, y
uno de ellos (el punto 7) es estructural: sin múltiples snapshots temporales no
existe estudio longitudinal, por bien ejecutado que esté todo lo demás.

Declarar PASS con el punto 7 abierto sería exactamente el error que el propio
checklist advierte: *"Un único snapshot NO permite afirmar evolución,
acumulación, persistencia o predicción de deuda técnica."*

---

## Evaluación punto por punto

| # | Punto | Estado | Evidencia |
|---|---|---|---|
| 1 | Objetivo de investigación | **COMPLETADO** | `Objetivo_Investigacion.md` — pregunta de factibilidad + 3 sub-preguntas operativas + delimitación de lo que no se afirma |
| 2 | Baseline CIMPS | **COMPLETADO** | `D2_CIMPS8_OBSERVABILIDAD.csv` — 8 proyectos con rama, commits, ventana temporal, tags, estructura y tracker |
| 3 | Estado del arte | **EN PROCESO** | `D1_Estado_Arte_Gap.md` §1.1 — 2 artículos leídos íntegramente; 3 identificados sin leer |
| 4 | Gap científico | **COMPLETADO** | `D1_Estado_Arte_Gap.md` §2 — formato Prior work → Limitation → Gap → Proposed contribution |
| 5 | Corpus longitudinal | **COMPLETADO** | `D2_CIMPS8_OBSERVABILIDAD.csv` + criterio de selección del piloto en bitácora D-01 |
| 6 | Identidad longitudinal | **COMPLETADO** | `D3_ARTIFACT_IDENTITY.csv` — 10 archivos, 21 eventos, con hallazgo propio (§2.4) |
| 7 | Snapshots temporales | **NO INICIADO** | `SNAPSHOTS_TEMPORALES.md` — regla definida y justificada, serie T0…Tn **no construida** |
| 8 | Dataset evolutivo | **COMPLETADO** | `D3_EVOLUTION_DATASET.csv` (30×6) + versión corregida + diccionario + script generador |
| 9 | RefactoringMiner | **COMPLETADO** | v3.0.10, 115 commits, 0 errores, 1,979 refactorings + log + JSON crudo + auditoría de 30 |
| 10 | Control de leakage | **EN PROCESO** | `D4_TEMPORAL_LEAKAGE.md` — 7 riesgos; 6 mitigados, **L-05 abierto** |
| 11 | Separación temporal | **EN PROCESO** | `D_Separacion_Temporal.md` — diseño y pseudocódigo con aserciones; cortes no fijados (dependen del punto 7) |
| 12 | Reproducibilidad | **COMPLETADO** | README + 5 scripts versionados + versiones de entorno + instrucciones de ejecución |
| 13 | Provenance e integridad | **COMPLETADO** | `PROVENANCE_INTEGRIDAD.md` — cadena raw→processed→analysis→output + 13 hashes SHA-256 |
| 14 | Resultados reales | **COMPLETADO** | Todo lo reportado proviene de ejecución; §"Resultados vs. hipótesis" más abajo |
| 15 | Bitácora | **COMPLETADO** | `BITACORA_ERRORES_DECISIONES.md` — 6 decisiones, 3 errores corregidos, 3 hallazgos, 2 limitaciones |
| 16 | Repositorio actual | **COMPLETADO** | URL + tag `g1a-2026-09-30` (ver README §1) |
| 17 | Demostración reproducible | **COMPLETADO** | `D_Guion_Demostracion.md` — pipeline ejecutable de extremo a extremo |
| 18 | Autoevaluación | **COMPLETADO** | Este documento |
| 19 | Siguiente sprint | **NO APLICA** | Solo si G1A resulta aprobado en la revisión |

**Resumen:** 13 completados · 3 en proceso · 1 no iniciado · 1 no aplica.

---

## Qué es resultado real y qué sigue siendo hipótesis

### Resultados ejecutados, con evidencia verificable

1. Inventario de observabilidad de los 8 proyectos del corpus, con la fuente de
   contexto de cada uno correctamente clasificada tras corregir un error de
   detección (bitácora E-01).
2. 21 eventos de identidad sobre 10 archivos, con los 10 rastreables sin
   ambigüedad a través de dos migraciones globales del proyecto.
3. Constatación de que la similitud de renombre **no siempre es 100%**: el
   cambio de paquete de este piloto produce R095–R099, a diferencia de
   `commons-lang`. Divergencia real entre los dos pilotos del equipo.
4. Dataset de 30 archivos × 6 métricas con regla temporal `--before` aplicada y
   verificada manualmente en 3 casos (uno por estrato).
5. Identificación de **84 commits masivos** y cuantificación de su efecto:
   **26 de 30 archivos** con la recencia contaminada, sesgo máximo de
   **2,509 días**.
6. Ejecución de RefactoringMiner sobre 115 commits sin errores: **1,979
   refactorings**, de los cuales **1,934 (97.73%)** provienen de tres commits de
   convención mecánica y **45 (2.27%)** son trabajo de diseño individual.
7. Convergencia con el entregable paralelo: el mismo barrido de licencia del
   2025-05-20 afecta a 511 archivos en `commons-lang` y 711 en
   `commons-collections`.

### Hipótesis no demostradas

- Que el sesgo por eventos globales afecta a los **seis proyectos restantes**
  del corpus. Verificado en dos; es indicio, no prueba.
- Que el umbral de 50 archivos es el punto de corte adecuado. Separa bien en
  este piloto; no se ha hecho análisis de sensibilidad.
- Que la regla de snapshots por release final producirá una serie utilizable.
  Con la regla adoptada, la ventana reciente aporta **un solo** snapshot válido.
- Que los refactorings genuinos se concentran en los archivos de alto churn.
  **No se ha hecho el cruce** entre `D4_REFACTORING_EVENTS_RAW.csv` y
  `D3_EVOLUTION_DATASET.csv`.

### Lo que NO se ha hecho, y es correcto que no se haya hecho

- Ningún modelo entrenado. Ninguna afirmación predictiva.
- El corpus no se expandió más allá de los 8 proyectos de CIMPS.
- No se abrieron líneas experimentales nuevas.

---

## Por qué INCONCLUSIVE y no FAIL

El trabajo cumple las tres condiciones que separan un avance real de un avance
aparente:

1. **Toda cifra reportada proviene de una ejecución**, con script versionado,
   salida en disco y hash de integridad. No hay resultados esperados presentados
   como obtenidos.
2. **Los errores están documentados, no escondidos.** Tres errores cometidos y
   corregidos (E-01, E-02, E-03), con la consecuencia que habrían tenido de no
   detectarse.
3. **Los límites están declarados.** Lo que no se sabe está escrito como no
   sabido, y el punto que bloquea el entrenamiento está identificado por nombre
   (L-05).

## Por qué INCONCLUSIVE y no PASS CANDIDATE

1. **Punto 7 no iniciado.** Es el punto que define el objeto de estudio. Con un
   solo punto temporal, lo entregado es un pipeline longitudinal **validado en
   un instante**, no un estudio longitudinal.
2. **Punto 3 incompleto.** Dos artículos primarios leídos no bastan para
   sustentar un gap con solidez. El artículo más directamente relacionado con el
   hallazgo central (Herzig, Just & Zeller sobre *tangled changes*) no pudo
   obtenerse.
3. **Punto 10 abierto.** El riesgo L-05 no está mitigado.

---

## Lo que este trabajo sí demuestra

Aunque el gate no pase, el resultado tiene valor propio y es defendible:

> El pipeline de extracción longitudinal **funciona y es reproducible**, y al
> ejecutarlo apareció un sesgo sistemático que no estaba previsto: los eventos
> globales de proyecto contaminan simultáneamente la identidad de artefactos, la
> recencia y los conteos de refactoring. En este piloto el sesgo alcanza el
> **97.73%** de los eventos de refactoring y **2,509 días** de error en la
> recencia. El fenómeno se confirma en los dos pilotos del equipo, lo que sugiere
> que es una propiedad del corpus.
>
> Un estudio longitudinal de deuda técnica sobre este corpus que no filtre
> explícitamente los eventos globales estará modelando política de proyecto
> —formateo, migraciones, convenciones— creyendo que modela evolución de calidad.

---

## Propuesta para el siguiente sprint

Condicionada a la decisión de la revisión. Tres entregables verificables, en
orden de prioridad:

| # | Entregable | Criterio de verificación |
|---|---|---|
| **S2-1** | Serie de snapshots T0…Tn construida sobre los 59 tags de `commons-collections`, con manifest de fecha y hash exacto, y el dataset de evolución calculado en cada uno | Existe `SNAPSHOTS_MANIFEST.csv` y un `D3_EVOLUTION_DATASET_T{n}.csv` por snapshot, generados por el script ya parametrizado |
| **S2-2** | Verificación del sesgo por eventos globales en los seis proyectos restantes del corpus | Existe `D5_EVENTOS_GLOBALES_CORPUS.csv` con el conteo de commits masivos y el porcentaje de archivos contaminados por proyecto |
| **S2-3** | Matriz del estado del arte ampliada a 8 artículos primarios leídos íntegramente, con Herzig et al. (2016) incluido | `D1_Estado_Arte_Gap.md` §1.1 con 8 filas completas y DOI verificable en cada una |

Los tres son condición previa a cualquier modelado. Ninguno implica
entrenamiento.
