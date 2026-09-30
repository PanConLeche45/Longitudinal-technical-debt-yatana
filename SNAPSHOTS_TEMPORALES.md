# Snapshots temporales — regla de selección

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Piloto:** `apache/commons-collections` · **Gate:** G1A · 2026-09-30

---

## Estado honesto de este punto

> **El punto 7 del checklist exige múltiples puntos temporales T0, T1, … Tn.**
> Este entregable trabaja, hasta ahora, con **un único punto de decisión**
> (`decision_time = 2025-11-12`) y una **ventana de observación retrospectiva**.
> Eso NO satisface el requisito de multiplicidad temporal.
>
> El checklist lo advierte expresamente: *"Un único snapshot NO permite afirmar
> evolución, acumulación, persistencia o predicción de deuda técnica."*
> Este documento define la regla de selección de los snapshots y deja
> implementada la infraestructura, pero **la serie T0…Tn no está construida**.

---

## 1. Punto de decisión actual

| Elemento | Valor |
|---|---|
| `decision_time` | **2025-11-12** |
| Commit de referencia | `e96986a5c61e8fc9e7a180579ef793253161b7c3` (`e96986a5c`) |
| Fecha del commit | 2025-11-09 |
| Mensaje | *Fix issue links in the generated site's release history page* |
| Release vigente en esa fecha | `rel/commons-collections-4.5.0` (2025-04-22) |
| Justificación | Coincide con el `decision_time` del entregable paralelo sobre `commons-lang`, lo que hace comparables ambos resultados. Corresponde a la fecha del snapshot CIMPS. |

**Ventana de observación retrospectiva:** todo el historial anterior a
`decision_time` (desde 2001-04-14, primer commit del proyecto).

**Ventana de ejecución de RefactoringMiner:**
`rel/commons-collections-4.5.0` (`7f7fb0244`, 2025-04-22) → `e96986a5c`
(2025-11-09) = **119 commits**, de los cuales RefactoringMiner procesó 115.

---

## 2. Regla propuesta para la serie T0…Tn

La regla debe estar justificada, no ser arbitraria. Se proponen tres candidatas
y se argumenta la elección.

### Candidata A — Por release (elegida)

Un snapshot por cada tag `rel/commons-collections-*`.

**A favor:** los releases son puntos de estabilización decididos por el propio
proyecto; el código en un tag de release es, por construcción, código que el
equipo consideró entregable. Los intervalos son semánticamente comparables
entre proyectos del corpus (los 8 usan tags de release). Evita cortar en medio
de un refactor a medias.

**En contra:** los intervalos son irregulares en el tiempo. En
`commons-collections` hay 59 tags repartidos de forma muy desigual: entre
`4.4` (2019-07-08) y `4.5.0-M1` (2024-04-02) hay un hueco de **casi 5 años**.

### Candidata B — Por ventana de calendario fija

Un snapshot cada N meses (el trabajo de Robredo et al. 2025 usa ventanas
quincenales y mensuales).

**A favor:** intervalos regulares, directamente utilizables por modelos de
series temporales. **En contra:** ignora el ritmo real del proyecto; en el
hueco 2019–2024 produciría decenas de snapshots casi idénticos.

### Candidata C — Por número de commits

Un snapshot cada N commits.

**A favor:** normaliza por actividad. **En contra:** el eje deja de ser tiempo
calendario, lo que complica interpretar "acumulación" y "persistencia"; y con
84 commits masivos identificados en este piloto, N commits pueden representar
trabajo muy distinto según dónde caigan.

### Decisión

**Se adopta la Candidata A (por release), con dos correcciones:**

1. Se usan únicamente los tags `rel/*` (releases finales), excluyendo los
   `-RC*` y los hitos `-M*`, que no son entregables estables.
2. Cuando el intervalo entre dos releases consecutivos supere **24 meses**, se
   insertan snapshots intermedios anuales para no dejar huecos ciegos.

Esta regla está **definida y justificada**, pero **no ejecutada**: construir la
serie es el primer entregable del siguiente sprint.

---

## 3. Releases candidatos a snapshot (anteriores a `decision_time`)

Extraídos con:

```bash
git for-each-ref --sort=creatordate \
  --format='%(creatordate:short)  %(refname:short)  %(objectname:short)' \
  'refs/tags/rel/*'
```

| Snapshot | Tag | Fecha | Observación |
|---|---|---|---|
| T0 | `rel/commons-collections-4.5.0-M1` | 2024-04-02 | hito, excluido por la regla |
| T1 | `rel/commons-collections-4.5.0-M2` | 2024-06-18 | hito, excluido |
| T2 | `rel/commons-collections-4.5.0-M3` | 2024-12-18 | hito, excluido |
| **T3** | **`rel/commons-collections-4.5.0`** | **2025-04-22** | release final — **único release final dentro de la ventana reciente** |
| — | `rel/commons-collections-4.6.0` | 2026-08-10 | **posterior a `decision_time`**: excluido por regla temporal |

**Consecuencia inmediata y honesta:** con la regla adoptada, la ventana
2024–2025 aporta **un solo snapshot válido**. Para construir una serie
utilizable hay que retroceder a los releases de la serie 4.x y anteriores
(59 tags en total, el más antiguo de 2001). Esa extensión es trabajo del
siguiente sprint, no de este.

---

## 4. Qué falta para cerrar el punto 7

1. Ejecutar la regla sobre los 59 tags y producir el manifest con fecha y hash
   exacto de cada snapshot.
2. Calcular el dataset de evolución en cada Tn (el script ya lo permite: acepta
   `decision_time` y `commit_ref` como parámetros).
3. Verificar que la identidad de cada entidad se sostiene a través de todos los
   snapshots, incluyendo los que cruzan las dos migraciones globales de 2012 y
   2013 detectadas en `D3_ARTIFACT_IDENTITY.csv`.
