# Diccionario de datos

**Estudiante:** Yatana Roa Moreno — ZS23020600 · Gate G1A · 2026-09-30

---

## `D2_CIMPS8_OBSERVABILIDAD.csv`

Inventario de observabilidad de los 8 proyectos del corpus CIMPS.
Generado por `scripts/build_observability_inventory.sh`. 8 filas.

| Columna | Tipo | Descripción |
|---|---|---|
| `proyecto` | texto | Nombre del repositorio |
| `rama_principal` | texto | Rama de desarrollo (`master`, `main` o `trunk`) |
| `total_commits` | entero | `git rev-list --all --count` |
| `primer_commit` | fecha | Inicio de la ventana observable |
| `ultimo_commit` | fecha | Fin de la ventana observable |
| `num_tags` | entero | Releases/tags disponibles como candidatos a snapshot |
| `estructura_java` | categoría | `mono-modulo`, `multi-modulo`, `multi-modulo-profundo` |
| `ruta_java_principal` | ruta | Primer `src/main/java` encontrado |
| `prefijo_jira` | texto | Prefijo de ticket dominante, o `GITHUB_ISSUES` |
| `commits_con_jira` | entero | Commits cuyo mensaje cita un ticket del tracker |
| `observaciones` | texto | Notas cualitativas |

> El campo `prefijo_jira` aplica una lista de exclusión (`UTF`, `GHSA`, `CVE`…)
> y un umbral mínimo de 50 commits. Ver bitácora E-01.

---

## `D3_ARTIFACT_IDENTITY.csv`

Eventos de identidad longitudinal. Generado por
`scripts/build_artifact_identity.sh`. 21 filas.

| Columna | Tipo | Descripción |
|---|---|---|
| `entity_id` | texto | Nombre de la clase sin extensión |
| `ruta_actual` | ruta | Ubicación en el commit de referencia |
| `tipo_evento` | categoría | `NACIMIENTO`, `MOVE_EXACTO` (R100), `RENAME_CON_CAMBIOS` (R<100) |
| `similitud` | entero | Porcentaje de similitud calculado por Git; vacío en nacimientos |
| `commit` | hash | Commit abreviado donde ocurrió el evento |
| `fecha` | fecha | Fecha del commit |
| `ruta_origen` | ruta | Ruta anterior (vacía en nacimientos) |
| `ruta_destino` | ruta | Ruta posterior |
| `mensaje_commit` | texto | Mensaje, truncado a 90 caracteres |

> Las filas se listan en orden de `git log`: del evento más reciente al más
> antiguo. El `NACIMIENTO` es siempre la última fila de cada entidad.

---

## `D3_EVOLUTION_DATASET.csv`

Dataset de evolución. Generado por `scripts/build_evolution_dataset.sh`.
30 filas. **Todas las métricas se calculan con `--before=decision_time`.**

| Columna | Tipo | Descripción |
|---|---|---|
| `project_id` | texto | Proyecto (`commons-collections`) |
| `entity_id` | texto | Nombre de la clase |
| `file_path` | ruta | Ruta en el commit de referencia |
| `estrato` | categoría | `ALTO` (hotspot), `MEDIO`, `BAJO` (tranquilo) |
| `decision_time` | fecha | Momento de decisión (2025-11-12) |
| `commit_ref` | hash | Commit que materializa el corte |
| `prior_commits` | entero | Commits que tocaron el archivo **antes** del corte |
| `lines_added` | entero | Líneas agregadas acumuladas (sin merges) |
| `lines_deleted` | entero | Líneas eliminadas acumuladas (sin merges) |
| `churn` | entero | `lines_added + lines_deleted` |
| `days_since_last_change` | entero | Días entre el último cambio y `decision_time` |
| `distinct_contributors` | entero | Autores distintos antes del corte |
| `last_change_date` | fecha | Fecha del último cambio antes del corte |

> **Advertencia:** `days_since_last_change` está contaminada en 26 de las 30
> filas por commits masivos. Usar la versión corregida.

