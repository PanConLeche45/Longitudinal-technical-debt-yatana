# Bitácora de errores y decisiones

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Proyecto:** Continuidad post-CIMPS — Ruta B — Gate G1A

Formato: `fecha → problema/decisión → causa → acción → evidencia → estado`

> Los errores documentados son evidencia del proceso de investigación. Esta
> bitácora registra tanto las decisiones de diseño como los errores cometidos y
> corregidos durante la ejecución.

---

## 2026-09-29

### D-01 · Selección del proyecto piloto
- **Decisión:** usar `apache/commons-collections` como piloto.
- **Causa:** comparte perfil estructural con `commons-lang` —mono-módulo,
  `src/main/java`, tracker JIRA, historial desde 2001— lo que permite aplicar la
  metodología de Ruta B sin adaptaciones; y al ser distinto del piloto del
  entregable paralelo, permite comprobar si los hallazgos son locales o
  sistémicos del corpus.
- **Alternativa descartada:** `junit4` (tracker en GitHub Issues en lugar de
  JIRA, proyecto en modo mantenimiento) y `checkstyle` (19,742 commits, demasiado
  pesado para el plazo).
- **Evidencia:** `D2_CIMPS8_OBSERVABILIDAD.csv`, fila `commons-collections`.
- **Estado:** Confirmado.

### D-02 · Estructura inicial del repositorio
- **Decisión:** crear el esqueleto versionado antes de generar ningún dato.
- **Causa:** requisito de reproducibilidad y provenance del gate.
- **Acción:** `git init`, carpetas `scripts/`, `repos/`, `docs/`, `.gitignore`
  excluyendo `repos/` y `tools/` por peso.
- **Evidencia:** commit inicial del repositorio.
- **Estado:** Completado.

---

## 2026-09-30

### D-03 · Alineación del `decision_time` con el entregable paralelo
- **Decisión:** usar `decision_time = 2025-11-12`, el mismo del entregable de
  W. Tehuatle sobre `commons-lang`.
- **Causa:** corresponde a la fecha del snapshot CIMPS. Mantenerlo idéntico hace
  que los dos pilotos sean comparables; cambiarlo habría hecho imposible saber si
  una diferencia entre resultados viene del proyecto o de la fecha.
- **Acción:** identificado el commit del repositorio en esa fecha,
  `e96986a5c` (2025-11-09), y el release vigente, `rel/commons-collections-4.5.0`.
- **Evidencia:** `PROVENANCE_INTEGRIDAD.md` §2.
- **Estado:** Confirmado.

### E-01 · ERROR — Falsos positivos en la detección de tracker JIRA
- **Problema:** la primera versión de `build_observability_inventory.sh` detectó
  el prefijo `UTF` para `checkstyle` (10 commits) y `GHSA` para `junit4`
  (1 commit), concluyendo erróneamente que esos proyectos usaban JIRA.
- **Causa:** el patrón `[A-Z]{2,15}-[0-9]+` usado para detectar tickets también
  coincide con `UTF-8` (codificación de caracteres) y con `GHSA-xxxx`
  (identificadores de avisos de seguridad de GitHub). Ambos aparecen en mensajes
  de commit sin ser tickets.
- **Consecuencia si no se corrige:** el inventario habría clasificado mal la
  fuente de contexto de dos de los ocho proyectos, que es exactamente el dato
  crítico para la Ruta B (dónde vive el contexto de un cambio).
- **Acción:** se añadieron dos filtros al script — una lista de exclusión de
  prefijos conocidos que no son trackers (`UTF`, `GHSA`, `ISO`, `RFC`, `CVE`,
  etc.) y un umbral mínimo de 50 commits para que un prefijo se considere el
  tracker del proyecto. Por debajo del umbral se clasifica como
  `GITHUB_ISSUES`.
- **Evidencia:** `scripts/build_observability_inventory.sh`, bloque comentado
  "NOTA (error corregido, ver bitacora E-01)". `D2_CIMPS8_OBSERVABILIDAD.csv`
  regenerado: `checkstyle` y `junit4` ahora figuran como `GITHUB_ISSUES`.
- **Estado:** **Corregido y verificado.**

### E-02 · ERROR de diseño — Rutas relativas rotas tras `cd`
- **Problema:** `build_artifact_identity.sh` falló en la primera ejecución con
  *"No such file or directory"* sobre el archivo de lista de entrada; generó
  0 eventos.
