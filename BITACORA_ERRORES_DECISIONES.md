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

---

## 2026-10-05

### E-04 · ERROR — Clasificación incompleta del tracker de `maven`
- **Problema:** D2 clasificaba `maven` únicamente como usuario de JIRA. El
  proyecto usa JIRA (MNG) **y** GitHub Issues de forma simultánea.
- **Causa:** `build_observability_inventory.sh` deduce el tracker a partir de
  los prefijos de ticket presentes en los mensajes de commit. `maven` usa `MNG-`
  en 4,619 commits, por lo que el script concluyó JIRA y no comprobó si además
  la pestaña Issues de GitHub estaba activa. El método de detección no puede
  observar ese dato: vive en la configuración del repositorio, no en el
  historial.
- **Consecuencia si no se corrige:** el recolector de contexto de la Ruta B
  habría buscado el contexto de los cambios de `maven` en una sola de sus dos
  fuentes, perdiendo los issues registrados en GitHub.
- **Acción:** verificación manual del repositorio y corrección del campo
  `external_tracker` a doble fuente. Se añadió al inventario la columna
  `issues_available` para registrar este dato de forma explícita en los ocho
  proyectos.
- **Evidencia:** `github.com/apache/maven` — pestaña Issues activa con 582
  issues abiertos; el README del proyecto dirige los reportes de bugs a
  `github.com/apache/maven/issues`. Verificado el 2026-10-05.
- **Hallazgo derivado:** el corpus no tiene dos modelos de ubicación del
  contexto, sino tres. El caso de doble fuente obliga a unificar y resolver
  duplicados antes de usar el contexto como variable.
- **Estado:** **Corregido.** La divergencia con el entregable paralelo, que
  clasificaba `maven` correctamente desde el inicio, queda resuelta a favor de
  aquél.

### E-05 · ERROR — `ruta_java_principal` apunta a módulos periféricos
- **Problema:** en los cuatro proyectos multi-módulo, la ruta registrada no
  corresponde al código principal. El caso más claro es `maven`, donde la ruta
  registrada apuntaba a un recurso de prueba dentro de la suite de tests de
  integración (`its/core-it-suite/src/test/resources/...`), que no es código de
  producción.
- **Causa:** el script toma la primera coincidencia de `src/main/java` que
  devuelve `find`, y ese orden no tiene relación con la importancia del módulo.
- **Consecuencia si no se corrige:** cualquier selección de archivos basada en
  esa ruta analizaría módulos periféricos o código de prueba en lugar del
  núcleo del proyecto, invalidando la comparación entre proyectos.
- **Acción:** PENDIENTE — inspeccionar manualmente los cuatro proyectos
  multi-módulo y registrar la ruta del módulo principal. Documentar aquí el
  criterio adoptado para decidir cuál es "el módulo principal": módulo raíz
  declarado en el POM, mayor volumen de código, u otro.
- **Alcance:** afecta a `commons-math`, `httpcomponents-client`, `maven` y
  `pdfbox`. Los cuatro mono-módulo no están afectados.
- **Nota:** el piloto de este trabajo, `commons-collections`, es mono-módulo,
  por lo que ni D3 ni D4 están afectados por este error. El impacto se limita al
  inventario D2 y a la futura ampliación del estudio al corpus completo.
- **Evidencia:** `D2_CIMPS8_OBSERVABILIDAD.csv`, columna `ruta_java_principal`,
  valores marcados `VERIFICAR`.
- **Estado:** **Abierto.**

### D-07 · Decisión — Completar el inventario con las columnas del entregable
- **Decisión:** ampliar `D2_CIMPS8_OBSERVABILIDAD.csv` con los campos
  `repository_url`, `issues_available`, `pull_requests_available`,
  `external_tracker`, `recent_activity`, `rename_move_evidence`, `main_risk` y
  `evidence`.
- **Causa:** la tabla mínima del entregable D2 los exige, y el criterio de
  aceptación pide que cada dato importante tenga evidencia asociada. La versión
  anterior del inventario registraba los datos obtenibles por script pero no los
  que requieren inspección de la interfaz de GitHub.
- **Limitación reconocida:** los campos marcados `PENDIENTE` corresponden a
  datos que solo pueden obtenerse inspeccionando cada repositorio en GitHub.
  Mientras sigan marcados así, el inventario no cumple el criterio de
  aceptación de D2.
- **Estado:** Estructura completada; relleno **pendiente**.

---

# Sprint 2 — Línea E3 (hotspot / co-change)

## 2026-10-05

### D-08 · Decisión — Construir E3 en los dos pilotos
- **Decisión:** el extractor E3 se ejecuta en `commons-collections` (mi piloto, integrado con mi E2) y
  en `commons-lang` (piloto de Willian, integrado con su E2).
- **Causa:** el correo pide trabajar "sobre el mismo proyecto piloto" y una tabla conjunta con la llave
  `project + artifact_id + decision_time`; la redacción admite ambas lecturas y el script es genérico.