---

## `D3_EVOLUTION_DATASET_CORREGIDO.csv`

Igual que el anterior, más cuatro columnas. Generado por
`scripts/add_corrected_recency.sh` con umbral de 50 archivos.

| Columna | Tipo | Descripción |
|---|---|---|
| `days_since_last_change_corregido` | entero | Recencia ignorando los 84 commits masivos |
| `last_change_date_corregida` | fecha | Fecha del último cambio **no masivo** |
| `sesgo_recencia_dias` | entero | Diferencia entre la métrica corregida y la ingenua |
| `contaminado_por_commit_masivo` | `SI`/`NO` | Si la métrica ingenua difería de la corregida |

---

## `D4_REFACTORING_EVENTS_RAW.csv`

Eventos de refactoring normalizados desde la salida de RefactoringMiner.
Generado por `scripts/parse_refactoring_events.py`. 1,979 filas.

| Columna | Tipo | Descripción |
|---|---|---|
| `event_id` | texto | `<commit>-<índice>`, único |
| `project_id` | texto | Proyecto |
| `commit` | hash | Commit abreviado (9 caracteres) |
| `commit_full` | hash | Commit completo (40 caracteres) |
| `fecha` | fecha | Fecha del commit |
| `autor` | texto | Autor del commit |
| `tipo_refactoring` | categoría | Tipo del catálogo de RefactoringMiner (22 distintos) |
| `entity_id` | texto | Clase del archivo principal afectado |
| `archivo_principal` | ruta | Primer archivo `.java` afectado |
| `num_archivos_afectados` | entero | Archivos `.java` implicados en el evento |
| `descripcion` | texto | Descripción de RefactoringMiner, truncada a 200 |
| `mensaje_commit` | texto | Mensaje del commit, truncado a 120 |
| `archivos_en_commit` | entero | **Total** de archivos tocados por el commit |
| `evento_masivo` | `SI`/`NO` | `SI` si `archivos_en_commit >= 50` |

> **Clave de uso:** filtrar por `evento_masivo == NO` deja 45 eventos, que son
> los que reflejan trabajo de diseño individual. Los 1,934 marcados `SI`
> provienen de tres commits de convención mecánica.

---

## `D4_REFACTORING_TIPOS.csv`

Distribución de tipos con desglose masivo/individual. 22 filas.

| Columna | Tipo | Descripción |
|---|---|---|
| `tipo_refactoring` | texto | Tipo del catálogo |
| `total` | entero | Ocurrencias totales |
| `en_commits_masivos` | entero | Ocurrencias en commits de ≥ 50 archivos |
| `en_commits_individuales` | entero | Ocurrencias en commits de trabajo normal |
| `pct_masivo` | decimal | Porcentaje atribuible a barridos |

---

## `D4_REFACTORING_AUDIT_30.csv`

Muestra auditable de 30 eventos (semilla fija `20250930`, reproducible).

| Columna | Tipo | Descripción |
|---|---|---|
| `event_id` | texto | Identificador del evento |
| `commit` | hash | Commit abreviado |
| `fecha` | fecha | Fecha del commit |
| `tipo_refactoring` | categoría | Tipo detectado |
| `entity_id` | texto | Clase afectada |
| `archivo_principal` | ruta | Archivo afectado |
| `descripcion` | texto | Descripción de RefactoringMiner |
| `comando_verificacion` | texto | Comando para comprobarlo contra Git |
| `archivo_existe_en_commit` | `SI`/`NO` | Verificación automática |
| `veredicto_auditoria` | categoría | `COHERENTE` o `REVISAR` |

---

## Convenciones generales

- **Codificación:** UTF-8. **Separador:** coma. **Fechas:** `YYYY-MM-DD`.
- Las comas dentro de campos de texto se sustituyen por `;` en la generación.
- `NA` indica valor no calculable, no cero.
- Ningún archivo de datos se editó a mano: todos provienen de los scripts
  versionados en `scripts/`.