- **Causa:** el script hace `cd` al directorio del repositorio para ejecutar los
  comandos de Git, pero la ruta de la lista de entrada seguía siendo relativa al
  directorio de invocación, que ya no era el actual.
- **Acción:** se resolvieron a rutas absolutas tanto la salida (`OUT_ABS`) como
  la entrada (`LISTA_ABS`) antes del `cd`.
- **Evidencia:** `scripts/build_artifact_identity.sh`, comentario
  "Se resuelven rutas absolutas". Segunda ejecución: 21 eventos registrados.
- **Estado:** **Corregido.**

### H-01 · HALLAZGO — La similitud de renombre no siempre es 100%
- **Problema:** se esperaba replicar el patrón de `commons-lang`, donde ambas
  migraciones aparecen como `R100`. En `commons-collections` el cambio de
  paquete produce `R095`–`R099`.
- **Causa:** `commons-lang` separó el renombre de directorio del cambio de la
  declaración `package` en commits distintos; `commons-collections` lo hizo todo
  en el commit `a8d1066b5`, por lo que el contenido cambió junto con la ruta.
- **Consecuencia metodológica:** un criterio de identidad que exigiera `R100`
  perdería los 5 archivos antiguos de este piloto. El criterio debe aceptar
  similitudes menores y apoyarse en la evidencia secundaria (mensaje de commit +
  ticket del tracker).
- **Evidencia:** `D3_ARTIFACT_IDENTITY.csv`, filas con
  `tipo_evento = RENAME_CON_CAMBIOS`. Análisis en `D3_Analisis_Evolucion.md` §2.4.
- **Estado:** Documentado. Divergencia respecto al entregable paralelo,
  registrada explícitamente.

### E-03 · ERROR de medición — Recencia contaminada por commits masivos
- **Problema:** 25 de los 30 archivos del dataset mostraban exactamente la misma
  fecha de último cambio: 2025-05-20.
- **Causa:** el commit `8ee475dcc` (*"Update Apache License URL to HTTPS"*)
  modificó **711 archivos**, cambiando una sola línea en cada uno. La métrica
  `days_since_last_change` calculada de forma ingenua lo trata como actividad
  individual del archivo.
- **Consecuencia:** 26 de 30 archivos con la métrica contaminada. Caso extremo:
  `SynchronizedQueue` aparenta 176 días de antigüedad cuando su último cambio
  sustantivo fue el 2018-07-07 — un sesgo de **2,509 días**.
- **Acción:** se escribió `scripts/add_corrected_recency.sh`, que identifica
  todos los commits con ≥ 50 archivos (84 en este piloto) y recalcula la
  recencia ignorándolos. Se generó `D3_EVOLUTION_DATASET_CORREGIDO.csv` con las
  columnas `days_since_last_change_corregido`, `sesgo_recencia_dias` y
  `contaminado_por_commit_masivo`.
- **Evidencia:** ambos datasets, el script, y `D4_TEMPORAL_LEAKAGE.md` §L-03.
- **Estado:** **Mitigado**, con la salvedad de que el umbral de 50 archivos es
  una decisión de diseño sin validación empírica. Análisis de sensibilidad
  pendiente.

### D-04 · Decisión — Umbral de commit masivo en 50 archivos
- **Decisión:** considerar "masivo" todo commit que toque 50 archivos o más.
- **Causa:** se necesitaba un criterio operativo. 50 está muy por encima del
  tamaño de un commit de trabajo normal en este proyecto y muy por debajo de los
  barridos observados (454–714 archivos), por lo que separa con holgura.
- **Limitación reconocida:** el valor no se derivó de un análisis de la
  distribución de tamaños de commit. Es una elección justificable, no validada.
- **Evidencia:** parámetro `UMBRAL` en `scripts/add_corrected_recency.sh`.
- **Estado:** Adoptado provisionalmente; pendiente análisis de sensibilidad.

### H-02 · HALLAZGO — El 97.73% de los refactorings son un barrido de convención
- **Problema:** la distribución de tipos de refactoring resultó degenerada: un
  solo tipo (*Change Method Access Modifier*) con el 92.77% de los 1,979 eventos
  detectados.