- **Estado:** **pendiente de confirmar** con el profesor cuál es el piloto oficial de la tabla integrada.

### D-09 · Decisión — Transacción = commit; corte = ancestros del decision commit
- **Decisión:** un co-change es aparecer en el mismo commit no-merge. Sólo se usan commits ancestros del
  decision commit (`git log <sha>`), y además se verifica que ninguna fecha supere el decision_time.
- **Causa:** agrupar por día (Bochicchio et al., 2025) mezcla trabajo no relacionado; `--before=fecha`
  admitiría commits fechados antes pero integrados después.
- **Evidencia:** `sprint2_E3/out/*/E3_RUN_MANIFEST_*.json`, `TEMPORAL_CHECK.json`.

### D-10 · Decisión — Umbral de commit masivo en 50 (igual que D-04), 100 como sensibilidad
- **Decisión:** se excluyen del conteo los commits con > 50 archivos de producción.
- **Causa:** coherencia con D-04 de G1A, fijado antes de ver resultados de E3; 100 es el umbral de
  D'Ambros et al. (2009) y se corre como análisis de sensibilidad (pendiente 6 de G1A).
- **Resultado:** ρ(50 vs 100) = 0.97 para M1 y M2 en commons-collections; 0.99 en commons-lang.

### D-11 · Decisión — Identidad con `-M` por commit, no con `--follow`
- **Decisión:** los renombres se resuelven con la detección de Git dentro de cada commit y se mapean a la
  ruta vigente en el decision commit. Tests excluidos del universo.
- **Causa:** H-04.

### D-12 · Decisión — Dos medidas candidatas fijadas a priori
- **Decisión:** M1 = grado de co-change (k = 2), M2 = confianza máxima (k = 2). Ninguna se modifica en
  este sprint aunque muestren limitaciones (H-06).
- **Evidencia:** `sprint2_E3/M_MEDIDAS_CANDIDATAS.md`.

### E-06 · ERROR — `entity_id` no identifica de forma única al artefacto
- **Problema:** en `D3_EVOLUTION_DATASET.csv`, tres filas tienen `entity_id = package-info`
  (`trie/`, `splitmap/`, `map/`).
- **Consecuencia si no se corrige:** la llave `project + artifact_id + decision_time` sería ambigua y la
  integración uniría filas equivocadas.
- **Acción:** `sprint2_E3/data/ARTIFACTS_commons-collections.csv` asigna `artifact_id` C001–C030 en el
  orden del dataset, conservando `entity_id` y la ruta. El extractor aborta si la llave no es única.
- **Estado:** **Mitigado** en Sprint 2; el dataset de G1A no se modifica.

### H-04 · HALLAZGO — `git log --follow` construye linajes falsos en E2
- **Observación:** `prior_commits = n_commits_e3 + commits masivos` se cumple exactamente en 16/30
  archivos de commons-collections y 19/30 de commons-lang; en el resto `--follow` salta a archivos
  parecidos (p. ej. `Get.java` → `TestAll`, `HashBag`; `ListOrderedSet` → colecciones primitivas;
  en commons-lang hasta `LICENSE`). Diferencia máxima: 62 commits (C007).
- **Impacto:** puntos 6 y 8 de G1A; el estrato MEDIO de ambos datasets está sobrerrepresentado por
  archivos inflados; la verificación manual con el mismo `--follow` no era independiente.
- **Evidencia:** `sprint2_E3/HALLAZGO_LINAJE_FOLLOW.md`, columna `check_e2_minus_e3`.
- **Estado:** **Abierto** — revisar con Willian; no eliminar archivos.

### H-05 · HALLAZGO — El co-change reciente es mayoritariamente cosmético
- **Observación:** 8 de 10 commits recientes de commons-collections y 6 de 10 de commons-lang son de
  Javadoc; en commons-collections todos los pares repetidos de la práctica son cosméticos. En
  SynchronizedQueue, 6 de sus 7 socios de M1 provienen de dos barridos (comentarios, ortografía).
- **Relación:** *tangled changes* (Herzig, Just & Zeller, 2016), pendiente en D1.
- **Estado:** Documentado como amenaza de constructo; posible filtro en el siguiente sprint.

### H-06 · HALLAZGO — M1 replica a E2; M2 aporta información pero es inestable
- **Observación:** ρ(M1, prior_commits) = 0.96 (collections) / 0.87 (lang); ρ(M2, prior_commits) =
  −0.13 / 0.33; en collections M2 correlaciona −0.58 con LOC (valores altos en archivos pequeños).
- **Estado:** exploratorio (n = 30 por piloto). El valor incremental se medirá en el experimento.

## 2026-10-15

