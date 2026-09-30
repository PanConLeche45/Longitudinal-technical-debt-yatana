# D3 — Análisis: identidad de artefactos y dataset de evolución

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Piloto:** `apache/commons-collections` · **decision_time:** 2025-11-12
**Gate:** G1A · 2026-09-30

---

## 1. Qué se quería averiguar

Dos preguntas operativas (SQ1 y SQ2 del objetivo de investigación):

- ¿Puede seguirse el mismo archivo a través del historial, con evidencia, cuando
  cambia de ruta o de paquete?
- ¿Pueden calcularse métricas de un archivo en un momento dado usando
  exclusivamente información anterior a ese momento?

---

## 2. Identidad longitudinal de artefactos

### 2.1 Método

Se siguieron **10 archivos** con `git log --follow --name-status --diff-filter=AR`,
que registra nacimientos (`A`) y renombres (`R###`, donde `###` es el porcentaje
de similitud detectado por Git). Selección deliberadamente contrastada: 5
archivos nacidos **antes** de 2010 y 5 **después**, para probar si la fecha de
nacimiento predice la complejidad de identidad.

Resultado: **21 eventos de identidad** registrados en `D3_ARTIFACT_IDENTITY.csv`.

### 2.2 Los dos eventos de migración del proyecto

Todos los renombres detectados se concentran en **dos commits**, y ninguno de
los dos es actividad de los archivos: son reorganizaciones del proyecto entero.

| Commit | Fecha | Mensaje | Archivos tocados |
|---|---|---|---|
| `8ffb78ec5` | 2012-03-08 | *MOve to standard Maven layout* | **454** |
| `a8d1066b5` | 2013-04-17 | *[COLLECTIONS-452] Change package to o.a.c.collections4.* | **714** |

### 2.3 Caso demostrativo — `CollectionUtils.java`

```
src/java/org/apache/commons/collections/CollectionUtils.java
        │   nace 2001-04-24  (256420016)  "adding CollectionUtils and tests for it"
        │
        │   8ffb78ec5  (2012-03-08)  "MOve to standard Maven layout"
        │   similitud R100  →  MOVE EXACTO
        ▼
src/main/java/org/apache/commons/collections/CollectionUtils.java
        │
        │   a8d1066b5  (2013-04-17)  "[COLLECTIONS-452] Change package to o.a.c.collections4."
        │   similitud R099  →  RENAME CON CAMBIOS
        ▼
src/main/java/org/apache/commons/collections4/CollectionUtils.java   (ubicación actual)
```

La identidad se sostiene en **dos evidencias independientes**: el código de
similitud que Git calculó, y el mensaje de commit, que además cita el ticket
**COLLECTIONS-452** del tracker JIRA. Cadena completa:
`archivo → commit → movimiento → ticket JIRA`.

### 2.4 Hallazgo 1 — La similitud no siempre es 100%, y eso importa

| Evento | Similitud observada |
|---|---|
| `8ffb78ec5` — cambio de layout (`src/java` → `src/main/java`) | **R100** en los 5 archivos afectados |
| `a8d1066b5` — cambio de paquete (`collections` → `collections4`) | **R095 – R099**, nunca R100 |

**Explicación:** el cambio de layout movió los archivos sin tocar su contenido,
de ahí el 100% de similitud. El cambio de paquete, en cambio, modificó la
declaración `package` y los `import` dentro de cada archivo **en el mismo
commit** que lo movió, por lo que el contenido ya no era idéntico.

**Por qué importa:** en el entregable paralelo sobre `commons-lang`, ambas
migraciones aparecen como R100, porque ese proyecto separó el renombre de
directorio del cambio de declaración en commits distintos. La conclusión "la
identidad se establece con R100" **no es generalizable al corpus**: depende de
cómo cada proyecto ejecutó su migración. Un pipeline que exigiera R100 como
criterio de identidad perdería los 5 archivos antiguos de este piloto.

