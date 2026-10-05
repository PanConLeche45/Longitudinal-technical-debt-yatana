# Medidas candidatas E3 (máximo dos) — nivel archivo

Ambas salen de la **misma tabla de pares** del extractor: commits ancestros del decision commit,
no-merge, con ≤ 50 archivos de producción. Parámetros fijados **antes** de ver resultados.

**Notación** (archivo *f*, momento *t*):
- `n_t(f)` = commits elegibles hasta *t* que tocan *f* (`n_commits_e3`)
- `cc_t(f,g)` = commits elegibles hasta *t* que tocan *f* **y** *g* (`cochange_count`)

---

## M1 — Grado de co-change (`ccd_k2`)

| | |
|---|---|
| **Fórmula** | `M1_t(f) = | { g ≠ f : cc_t(f,g) ≥ 2 } |` |
| **Qué representa** | **Anchura** del acoplamiento lógico: con cuántos archivos distintos cambia *f* de forma repetida. Equivale a NOCC(f, n = 2) de D'Ambros, Lanza & Robbes (2009). Alto = cambiar *f* tiende a arrastrar a muchos otros (*shotgun surgery*). |

## M2 — Confianza máxima de acoplamiento (`max_conf_k2`)

| | |
|---|---|
| **Fórmula** | `M2_t(f) = max_{g : cc_t(f,g) ≥ 2} cc_t(f,g) / n_t(f)` (0 si ningún par llega a 2) |
| **Qué representa** | **Fuerza** de la dependencia más intensa: "cuando *f* cambia, ¿en qué proporción cambia también su socio principal?". Es la *confidence* de la regla f ⇒ g (Zimmermann et al., 2005). Normalizada por la actividad de *f*. |

---

## Ejemplo manual 1 — C028 `queue/SynchronizedQueue.java` (commons-collections, t = 2025-11-12)

```bash
git log --no-merges --format='%h %cs %s' e96986a5c -- src/main/java/org/apache/commons/collections4/queue/SynchronizedQueue.java
git show --name-only --format= <SHA> -- src/main/java | grep -c '\.java$'
```

| Commit | Fecha | Mensaje | Arch. prod. | ¿Elegible? | Otros archivos |
|---|---|---|---|---|---|
| 8ee475dcc | 2025-05-20 | Update Apache License URL to HTTPS | 359 | **no** (masivo) | — |
| 3a5c5c283 | 2022-11-06 | (chore) Fix minor typos | 57 | **no** (masivo) | — |
| 1e0646ee8 | 2022-05-31 | Remove noisy inline comments | 28 | sí | MapUtils, MultiMapUtils, PredicateUtils, SetUniqueList, AbstractMultiValuedMapDecorator, ListOrderedSet, + 21 más |
| a6d53a764 | 2020-03-30 | Standardize on American English spelling of 'behavior' | 46 | sí | **QueueUtils**, MapUtils, MultiMapUtils, PredicateUtils, SetUniqueList, AbstractMultiValuedMapDecorator, ListOrderedSet, + 38 más |
| b0b5759d5 | 2019-05-10 | Close tags in class-level Javadoc | 181 | **no** (masivo) | — |
| 9f1dabed5 | 2018-07-07 | Remove redundant type arguments | 1 | sí | (ninguno) |
| c6dc370ab | 2018-01-02 | [COLLECTIONS-575] Synchronized queue wrapper in QueueUtils | 2 | sí | **QueueUtils** |

- `n(f) = 4` elegibles (+ 3 masivos excluidos = 7 = `prior_commits` de mi E2 ✔)
- Socios con `cc ≥ 2`: QueueUtils, MapUtils, MultiMapUtils, PredicateUtils, SetUniqueList,
  AbstractMultiValuedMapDecorator, ListOrderedSet → **M1 = 7**
- Máximo `cc` = 2 → **M2 = 2 / 4 = 0.50**

**Script** (`out/commons-collections/E3_COCHANGE_FEATURES_commons-collections_2025-11-12_mf50.csv`,
fila C028): `n_commits_e3 = 4, n_commits_excluded_large = 3, ccd_k2 = 7, max_conf_k2 = 0.5` → **coincide**.

**Lectura crítica:** de los 7 socios, **sólo QueueUtils** tiene relación de diseño (COLLECTIONS-575);
los otros 6 vienen de dos barridos cosméticos (comentarios y ortografía). Es el ejemplo más claro de
la limitación H-05.

## Ejemplo manual 2 — F026 `DoubleRange.java` (commons-lang, t = 2025-11-12)

| Commit | Fecha | Mensaje | ¿Elegible? | Otros archivos |
|---|---|---|---|---|
| d8f7c3843 | 2025-09-16 | Add DoubleRange.fit(double) | sí | (ninguno) |
| a82f4cb50 | 2025-05-20 | Update Apache License URL to HTTPS | **no** (254 arch.) | — |
| a1e911a93 | 2022-10-23 | Fix simple broken javadoc | sí | ClassUtils, IntegerRange, LongRange |
| 57ddce119 | 2022-10-17 | Add NumberRange, DoubleRange, IntegerRange, LongRange | sí | IntegerRange, LongRange, NumberRange, Range, time/DurationUtils |

`n = 3` → IntegerRange 2, LongRange 2, resto 1 → **M1 = 2**, **M2 = 2/3 = 0.667**. Script, fila F026:
igual. Aquí los dos socios **sí** son de diseño (familia de rangos creada junta).

---

## Limitaciones

| | M1 | M2 |
|---|---|---|
| Redundancia con E2 | **Alta**: ρ = 0.96 con `prior_commits` (collections), 0.87 (lang); se satura en hotspots (CollectionUtils = 198 de 358 posibles) | Baja: ρ = −0.13 (collections), 0.33 (lang) |
| Archivos con poca historia | Puede ser alto por 1–2 barridos (SynchronizedQueue) | **Inestable**: con n = 2–4 da saltos 0.5 / 0.67 / 1.0; ρ = −0.58 con LOC en collections |
| Co-change cosmético | Lo cuenta igual | Igual |
| Familias de clases hermanas | Infla (OrPredicate ↔ AndPredicate…) | Da valores altos "por convención" |
| Identidad | Depende de `-M` por commit | Igual |

Correlaciones **exploratorias** (n = 30 por piloto, un momento). No se cambia ninguna fórmula en este
sprint; las mejoras posibles (soporte mínimo para M2, filtrar commits de Javadoc, normalizar M1) quedan
como propuesta documentada para el siguiente.

## ¿Qué aporta respecto del historial individual (E2)?

E2 describe al archivo **aislado**: cuánto cambió, cuánto churn, cuántas personas, hace cuánto.
E3 describe su **vecindario de cambio**: con quién cambia y con qué fuerza.
- **M1** añade la idea de *dispersión del impacto*, pero en ambos pilotos casi replica `prior_commits`.
- **M2** sí es información nueva (no correlaciona con E2) y apunta a dependencias fuertes como
  OrPredicate → AndPredicate (0.86), WhileClosure → ForClosure (0.83) o ArrayListIterator →
  ObjectArrayListIterator (0.80); su debilidad es la inestabilidad con poca historia.
- Que M2 aporte o no **valor incremental** sobre E1 + E2 es justo lo que debe medir el experimento
  controlado del siguiente sprint, con separación temporal.
