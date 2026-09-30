# D4 — Ledger de fuga temporal (*temporal leakage*)

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Piloto:** `apache/commons-collections` · **decision_time:** 2025-11-12
**Gate:** G1A · **Versión:** v1.0 — 2026-09-30

> **Estado del punto 10 del checklist:** ABIERTO.
> Mientras este punto permanezca abierto **no se autoriza entrenamiento de
> modelos**. Este documento identifica los riesgos; no todos están mitigados.

---

## Definición operativa

Existe **fuga temporal** cuando una observación fechada en `t` incorpora,
directa o indirectamente, información que en `t` todavía no existía. En un
estudio longitudinal de deuda técnica la fuga produce modelos que parecen
predecir bien y que en producción no predicen nada, porque durante el
entrenamiento tuvieron acceso al futuro.

La regla que este trabajo aplica y verifica es:

```
feature_timestamp <= decision_time
```

---

## Ledger

### L-01 · Métricas calculadas sobre el historial completo

| | |
|---|---|
| **Riesgo** | Calcular `prior_commits`, `churn` o `distinct_contributors` sobre todo el historial del archivo, incluyendo commits posteriores al momento de decisión. |
| **Causa** | `git log -- <archivo>` sin acotar devuelve el historial completo hasta HEAD. Es el comportamiento por defecto. |
| **Consecuencia** | La métrica del momento `t` incorpora actividad posterior a `t`. Un archivo que se volvió problemático **después** del corte aparece como problemático **antes**. El modelo aprende a "predecir" un futuro que ya tiene en la entrada. |
| **Mitigación** | Todas las invocaciones en `scripts/build_evolution_dataset.sh` llevan `--before="$DECISION_TIME"`. Verificable ejecutando `grep -c 'before' scripts/build_evolution_dataset.sh`. |
| **Estado** | **MITIGADO** y verificado (§ verificación manual, README §7.3). |

### L-02 · Universo de archivos tomado del estado actual (HEAD)

| | |
|---|---|
| **Riesgo** | Seleccionar los archivos a analizar a partir del árbol actual del repositorio en lugar del árbol vigente en `decision_time`. |
| **Causa** | `find src/main/java -name '*.java'` lista lo que existe hoy. |
| **Consecuencia** | Doble sesgo. (a) *Survivorship bias*: se excluyen archivos que existían en `t` y fueron borrados después, que son precisamente los candidatos a deuda terminal. (b) Se incluyen archivos creados después de `t`, que en `t` no existían. |
| **Mitigación** | El universo se construye con `git ls-tree -r --name-only <commit_ref>`, es decir, el árbol exacto del commit de referencia `e96986a5c`. Adicionalmente se descartan archivos con `prior_commits == 0`. |
| **Estado** | **MITIGADO** parcialmente. El *survivorship bias* persiste: los archivos borrados antes de `decision_time` siguen fuera del universo. Documentado como amenaza a la validez pendiente. |

### L-03 · Eventos globales de proyecto disfrazados de actividad individual

| | |
|---|---|
| **Riesgo** | Tratar un commit que modifica cientos de archivos a la vez (barrido de licencia, formateo global, cambio de convención) como si fuera actividad de desarrollo sobre cada archivo. |
| **Causa** | Git registra el evento idénticamente para los 711 archivos afectados; no hay marca que distinga trabajo de diseño de barrido mecánico. |
| **Consecuencia** | Documentada y cuantificada en este piloto: **26 de 30 archivos** del dataset muestran `days_since_last_change` contaminada por el commit `8ee475dcc` ("Update Apache License URL to HTTPS", 2025-05-20, **711 archivos**). El caso extremo es `SynchronizedQueue`: aparenta 176 días de antigüedad cuando su último cambio sustantivo fue **2018-07-07**, un sesgo de **2,509 días**. Un modelo entrenado con esta variable aprendería la fecha del barrido de licencia, no la actividad del archivo. |
| **Mitigación** | `scripts/add_corrected_recency.sh` identifica todos los commits que tocan ≥ 50 archivos (84 en este piloto) y recalcula la recencia ignorándolos. El dataset corregido incluye las columnas `days_since_last_change_corregido`, `sesgo_recencia_dias` y `contaminado_por_commit_masivo`. |
| **Estado** | **MITIGADO** con salvedad: el umbral de 50 archivos es una decisión de diseño, no un valor derivado empíricamente. Sensibilidad al umbral pendiente de evaluar. |

### L-04 · Conteos de refactoring dominados por barridos mecánicos