### E-07 · ERROR — El `decision_time` de G1A no era el snapshot CIMPS de commons-collections
- **Problema:** G1A fijó `decision_time = 2025-11-12` (commit `e96986a5c`) y el README y
  `SNAPSHOTS_TEMPORALES.md` afirman que "corresponde a la fecha del snapshot CIMPS". Según la Tabla 1
  del artículo CIMPS, el snapshot de commons-collections es `rel/commons-collections-4.5.0`,
  commit `7f7fb0244abc` (2025-04-19).
- **Causa:** la fecha 2025-11-12 se tomó del entregable paralelo; corresponde al release 3.20.0 de
  **commons-lang** (`598dfc163b8b`), que sí es el snapshot CIMPS de ese proyecto. No se cotejó con el
  artículo porque no estaba disponible al construir G1A.
- **Consecuencia si no se corrige:** E1 (métricas estáticas, continuación de CIMPS) y E2/E3 quedarían
  observados en momentos distintos; la integración E1+E2+E3 no describiría el mismo estado del código.
- **Acción:** D-13. Los entregables etiquetados de G1A (`g1a-2026-09-30`, `g1a-2026-10-05`) no se
  reescriben; la corrección queda aquí y en `sprint2_E3/`.
- **Evidencia:** artículo CIMPS, Tabla 1 (no se incluye en el repositorio por confidencialidad);
  `git log -1 7f7fb0244` → 2025-04-19T13:58:13+00:00 "Prepare for the release candidate 4.5.0 RC1".
- **Estado:** **Corregido** en Sprint 2.

### D-13 · Decisión — Alinear el decision_time principal al snapshot CIMPS (4.5.0)
- **Decisión:** decision_time principal de commons-collections = commit `7f7fb0244` (rel 4.5.0),
  etiqueta de llave `2025-04-19`; corte de E2 = `2025-04-19T13:58:14+00:00` (1 s después del commit,
  para incluirlo). Se verificó que, en ese corte, los commits con fecha ≤ corte en `master` son
  exactamente los 4,851 ancestros de `7f7fb0244` (sin diferencias).
- **Muestra:** se re-ejecutó `build_evolution_dataset.sh` en el corte para que la selección
  estratificada use sólo información ≤ 4.5.0 (seleccionar con la actividad hasta 2025-11-12 sería
  fuga por selección). Resultado: 29 de 30 archivos coinciden con G1A; sale `trie/package-info`
  (C021), entra `ConcurrentReferenceHashMap` (C031). `artifact_id` estable por ruta.
- **Se conserva** 2025-11-12 como momento posterior de la misma muestra y como integración
  secundaria con la muestra de G1A.
- **Evidencia:** `sprint2_E3/data/E2_commons-collections_2025-04-19/`,
  `sprint2_E3/data/ARTIFACTS_commons-collections*.csv`, `sprint2_E3/scripts/run_e3.sh`.

### H-07 · HALLAZGO — La magnitud de la contaminación por eventos globales depende del corte
- **Observación:** con el mismo umbral (50), en 4.5.0 sólo **1 de 30** archivos tiene la recencia
  contaminada (SynchronizedQueue, sesgo 1,583 días); en 2025-11-12 eran **26 de 30**. La diferencia
  es el barrido de licencia del 2025-05-20, posterior al snapshot CIMPS.
- **Implicación:** el hallazgo central de G1A (H-03) sigue siendo válido como mecanismo, pero la
  cifra 26/30 es propia del corte elegido; en un diseño longitudinal cada snapshot debe
  re-evaluarse.
- **Evidencia:** `sprint2_E3/data/E2_commons-collections_2025-04-19/D3_EVOLUTION_DATASET_CORREGIDO.csv`.

## 2026-10-25

### D-14 · Decisión — Nomenclatura: el sprint de E1/E2/E3 es el Sprint 2
- **Decisión:** G1A corresponde al Sprint 1 (como en el entregable paralelo); el sprint de las tres
  familias de evidencia es el **Sprint 2**. Carpeta `sprint2_E3/`, rama `sprint2-e3`.
- **Causa:** corrección de nomenclatura de la autora; sustituye el renombre del 2026-10-14.
- **Efecto:** sólo nombres de carpeta, rama y textos; ningún resultado cambia (salidas regeneradas con
  `run_e3.sh`, verificación temporal sin cambios).

### E-08 · Error — HTTP 403 al exportar métricas con un token de análisis
- **Qué pasó:** el análisis de 4.5.0 corrió con un *Global Analysis Token* (`sqa_`), pero la exportación
  (`api/measures/component_tree`) respondió **403**: ese tipo de token sólo puede enviar análisis, no
  leer resultados. La espera del paso 4 tampoco podía leer `api/ce/component` y terminó por tiempo.
- **Corrección:** se usa un *User Token* (`squ_`). `run_e1_sonar.sh` ahora comprueba antes si el token
  puede leer métricas, y si el proyecto ya está analizado se salta la reanálisis (`FORCE=1` para
  forzarla). `export_sonar_file_metrics.py` da un mensaje claro ante 401/403.
- **Efecto en resultados:** ninguno; no se había generado ningún CSV de E1.
