# D1 — Estado del arte y gap científico

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Gate:** G1A · **Versión:** v1.0 — 2026-09-30
**Estado del entregable:** PARCIAL — 2 artículos primarios leídos íntegramente,
3 identificados y pendientes de lectura completa.

---

## Advertencia de honestidad metodológica

Esta matriz distingue explícitamente entre artículos **leídos íntegramente**
(método, resultados y limitaciones verificados en el texto) y artículos
**identificados pero no leídos a fondo**. Los segundos NO se usan para
sustentar el gap; se listan porque delimitan el trabajo pendiente. Marcar como
revisado un artículo que solo se conoce por su resumen invalidaría la matriz.

---

## 1. Matriz del estado del arte

### 1.1 Artículos leídos íntegramente

| Campo | **A1** | **A2** |
|---|---|---|
| **Referencia** | Iammarino, M., Zampetti, F., Aversano, L., & Di Penta, M. (2021). *An empirical study on the co-occurrence between refactoring actions and self-admitted technical debt removal*. Journal of Systems and Software. | Robredo, M., Saarimäki, N., Esposito, M., Taibi, D., Peñaloza, R., & Lenarduzzi, V. (2025). *Evaluating Time-Dependent Methods and Seasonal Effects in Code Technical Debt Prediction*. |
| **DOI / ID** | 10.5281/zenodo.4628255 | arXiv:2408.08095v2 |
| **Problema** | ¿Los refactorings contribuyen a eliminar deuda técnica auto-admitida (SATD), o ambas actividades solo co-ocurren dentro de una mejora general de calidad? | ¿Los métodos de series temporales capturan mejor la evolución de la deuda técnica de código que los modelos de ML tradicionales, que ignoran la dependencia temporal? |
| **Corpus** | 4 proyectos Java OSS: Apache Camel, Gerrit Review, Apache Log4j, Apache Tomcat. 1,942,163 commits en 72 ramas; 2,729 instancias SATD; 834 commits de eliminación de SATD. | 31 proyectos Java de la Apache Software Foundation; análisis completado sobre **14** por problemas de convergencia del ajuste de los modelos TSA. |
| **Temporalidad** | Longitudinal: recorre el historial completo de commits de cada proyecto. | Longitudinal con serialización explícita: intervalos **quincenales** y **mensuales**; entre ~10 y 200+ observaciones por proyecto. |
| **Variables** | Acciones de refactoring (tipo y co-ocurrencia), eliminaciones de SATD, métricas estructurales (CBO, LOC, DIT, LCOM), solapamiento entre código refactorizado y afectado por SATD. | Dependiente: índice **SQALE** (minutos de remediación). Independientes: 205 reglas de code smell reducidas a 15 por selección de características. |
| **Herramienta / método** | **RefactoringMiner (RMiner)** (~98% precisión, ~87% recall) + herramienta `ck` para métricas. Test exacto de Fisher, regresión logística GLM de efectos mixtos. | 11 modelos: ARIMAX, SARIMAX, ARIMA+LM, SARIMA+LM, MLR, SGD, Lasso, Ridge, SVM, XGB, Random Forest. Validación *Walk-Forward* 80/20. Encuesta a 23 profesionales. |
| **Resultados** | Los refactorings tienen de 3 a 6 veces más probabilidad de co-ocurrir con eliminaciones de SATD que con otros commits; pero solo en 21% de los casos el comentario de SATD se refiere a mantenibilidad/legibilidad, y solo ~8% de los casos inspeccionados atienden directamente SATD de mantenibilidad. ~22% de refactorings son consecuencia de la eliminación (*floss refactoring*). | ARIMAX superior con datos quincenales (MAPE 0.97%). El ajuste estacional mejora modestamente. Pronóstico a largo plazo aceptable (SARIMAX 1.08% a 6 meses, 4.19% a 36 meses). Los profesionales prefieren horizontes de 2–4 semanas. |
| **Limitaciones declaradas** | Solo 4 proyectos de un dataset SATD curado; no generaliza. No establece causalidad. Posible imprecisión en la medición de eliminaciones de SATD. Acuerdo inter-evaluador moderado (kappa de Cohen 0.52). | Problemas de convergencia eliminaron 17 de 31 proyectos. Se interpolaron observaciones faltantes, introduciendo datos artificiales. Solo Java. Encuesta concentrada en Europa (87%), n=23. |
| **Relación con este proyecto** | Es el antecedente metodológico más cercano en el uso de RefactoringMiner sobre historial completo. **Crítico:** trabaja con conteos de refactorings sin reportar un filtrado explícito de commits masivos o mecánicos. Este trabajo muestra (§D4) que en `commons-collections` el 97.7% de los eventos detectados en la ventana analizada provienen de tres commits de convención mecánica. | Es el antecedente más cercano en el tratamiento formal de la temporalidad, y confirma que ignorar la dependencia temporal degrada los modelos. **Crítico:** serializa por ventanas de calendario (quincenal/mensual) sobre métricas agregadas de proyecto, no sobre la identidad de entidades individuales seguidas a través de renombres. |

### 1.2 Artículos identificados, pendientes de lectura completa

No se usan para sustentar el gap. Se listan como trabajo inmediato pendiente.