| | |
|---|---|
| **Riesgo** | Usar el número de refactorings detectados por RefactoringMiner como proxy de "actividad de mejora" o "pago de deuda". |
| **Causa** | RefactoringMiner detecta correctamente operaciones que son, formalmente, refactorings (p. ej. *Change Method Access Modifier*), sin distinguir si responden a una decisión de diseño o a la aplicación mecánica de una convención sobre toda la base de código. |
| **Consecuencia** | Cuantificada en este piloto: de **1,979** refactorings detectados en la ventana `rel-4.5.0 → decision_time`, **1,934 (97.73%)** provienen de **tres commits** del 2025-06-07/08 que aplican la convención de visibilidad de JUnit 5. Solo **45 eventos (2.27%)** corresponden a trabajo de diseño individual. Un estudio que tomara el conteo bruto concluiría que este periodo fue de intensa mejora de diseño; fue un cambio de convención de pruebas. |
| **Mitigación** | `D4_REFACTORING_EVENTS_RAW.csv` incluye las columnas `archivos_en_commit` y `evento_masivo`, que permiten filtrar. `D4_REFACTORING_TIPOS.csv` desglosa cada tipo entre commits masivos e individuales. |
| **Estado** | **MITIGADO** a nivel de marcado. El criterio para decidir qué eventos entran en un análisis posterior sigue abierto. |

### L-05 · Etiquetas construidas con información posterior al corte

| | |
|---|---|
| **Riesgo** | Definir la variable objetivo (p. ej. "este archivo acumuló deuda") observando lo que ocurrió **después** de `decision_time`, y luego permitir que alguna característica de entrada también mire ese periodo. |
| **Causa** | En un diseño predictivo la etiqueta **debe** venir del futuro respecto de las características; el error aparece cuando esa frontera no está escrita en ningún sitio y una característica la cruza sin que nadie lo note. |
| **Consecuencia** | Rendimiento inflado, irreproducible fuera del laboratorio. Es la forma más difícil de detectar porque no produce ningún error visible. |
| **Mitigación** | **NO MITIGADO.** En esta etapa no se han definido etiquetas ni se ha entrenado ningún modelo, precisamente porque el punto 10 lo prohíbe. La frontera está declarada en `D_Separacion_Temporal.md` pero no ejercitada. |
| **Estado** | **ABIERTO.** Bloquea el entrenamiento. |

### L-06 · Identidad del artefacto resuelta con información futura

| | |
|---|---|
| **Riesgo** | Usar `git log --follow` para afirmar que dos rutas son la misma entidad, cuando la detección del renombre se apoya en el estado del archivo **después** del movimiento. |
| **Causa** | `--follow` resuelve la cadena de renombres comparando contenidos; para saber que `A` pasó a ser `B` necesita observar `B`, que es posterior. |
| **Consecuencia** | Sutil pero real: en un escenario de predicción estricta, en el momento `t` el sistema no sabría que el archivo se va a renombrar después. Si la identidad se usa solo para **agregar historia pasada** (caso de este trabajo), el riesgo es aceptable; si se usara para construir etiquetas futuras, no lo sería. |
| **Mitigación** | Uso restringido: `--follow` se emplea exclusivamente para acumular métricas **anteriores** a `decision_time`. Todos los eventos de identidad registrados en `D3_ARTIFACT_IDENTITY.csv` son anteriores al corte (el más reciente es de 2020-01-24). |
| **Estado** | **MITIGADO** por restricción de uso, con la limitación documentada. |

### L-07 · Contaminación por commits de fusión (*merge*)

| | |
|---|---|
| **Riesgo** | Contar dos veces las líneas modificadas: una en el commit original y otra en el commit de fusión que las reintegra. |
| **Causa** | `git log --numstat` sobre un commit de merge puede reportar de nuevo líneas ya contabilizadas. |
| **Consecuencia** | `churn` inflado de forma no uniforme: los archivos que viven en ramas con muchas fusiones aparecen más volátiles que los que se modifican directamente en la rama principal. |
| **Mitigación** | Se añadió `--no-merges` al cálculo de `lines_added` / `lines_deleted` en `build_evolution_dataset.sh`. |
| **Estado** | **MITIGADO.** |

---

## Resumen

| ID | Riesgo | Estado |
|---|---|---|
| L-01 | Métricas sobre historial completo | MITIGADO |
| L-02 | Universo tomado de HEAD | MITIGADO (parcial: persiste *survivorship bias*) |
| L-03 | Eventos globales en métricas de recencia | MITIGADO (umbral no validado) |
| L-04 | Conteos de refactoring por barridos mecánicos | MITIGADO (marcado; criterio de uso abierto) |
| L-05 | Etiquetas con información futura | **ABIERTO** |
| L-06 | Identidad resuelta con información futura | MITIGADO por restricción de uso |
| L-07 | Doble conteo por merges | MITIGADO |

**Conclusión operativa:** con L-05 abierto, el punto 10 del checklist G1A no
puede declararse cerrado, y por tanto **no se autoriza entrenamiento**. Las
mitigaciones de L-01 a L-04, L-06 y L-07 están implementadas en scripts
ejecutables y son verificables sobre los datos entregados.