**Implicación operativa:** el criterio de identidad debe aceptar renombres por
debajo de 100% y apoyarse en la evidencia secundaria (mensaje de commit, ticket)
para los casos dudosos.

### 2.5 Hallazgo 2 — La fecha de nacimiento predice la complejidad de identidad

| Grupo | Archivos | Eventos de renombre |
|---|---|---|
| Nacidos antes de 2012-03-08 | `CollectionUtils`, `ListUtils`, `MapUtils`, `SetUtils`, `IteratorUtils` | **2 cada uno** (layout + paquete) |
| Nacido entre ambas migraciones (2012-08-24) | `PassiveExpiringMap` | **1** (solo paquete) |
| Nacidos después de 2013-04-17 | `AbstractPatriciaTrie`, `AbstractMultiValuedMap`, `IterableUtils`, `BloomFilter` | **0** |

`PassiveExpiringMap` funciona como experimento natural: nació **entre** las dos
migraciones y, en consecuencia, vivió exactamente una. El patrón no es
casualidad: los renombres no son actividad individual de los archivos, sino
**eventos globales que arrastraron a todos los archivos vivos en ese momento**.

### 2.6 Respuesta a SQ1

**Sí, con salvedad.** Los 10 archivos fueron rastreables sin ambigüedad: cero
casos en los que la cadena de identidad se rompiera o se bifurcara. Pero la
evidencia es **más débil de lo que sugiere el caso `commons-lang`**: cinco de
los diez apoyan su identidad en renombres de 95–99%, no en coincidencia exacta.

---

## 3. Dataset de evolución

### 3.1 Construcción

| Elemento | Valor |
|---|---|
| Universo | 359 archivos `.java` vivos en `e96986a5c` con historial previo al corte |
| Muestra | 30 archivos, estratificada: 10 ALTO (hotspots) / 10 MEDIO / 10 BAJO |
| Métricas | `prior_commits`, `lines_added`, `lines_deleted`, `churn`, `days_since_last_change`, `distinct_contributors` |
| Regla temporal | `--before="2025-11-12"` en **todas** las invocaciones a `git log` |
| Generador | `scripts/build_evolution_dataset.sh` |

### 3.2 Hallazgo 3 — La estratificación separa tres regímenes reales

| Estrato | `prior_commits` (rango) | `churn` (rango) |
|---|---|---|
| ALTO | 89 – 225 | 2,388 – 11,378 |
| MEDIO | 51 – 52 | 670 – 2,463 |
| BAJO | 2 – 11 | 62 – 439 |

Entre el archivo más activo (`CollectionUtils`, 225 commits) y el menos activo
(`IteratorOperations`, 2 commits) hay **dos órdenes de magnitud**. El estrato
MEDIO está comprimido (51–52 commits) porque la distribución de actividad tiene
una cola larga: la mayoría de los archivos se concentra en valores bajos.

### 3.3 Hallazgo 4 — Concentración extrema del churn

Los 3 archivos con más churn (`CollectionUtils` 11,378; `TreeBidiMap` 10,893;
`MapUtils` 9,898) suman **32,169** de los **77,251** de churn total de la
muestra: el **41.6%** en el 10% de los archivos. Los 5 primeros concentran el
**57.2%**.

### 3.4 Respuesta a SQ2

**Sí.** La regla `feature_timestamp <= decision_time` está implementada,
documentada y es verificable línea por línea en el script. La verificación
manual de §4 confirma que los valores son correctos.

---

## 4. Verificación manual (criterio de aceptación)

Se comprobaron tres archivos, uno por estrato, contra el historial de Git:

| Archivo | Estrato | `prior_commits` | `distinct_contributors` | ¿Coincide? |
|---|---|---|---|---|
| `CollectionUtils` | ALTO | 225 | 22 | Sí |
| `ChainedTransformer` | MEDIO | 51 | 12 | Sí |
| `IteratorOperations` | BAJO | 2 | 2 | Sí |

