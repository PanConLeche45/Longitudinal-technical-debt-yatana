# L1 — Ficha de lectura: Bochicchio et al. (2025)

**Referencia:** Bochicchio, M., Sas, D., Gilardi, A., & Arcelli Fontana, F. (2025). *An empirical study on
architectural smells through a pipeline for continuous technical debt assessment.* Information and
Software Technology, 185, 107783. https://doi.org/10.1016/j.infsof.2025.107783 (acceso abierto, CC BY)

**Datos y replicación:** Zenodo 13827946 (dataset), 15051564 (paquete de replicación);
pipeline: github.com/Arcan-Tech/arcan-pipeline; co-change: github.com/darius-sas/ccan-rs

> Borrador de trabajo. Debo reescribirlo con mis palabras antes de entregarlo.

---

## 1. Objetivo y pregunta
Dos metas: (a) un **pipeline** en Apache Airflow que genera datasets de deuda arquitectónica de forma
continua con Arcan 2.9.0, y (b) un estudio empírico (GQM) con una sola RQ: *¿los pares de archivos
afectados por smells arquitectónicos tienen mayor probabilidad de co-cambiar que los pares limpios?*

## 2. Unidad de análisis
**El par de archivos** dentro de un proyecto (no el archivo individual). Cada par se clasifica en
*smelly* (ambos archivos con smell), *mixed* (uno) o *clean* (ninguno). El análisis estadístico se hace
**por proyecto** (118 muestreados, 112 con resultados completos: 60 Java / 58 C# muestreados).

## 3. Definición de co-change
- **Co-change:** número de veces que los dos archivos se modificaron "simultáneamente". Los commits se
  **agrupan por día de desarrollo**: dos archivos cambiados el mismo día cuentan como co-change aunque
  estén en commits distintos.
- **Co-change rate (variable dependiente):** co-changes del par ÷ número de versiones del proyecto;
  lo interpretan como la probabilidad observada de co-cambiar.
- Es su propia implementación (basada en Kouroshfar et al. 2015 y Sas et al. 2021), publicada como `ccan-rs`.

## 4. Fuente de datos
- Repositorios de GitHub; smells detectados por **Arcan 2.9.0** (Hublike, Cyclic, Unstable Dependency y God
  Component) sobre versiones muestreadas por el pipeline (releases o 1 commit/mes si no hay releases).
- Co-changes desde el historial de la **rama principal**, **todos** los commits incluido el inicial.
- Filtros: Java y C#, ≥ 100 estrellas, ≥ 10,000 LOC y > 10 archivos; se quitan repos demo/examen/test;
  muestreo aleatorio del 12.5 %. Smells con ATDI < 10 y archivos < 20 LOC se descartan.

## 5. Construcción temporal
- El pipeline sí es temporal en la **ingesta** (muestreo logarítmico de releases: `maxRel(n)=⌊6·log10(n+1)⌋`).
- Pero el estudio es **transversal**: la etiqueta *smell-affected* se toma del dataset de la última
  ejecución y el co-change se cuenta **sobre toda la historia de la rama principal**. El artículo no
  describe un corte que impida usar commits **posteriores** al momento en que se observó el smell, ni una
  separación pasado/futuro. → Para nosotros, esto es justo la amenaza de *temporal leakage* que el
  sprint prohíbe; no puedo reutilizar su conteo tal cual.

## 6. Variables
| Variable | Rol |
|---|---|
| Smell-Affected (0, 1 o 2 archivos del par con smell de ATDI > 10) | Independiente |
| Co-change rate | Dependiente |
| Nº de smells en cada archivo del par | Descriptiva |
| Categoría LOC del par (XS/S/M/L por cuartiles; el par toma la mayor) | Control de confusor |

## 7. Comparación realizada
Por proyecto, **Mann-Whitney U unilateral** en tres pruebas: A smelly > clean, B mixed > clean,
C smelly > mixed; α = 0.05; corrección **Benjamini–Hochberg (FDR)**; tamaño del efecto con **CLES** y
**correlación rango-biserial**. Se repite por categoría LOC.

## 8. Resultados
- H0 rechazada en 78.57 % (A), 63.39 % (B) y 71.43 % (C) de los 112 proyectos.
- Medianas del efecto: A CLES 0.666 / RBC 0.333; B 0.436 / −0.129; C 0.620 / 0.240.
- El efecto crece con el tamaño: en XS se rechaza A en 47.44 % de proyectos; en L, 76.47 %.
- Más marcado en Java; tasas de co-change globalmente bajas (la mayoría de pares nunca co-cambia).
- Pipeline: 34,983 versiones de 13,451 proyectos, ~1.2 mil millones de LOC, ~7 M instancias de smell,
  88 % de análisis exitosos (C# el peor por dependencias de Windows).

**Observación crítica mía:** en la prueba B la mediana del efecto es **negativa** (CLES < 0.5, RBC < 0)
aunque se rechaza H0 en el 63 % de proyectos; el texto lo resume como "mixed > clean", pero el efecto
típico apunta a lo contrario o a una diferencia muy débil. Vale la pena mencionarlo al profesor.

## 9. Amenazas a la validez
- **Del artículo:** constructo (todo depende de la detección de Arcan; herramientas de deuda no coinciden
  entre sí, Lefever et al. 2021); criterios de inclusión amplios; significancia estadística ≠ práctica
  (mitigado con tamaño del efecto); sólo 4 tipos de smell y sólo Java/C#; datos sesgados a versiones recientes.
- **Las que yo agrego para nuestro uso:** (1) sin corte temporal → posible fuga de información;
  (2) agrupar por día mezcla trabajo no relacionado de distintas personas; (3) no filtran commits
  masivos (licencias, formato), que inflan co-change; (4) el denominador "nº de versiones" depende del
  muestreo del pipeline, no de la actividad real; (5) es correlación, no causalidad.

## 10. Elementos reutilizables
1. Co-change como **proxy de acoplamiento lógico**, normalizado (rate) para comparar archivos.
2. Control explícito del **tamaño (LOC)** como confusor → en nuestro experimento, estratificar por LOC (E1).
3. Análisis **por proyecto** + efecto + FDR, en lugar de mezclar proyectos de tamaños distintos.
4. Arcan y su dataset en Zenodo como posible **fuente adicional de E1** (smells arquitectónicos).
5. El patrón de *pipeline* reproducible (ingesta → ejecución → generación) para nuestros scripts.

## 11. Lo que ya NO podemos reclamar como novedoso
- Que los smells/deuda arquitectónica se **asocian** con mayor co-change (este artículo y Sas et al. 2021).
- Que el co-change refleja acoplamiento lógico y mayor esfuerzo de mantenimiento.
- Un pipeline continuo/escalable para producir datasets de deuda técnica.
- Comparaciones por proyecto con Mann-Whitney + FDR + CLES/RBC, ni controlar por LOC.

**Lo que sí queda abierto (nuestro gap):** medir co-change **a nivel archivo × tiempo con corte estricto
en decision_time**, integrado con métricas estáticas (E1) e historia individual (E2) bajo la misma llave,
para evaluar después —con separación temporal— si E3 aporta información **incremental**.
