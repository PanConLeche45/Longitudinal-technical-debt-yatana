# H-04 — `git log --follow` construye linajes falsos (afecta E2 en ambos pilotos)

**Fecha:** 2026-10-05 · **Para revisar con:** Willian · **Origen:** cruce automático E2 × E3
(`check_e2_minus_e3` en `INTEGRATED_E1_E2_E3_*.csv`)

## 1. Cómo apareció
E2 cuenta commits con `git log --follow` (incluye commits masivos). E3 cuenta con `git log -M` por
commit y separa los masivos. Si ambos describen la misma historia, debe cumplirse:

```
prior_commits (E2)  =  n_commits_e3  +  n_commits_excluded_large        → diferencia = 0
```

Se cumple **exactamente** en 16 de 30 archivos de commons-collections y en 19 de 30 de commons-lang (diferencias de 1–5 en otros 4; ver tabla).
Donde no, listar las rutas que recorre `--follow` muestra el porqué:

```bash
git log --follow --name-only --format= <decision_commit> -- <ruta> | sed 's#.*/##' | sort -u
```

## 2. commons-collections (mi E2)

| ID | Archivo | E2 | E3 + masivos | Dif. | Rutas extra que recorre `--follow` |
|---|---|---|---|---|---|
| C007 | multiset/AbstractMapMultiSet | 97 | 26 + 9 | **62** | AbstractBag, AbstractMapBag, DefaultMapBag |
| C012 | Get | 51 | 13 + 9 | **29** | **TestAll, TestFastHashMap, TestLRUMap**, HashBag, BoundedCollection |
| C005 | map/AbstractReferenceMap | 109 | 56 + 26 | 27 | ReferenceMap (extracción real en 3.1, discutible) |
| C010 | set/ListOrderedSet | 89 | 40 + 24 | 25 | **Closure, FixedSizeList, IntListIterator, CharListIteratorListIterator…** |
| C019 | iterators/AbstractMapIteratorDecorator | 51 | 12 + 22 | 17 | AbstractIteratorDecorator, AbstractListIteratorDecorator, ByteIteratorIterator… |
| C018 | functors/WhileClosure | 51 | 12 + 24 | 15 | AbstractMapEntry, DefaultMapEntry |
| C017 | functors/OrPredicate | 51 | 14 + 24 | 13 | AbstractKeyValue, AbstractPair, ConstantFactory, PriorityQueue… |
| C016 | functors/ConstantTransformer | 51 | 15 + 24 | 12 | AbstractKeyValue, AbstractPair, ConstantFactory, PriorityQueue, TransformerClosure |
| C013 · C008 · C006 | DualHashBidiMap · AbstractHashedMap · TreeBidiMap | | | 10 · 8 · 7 | Closure/SortedBidiMap · HashedMap · DoubleOrderedMap |
| C014 · C021 · C015 | PredicatedCollection · trie/package-info · ChainedTransformer | | | 5 · 3 · 1 | (menores; revisar) |

## 3. commons-lang (E2 de Willian)

| ID | Archivo | E2 | E3 + masivos | Dif. | Rutas extra |
|---|---|---|---|---|---|
| F010 | time/FastDatePrinter | 162 | 95 + 9 | **58** | FastDateFormat (extracción real, discutible) |
| F020 | function/ByteSupplier | 32 | 1 + 0 | **31** | FailableByteSupplier, FailableIntSupplier, **GenericParent (test), LICENSE** |
| F018 | function/IntToCharFunction | 32 | 2 + 1 | 29 | FailableBooleanSupplier, ToBooleanBiFunction, **GenericParent, LICENSE** |
| F019 | function/FailableShortSupplier | 32 | 3 + 2 | 27 | FailableIntSupplier, **GenericParent, LICENSE** |
| F011 | time/TimeZones | 33 | 8 + 2 | 23 | **GenericParent, DummyEnum, StaticContainerChild, Typed, LICENSE** |
| F004 · F014 · F015 · F017 | NumberUtils · MutableTriple · OctalUnescaper · Mutable | | | 10 · 10 · 10 · 7 | **`lang/NumberUtils` (otra clase homónima del paquete raíz: exactamente 10 commits)** · MutablePair · AggregateTranslator · DummyEnum/LICENSE |
| F016 · F028 | NumericEntityEscaper · AbstractFutureProxy | | | 3 · 1 | UnicodeEscaper · UncheckedFutureImpl |

## 4. Por qué pasa
`--follow` sigue **un solo archivo** y, en cada commit, busca el archivo borrado/creado **más
parecido** por contenido. En archivos pequeños y casi idénticos (interfaces `Failable*`, functors,
decoradores, clases que sólo tienen la cabecera de licencia) se "salta" a otro archivo — a veces a un
test o al propio `LICENSE`. La documentación de Git lo describe como heurístico.

## 5. Por qué importa
1. Infla `prior_commits`, `churn` y `distinct_contributors` de ~8 de 30 archivos en cada piloto.
2. **El estrato MEDIO de ambos datasets** (todos ≈ 51 en collections, ≈ 32–33 en lang) **está
   sobrerrepresentado por archivos afectados**: la muestra estratificada se eligió con valores inflados.
3. La verificación manual de G1A (ChainedTransformer = 51) "coincidió" porque usó el **mismo**
   `--follow`: no era una verificación independiente. (ChainedTransformer, por suerte, es de los sanos:
   dif. = 1.)
4. Toca los puntos 6 (identidad) y 8 (dataset) de G1A que marqué como COMPLETADOS.

## 6. Propuesta (decidir juntos; no eliminar archivos)
- En la auditoría de 10 registros de Willian, incluir F011, F018 y F020; en mi revisión, C007, C010 y C012.
- Recalcular E2 con `-M` por commit (como el extractor E3) o restringir `--follow` a rutas bajo
  `src/main/java` y similitud ≥ 90 %; documentar ambos valores, no sustituir en silencio.
- Registrar en ambas bitácoras; conservar los archivos y la columna `check_e2_minus_e3`.
