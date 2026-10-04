# D5 — Plan de evolución: de CIMPS a un estudio longitudinal

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Línea:** Ruta B — archivos que concentran cambios (*hotspots*) y contexto de commits, issues y pull requests
**Proyecto piloto:** `apache/commons-collections`
**Gate:** G1A · **Fecha:** 2026-10-05

Cada decisión de este plan se apoya en evidencia producida en D1–D4 y se cita
con el archivo que la contiene. No se incluyen propuestas sin respaldo en el
trabajo ya ejecutado.

---

## 1. Mantener — qué del estudio CIMPS sigue siendo útil

| Elemento | Por qué se conserva | Evidencia |
|---|---|---|
| El corpus de ocho proyectos Java | Los ocho resultaron observables: historial completo accesible, rama principal identificable y estructura Java localizable en los ocho casos. Ninguno tuvo que descartarse por falta de historial. | `D2_CIMPS8_OBSERVABILIDAD.csv` |
| El análisis estático como una de las fuentes | Sigue siendo la única fuente que describe el estado interno del código. El historial Git describe actividad, no calidad: son planos distintos y complementarios. | `D1_Estado_Arte_Gap.md` |
| La normalización de métricas | El problema que motivó normalizar en CIMPS (comparar proyectos de tamaños muy distintos) persiste y se agrava al añadir métricas de actividad. | `D1_Estado_Arte_Gap.md` |
| El papel de CIMPS como línea base | CIMPS aporta el punto de referencia contra el cual medir si la información longitudinal aporta algo. Sin baseline no hay ablation posible. | `Objetivo_Investigacion.md` |

**CIMPS funciona como línea base, no como evidencia longitudinal.** Analizó
cada proyecto en un único snapshot, y un snapshot no permite afirmar evolución,
acumulación, persistencia ni predicción.

---

## 2. Agregar — qué información longitudinal necesitamos

### 2.1 Serie de snapshots T0…Tn

Es la carencia estructural de la entrega actual (punto 7 del checklist,
NO INICIADO). Todo lo construido hasta ahora observa **un solo**
`decision_time` (2025-11-12). Con un punto no hay evolución que medir.

La regla de selección está definida en `SNAPSHOTS_TEMPORALES.md`, pero no se ha
ejecutado. Es el primer entregable del siguiente sprint.

### 2.2 Tabla de identidad longitudinal como artefacto de primera clase

La identidad no puede recalcularse en cada snapshot de forma independiente: debe
existir un `entity_id` estable que sobreviva a renombres y movimientos, y que
sea la clave de unión entre todas las tablas del estudio.

Evidencia que lo justifica: de los 10 archivos seguidos, los 5 nacidos antes de
2012 acumulan 2 renombres cada uno, mientras que los 4 nacidos después de
2013-04-17 no tienen ninguno (`D3_ARTIFACT_IDENTITY.csv`, 21 eventos).

### 2.3 Clasificación de commits masivos frente a commits individuales