Comandos de comprobación en `PROVENANCE_INTEGRIDAD.md` §5.

---

## 5. Hallazgo 5 — La contaminación por eventos globales (el hallazgo central)

Al revisar `days_since_last_change` apareció una anomalía: **25 de 30 archivos**
tenían exactamente la misma fecha de último cambio, **2025-05-20**.

La causa es el commit `8ee475dcc`, *"Update Apache License URL to HTTPS"*, que
modificó **711 archivos** cambiando **una línea** en cada uno.

### 5.1 Magnitud de la contaminación

Se recalculó la métrica ignorando los **84 commits masivos** (≥ 50 archivos)
identificados antes del corte. Resultado: **26 de 30 archivos contaminados**.

| Archivo | Recencia reportada | Último cambio real | Sesgo |
|---|---|---|---|
| `SynchronizedQueue` | 176 días (2025-05-20) | 2018-07-07 | **2,509 días** |
| `trie/package-info` | 176 días | 2024-01-27 | 479 días |
| `map/package-info` | 176 días | 2024-01-27 | 479 días |
| `PredicatedCollection` | 176 días | 2024-07-10 | 314 días |
| `ReplacementsHandler` | 176 días | 2024-07-12 | 312 días |

`SynchronizedQueue` es el caso límite: un archivo dormido **casi siete años**
que la métrica ingenua presenta como modificado hace menos de seis meses.

### 5.2 Los commits masivos del proyecto

| Commit | Fecha | Archivos | Mensaje |
|---|---|---|---|
| `a8d1066b5` | 2013-04-17 | 714 | Change package to o.a.c.collections4 |
| `8ee475dcc` | 2025-05-20 | 711 | Update Apache License URL to HTTPS |
| `13dcac086` | 2003-08-31 | 574 | Unify spelling of acknowedgement in licence |
| `29d2e9396` | 2017-09-12 | 512 | Remove @version tag |
| `01bd494f0` | 2024-01-20 | 492 | Sort members |
| `8ffb78ec5` | 2012-03-08 | 454 | MOve to standard Maven layout |

**Consistencia interna:** los dos commits que la §2 identificó como eventos de
migración (`a8d1066b5`, `8ffb78ec5`) aparecen aquí entre los mayores commits
masivos. El análisis de identidad y el de recencia convergen en los mismos
eventos, por caminos independientes.

### 5.3 Convergencia con el entregable paralelo

El commit de licencia del **2025-05-20** aparece en los dos pilotos:

| Piloto | Archivos tocados |
|---|---|
| `commons-lang` (W. Tehuatle) | 511 |
| `commons-collections` (este trabajo) | 711 |

Es el mismo barrido de la Apache Software Foundation aplicado a componentes
distintos. **El fenómeno no es una rareza de un proyecto: es sistémico del
corpus.** Cualquier estudio longitudinal sobre estos ocho proyectos debe
filtrarlo explícitamente.

---

## 6. Amenazas a la validez

1. **Umbral arbitrario.** El corte de 50 archivos para declarar un commit
   "masivo" es una decisión de diseño sin validación empírica. Un análisis de
   sensibilidad al umbral está pendiente.
2. ***Survivorship bias*.** El universo se toma del árbol vigente en
   `decision_time`, por lo que excluye archivos borrados antes de esa fecha —
   precisamente los candidatos a deuda terminal.
3. **Un solo piloto.** Los hallazgos 1, 2 y 5 se verificaron en
   `commons-collections`. La convergencia con `commons-lang` en el hallazgo 5 es
   indicio de generalidad, no prueba.
4. **Muestra pequeña.** 30 archivos de un universo de 359 (8.4%). La
   estratificación cubre los tres regímenes, pero no soporta inferencia
   estadística.
5. **Churn y merges.** Se aplicó `--no-merges` para evitar doble conteo, pero no
   se verificó manualmente el efecto de esa decisión sobre los valores.