- **Causa:** tres commits del 2025-06-07/08 (`d1a4c56c3`, `48afb43fa`,
  `3d737b007`) aplican la convención de visibilidad de JUnit 5 sobre toda la
  suite de pruebas. Concentran 1,934 de los 1,979 eventos.
- **Consecuencia metodológica:** usar el conteo bruto de refactorings como proxy
  de "esfuerzo de mejora" o "pago de deuda" produciría una conclusión falsa sobre
  este periodo. Solo 45 eventos (2.27%) corresponden a trabajo de diseño real.
- **Acción:** se añadieron las columnas `archivos_en_commit` y `evento_masivo` a
  `D4_REFACTORING_EVENTS_RAW.csv`, y el desglose masivo/individual por tipo a
  `D4_REFACTORING_TIPOS.csv`.
- **Evidencia:** `D4_Analisis_Refactorings.md` §2.
- **Estado:** Documentado y mitigado a nivel de marcado.

### H-03 · HALLAZGO — El sesgo por eventos globales es sistémico, no local
- **Observación:** el commit de barrido de licencia del 2025-05-20 aparece en
  los dos pilotos del equipo: 511 archivos en `commons-lang` (entregable
  paralelo) y 711 en `commons-collections` (este trabajo).
- **Interpretación:** es el mismo barrido de la Apache Software Foundation
  aplicado a componentes distintos. El fenómeno afecta al corpus completo, no a
  un proyecto.
- **Consecuencia:** el filtrado de eventos globales no es un ajuste local del
  piloto; es una condición de validez para el estudio longitudinal sobre los
  ocho proyectos.
- **Evidencia:** `D3_Analisis_Evolucion.md` §5.3, contrastado con el README del
  entregable paralelo.
- **Estado:** Documentado. Pendiente de verificar en los seis proyectos restantes.

### D-05 · Decisión — No cerrar el punto 10 del checklist
- **Decisión:** declarar el control de fuga temporal **ABIERTO** y, en
  consecuencia, no entrenar ningún modelo.
- **Causa:** el riesgo L-05 (etiquetas construidas con información posterior al
  corte) no está mitigado, porque no se han definido etiquetas. El checklist
  prohíbe expresamente el entrenamiento mientras el punto 10 siga abierto.
- **Evidencia:** `D4_TEMPORAL_LEAKAGE.md`, resumen final.
- **Estado:** Asumido conscientemente.

### D-06 · Decisión — Declarar honestamente el entorno de ejecución
- **Decisión:** hacer constar en `PROVENANCE_INTEGRIDAD.md` que los artefactos
  de datos se generaron en un entorno de trabajo asistido (contenedor Linux) y
  no en el equipo personal de la autora.
- **Causa:** el gate exige que otra persona pueda reconstruir el dataset; eso
  incluye saber dónde y con qué versiones se construyó. Omitirlo sería declarar
  algo falso.
- **Acción:** tabla comparativa de versiones y batería de comandos de
  verificación independiente en `PROVENANCE_INTEGRIDAD.md` §5, para reproducción
  local.
- **Estado:** Pendiente de ejecución de la verificación local por la autora.

### L-01 · LIMITACIÓN — D1 incompleto
- **Problema:** la matriz del estado del arte contiene 2 artículos primarios
  leídos íntegramente, no los 8 que sería deseable.
- **Causa:** plazo de entrega. Además, el acceso a Herzig, Just & Zeller (2016)
  fue rechazado por el servidor de Springer (HTTP 429) durante la sesión.
- **Acción:** se separó explícitamente la matriz en "leídos íntegramente" y
  "identificados, pendientes de lectura". Los segundos no sustentan el gap.
- **Evidencia:** `D1_Estado_Arte_Gap.md` §1.1 y §1.2.
- **Estado:** **Abierto.** Es la principal carencia de esta entrega.

### L-02 · LIMITACIÓN — Punto 7 (snapshots múltiples) no satisfecho
- **Problema:** el checklist exige múltiples puntos temporales T0…Tn. Este
  trabajo tiene un único `decision_time` y una ventana retrospectiva.
- **Acción:** se definió y justificó la regla de selección de snapshots (por
  release final, con inserción anual en huecos > 24 meses) y se dejó el script
  parametrizado para aceptar cualquier `decision_time` y `commit_ref`. La serie
  no está construida.
- **Evidencia:** `SNAPSHOTS_TEMPORALES.md`.
- **Estado:** **Abierto.** Primer entregable del siguiente sprint.