| Referencia | Por qué es relevante | Estado |
|---|---|---|
| Herzig, K., Just, S., & Zeller, A. — *The impact of tangled code changes on defect prediction models*. Empirical Software Engineering (2016). DOI: 10.1007/s10664-015-9376-6 | Es el trabajo de referencia sobre cómo los commits que mezclan propósitos sesgan los modelos construidos sobre ellos. Conecta directamente con el hallazgo central de este trabajo. | **No leído.** El servidor (Springer) rechazó el acceso durante esta sesión (HTTP 429). Pendiente de obtener vía biblioteca institucional. |
| Tsoukalas, D. et al. — trabajos sobre *technical debt forecasting* (Univ. de Macedonia). | Línea de predicción de deuda técnica citada en el entregable paralelo. | **No leído.** Identificado, pendiente de selección del artículo concreto. |
| Tsantalis, N. et al. — *RefactoringMiner 2.0* | Documentación de precisión/recall de la herramienta usada en D4. Necesario para declarar la validez de la detección. | **No leído.** Pendiente. |

---

## 2. Gap científico

Formato requerido: *Prior work → Limitation → Gap → Proposed contribution*.

### Prior work

- **CIMPS 2026 (baseline propio).** Midió deuda técnica de código en 8 proyectos
  Java de código abierto en un **único snapshot** por proyecto.
- **Iammarino et al. (2021).** Recorrió el historial completo de 4 proyectos con
  RefactoringMiner y relacionó refactorings con eliminación de SATD.
- **Robredo et al. (2025).** Serializó la deuda técnica (SQALE) en ventanas
  quincenales y mensuales sobre 14 proyectos Apache y comparó 11 modelos
  predictivos con validación *walk-forward*.

### Limitation

1. **CIMPS** no puede sustentar afirmaciones de evolución, acumulación,
   persistencia ni predicción: con un solo punto temporal no existe la variable
   tiempo.
2. **Iammarino et al.** opera sobre conteos de refactorings sin reportar un
   filtrado explícito de commits masivos o mecánicos. Si una fracción dominante
   de los eventos detectados proviene de barridos automáticos (convenciones de
   estilo, cambios de visibilidad, actualizaciones de licencia), el conteo mide
   política del proyecto, no actividad de diseño.
3. **Robredo et al.** trata la temporalidad a nivel de **proyecto agregado** y
   por ventanas de calendario. No aborda la **identidad de la entidad
   individual** a través de renombres, movimientos y migraciones de paquete, ni
   distingue entre actividad real sobre un archivo y eventos que arrastran a
   todos los archivos vivos a la vez.
4. Ninguno de los tres reporta un **ledger explícito de fuga temporal** ni una
   regla verificable de tipo `feature_timestamp <= decision_time` aplicada
   archivo por archivo.

### Gap

> Falta un procedimiento **reproducible y verificable** que, antes de cualquier
> modelado, establezca simultáneamente: (a) la identidad longitudinal de cada
> entidad a través de renombres y migraciones; (b) la limpieza temporal de cada
> métrica respecto a un momento de decisión explícito; y (c) la separación entre
> actividad individual real y **eventos globales de proyecto** que contaminan de
> forma sistemática tanto las métricas de recencia como los conteos de
> refactorings.
>
> Sin ese procedimiento, cualquier estudio longitudinal de deuda técnica corre
> el riesgo de modelar ruido de proceso (políticas de formateo, migraciones,
> convenciones de estilo) creyendo que modela evolución de calidad.

### Proposed contribution

Este trabajo aporta, con evidencia ejecutada sobre `commons-collections`:

1. **Un procedimiento de identidad longitudinal** con evidencia doble (código de
   similitud del renombre + mensaje de commit ligado al ticket del tracker), y
   la constatación de que la similitud **no siempre es 100%**: en este piloto la
   migración de paquete `collections → collections4` produjo renombres de 95–99%
   de similitud, no R100 (§D3.1). La evidencia de identidad es más débil de lo
   que sugiere el caso de `commons-lang`.
2. **Un dataset con regla temporal explícita y verificable**, generado por script
   reproducible, donde todas las métricas se calculan con
   `--before=decision_time` (§D3.2).
3. **La cuantificación del sesgo por eventos globales** y una regla de filtrado
   operativa (umbral de commit masivo). En este piloto: 84 commits masivos
   identificados; **26 de 30 archivos** con la métrica de recencia contaminada,
   con un sesgo máximo de **2,509 días**; y **97.73% de los refactorings**
   detectados concentrados en tres commits de convención mecánica (§D4).
4. **La constatación de que el fenómeno es sistémico y no local**: el mismo
   commit de barrido de licencia (2025-05-20) aparece en `commons-lang`
   (511 archivos, entregable paralelo) y en `commons-collections` (711
   archivos, este trabajo), lo que sugiere un patrón de la Apache Software
   Foundation que afecta al corpus completo.

### Por qué no es una repetición de CIMPS

CIMPS respondió *"¿cuánta deuda técnica hay en estos proyectos?"* sobre una
foto. Este trabajo responde *"¿bajo qué condiciones puede esa medición
extenderse en el tiempo sin que el resultado sea un artefacto del proceso de
desarrollo?"*. El objeto de estudio no es la deuda, sino la **validez del
sustrato de datos**. El resultado no es una cifra de deuda, sino un conjunto de
condiciones y filtros necesarios, cuantificados.

---

## 3. Trabajo pendiente de D1

1. Obtener y fichar Herzig, Just & Zeller (2016) vía biblioteca institucional.
2. Seleccionar y fichar un artículo concreto de la línea Tsoukalas.
3. Fichar la documentación de precisión/recall de RefactoringMiner 2.0/3.x.
4. Ampliar la matriz a un mínimo de 8 artículos primarios.