Hallazgo central de D3: el commit `8ee475dcc` (*"Update Apache License URL to
HTTPS"*, 2025-05-20) modificó **711 archivos** cambiando una línea en cada uno.
Al recalcular ignorando los **84 commits masivos** (≥ 50 archivos) del proyecto,
**26 de 30 archivos** del dataset resultaron contaminados en
`days_since_last_change`. El caso extremo, `SynchronizedQueue`, aparentaba 176
días sin cambios cuando su último cambio sustantivo fue en 2018-07-07: un sesgo
de **2,509 días**.

Sin esta clasificación, cualquier métrica de recencia del estudio es ruido.

Evidencia: `D3_Analisis_Evolucion.md`, `scripts/add_corrected_recency.sh`,
`D3_EVOLUTION_DATASET_CORREGIDO.csv`.

### 2.4 Clasificación de refactorings por naturaleza, no por conteo

De los **1,979** refactorings detectados por RefactoringMiner 3.0.10 en el rango
analizado, **1,934 (97.73 %)** provienen de tres commits que aplicaron una
convención de visibilidad de JUnit 5 en dos días. Solo **45 eventos (2.27 %)**
corresponden a trabajo de diseño individual.

Un estudio que use el conteo bruto como proxy de "pago de deuda" concluiría que
este periodo fue de intensa refactorización. Lo que ocurrió fue un barrido
mecánico.

Evidencia: `D4_Analisis_Refactorings.md`, `D4_REFACTORING_TIPOS.csv`,
`D4_REFACTORING_AUDIT_30.csv`.

### 2.5 Contexto de issues y pull requests, adaptado por proyecto

Es el núcleo de la Ruta B y lo único que todavía no se ha tocado. D2 muestra que
la recolección no puede ser uniforme: cinco proyectos concentran el contexto en
JIRA con la pestaña Issues de GitHub desactivada, dos lo tienen en GitHub
Issues, y `maven` usa ambos sistemas a la vez.

**Corrección registrada (2026-10-05, E-02).** La versión inicial de D2
clasificaba `maven` únicamente como JIRA. La verificación directa del
repositorio mostró la pestaña Issues activa con 582 issues abiertos y el propio
README del proyecto dirigiendo ahí los reportes de bugs. `maven` usa ambos
sistemas, lo que eleva a tres los modelos de ubicación del contexto en el
corpus.

Consecuencia para el diseño: el recolector no puede asumir una fuente única por
proyecto. En el caso de doble fuente habrá que unificar y resolver duplicados —
un mismo defecto puede estar registrado en los dos sistemas— antes de usar el
contexto como variable.

---

## 3. Modificar — qué parte del procedimiento actual no sirve directamente

| Procedimiento actual | Problema | Modificación propuesta |
|---|---|---|
| `git log --follow` archivo por archivo | No escala al corpus completo ni a múltiples snapshots; `--follow` solo acepta una ruta. | Construir el lineage una sola vez con `--name-status --find-renames` sobre todo el historial y persistirlo. |
| Criterio de identidad por similitud R100 | En este piloto la migración de paquete dio **R095–R099**, porque cambió la declaración `package` y los `import` en el mismo commit. Exigir R100 habría perdido los 5 archivos antiguos. | Umbral configurable más evidencia secundaria (mensaje de commit, ticket). Lo que no se pueda sostener se marca `AMBIGUOUS`, nunca se asigna por intuición. |
| `days_since_last_change` sin filtrar | Contaminada en 26 de 30 casos. | Sustituir por la versión corregida como métrica primaria. |
| Conteo bruto de refactorings | Dominado por tres commits mecánicos. | Separar barrido masivo de trabajo individual antes de cualquier agregación. |

---

## 4. No hacer todavía — qué debe esperar a otro sprint

- **Entrenar cualquier modelo predictivo.** El punto 10 del checklist sigue
  abierto: el riesgo **L-05** (etiquetas construidas con información futura) no
  está cerrado. El checklist es explícito: no se autoriza entrenamiento mientras
  ese punto permanezca abierto. (`D4_TEMPORAL_LEAKAGE.md`, 7 riesgos, 6
  mitigados.)
- **Fijar el corpus confirmatorio final.** D2 inventarió observabilidad, no
  seleccionó.
- **Interpretar un refactoring como pago de deuda técnica.** Requiere evidencia
  independiente que esta etapa no produjo.
- **Afirmar que el historial Git mejora la priorización.** Exige baseline,
  ablation y separación temporal ejecutada, no solo diseñada
  (`D_Separacion_Temporal.md`, punto 11: diseñada, no ejecutada).
- **Ampliar el corpus más allá de los ocho proyectos.**

---

## 5. Riesgos — qué podría impedir el nuevo estudio

| # | Riesgo | Evidencia que lo sustenta | Mitigación |
|---|---|---|---|
| R1 | **Eventos globales que se disfrazan de actividad individual.** No es una rareza del piloto: el mismo barrido de licencia del 2025-05-20 afectó a 711 archivos aquí y a 511 en el piloto paralelo. Es sistémico del corpus. | `D3_Analisis_Evolucion.md`, §9 del README | Filtrado por umbral de archivos por commit, con análisis de sensibilidad al umbral de 50. |
| R2 | **Fuga de información temporal.** Seis riesgos mitigados, L-05 abierto. | `D4_TEMPORAL_LEAKAGE.md` | Cerrar L-05 antes de cualquier experimento. |
| R3 | **Heterogeneidad del tracker.** El contexto de un cambio no vive en el mismo sitio en todos los proyectos. | `D2_CIMPS8_OBSERVABILIDAD.csv` | Recolector por proyecto; documentar cobertura real de la unión commit↔issue antes de usarla. |
| R4 | **Estructura multi-módulo.** Cinco de ocho proyectos tienen estructura profunda, lo que complica seguir un archivo. El piloto actual es mono-módulo, el caso fácil. | `D2_CIMPS8_OBSERVABILIDAD.csv` | Validar el procedimiento de identidad sobre un proyecto multi-módulo antes de generalizar. |
| R5 | **Generalización indebida desde un solo piloto.** La conclusión "la identidad se establece con R100" no es generalizable: depende de cómo cada proyecto ejecutó su migración. | §9 del README (divergencia R100 vs R095–R099) | Replicar el procedimiento en al menos un segundo proyecto antes de fijar criterios. |
| R6 | **Historial discontinuo por migración de VCS.** Conviven tres nombres de rama principal; `pdfbox` procede de Subversion. | `D2_CIMPS8_OBSERVABILIDAD.csv` | Verificar continuidad del historial en los proyectos migrados. |

---

## 6. Respuestas a las ocho preguntas del entregable

**1. ¿Qué unidad debería observar el nuevo estudio?**
El archivo `.java` como entidad con identidad longitudinal estable, observado en
múltiples instantes. No la ruta: la ruta cambia sin que cambie el artefacto, como
demostró `CollectionUtils.java` con dos migraciones globales.

**2. ¿Qué información podemos obtener de Git?**
Lo verificado en D3: commits previos, líneas agregadas y eliminadas, churn,
recencia del último cambio y número de colaboradores distintos, todo acotado por
`--before=decision_time`. Además, el lineage de renombres y movimientos con su
porcentaje de similitud. Lo que Git **no** da es por qué se hizo un cambio; eso
exige el tracker.

**3. ¿Qué dificultades existen para seguir un archivo a través del tiempo?**
Tres, todas observadas: las migraciones globales que arrastran a todos los
archivos vivos a la vez; la similitud por debajo de 100 cuando el renombre y la
edición ocurren en el mismo commit; y la estructura multi-módulo, que este piloto
no ejercitó por ser mono-módulo.

**4. ¿Qué tan factible resultó utilizar RefactoringMiner?**
Factible: 115 de 119 commits procesados sin errores con la versión 3.0.10. La
dificultad no es técnica sino interpretativa — el 97.73 % de la salida es ruido
mecánico que exige clasificación manual previa.

**5. ¿Qué información adicional podrían aportar issues o pull requests?**
La intención del cambio, que es lo único que permitiría distinguir una
corrección de un barrido. En este piloto la cadena `archivo → commit →
movimiento → ticket JIRA` quedó demostrada con COLLECTIONS-452. Falta medir qué
proporción de commits tiene esa trazabilidad; sin esa cifra no se puede afirmar
que la fuente sea utilizable.

**6. ¿Qué riesgos de temporalidad identificó?**
Los siete del ledger. El operativo ahora es L-05: construir etiquetas con
información posterior al `decision_time`.

**7. ¿Qué debería implementarse en el siguiente sprint?**
En orden: (a) la serie T0…Tn; (b) el lineage persistido como tabla de entidades;
(c) el cruce de `D4_REFACTORING_EVENTS_RAW.csv` con `D3_EVOLUTION_DATASET.csv`
por `(entity_id, commit)`.

**8. ¿Qué parte puede incorporarse al protocolo de Proyecto Guiado?**
El hallazgo de contaminación por eventos globales, porque afecta directamente a
la operacionalización de las variables del protocolo: cualquier indicador de
sobreesfuerzo basado en recencia o en conteo de cambios hereda ese sesgo si no se
filtra.

---

## 7. Trazabilidad del plan

| Apartado | Deriva de |
|---|---|
| Mantener | D1, D2 |
| Agregar | D2, D3, D4 |
| Modificar | D3, D4 |
| No hacer todavía | D4 (leakage), punto 11 |
| Riesgos | D2, D3, D4, §9 del README |

Ninguna entrada de este plan es una "mejora futura" genérica: todas responden a
una limitación observada y documentada en esta entrega.
