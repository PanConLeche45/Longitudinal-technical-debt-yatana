# P1 — Práctica manual de co-change

**Regla de selección (fijada antes de mirar):** los **10 commits más recientes**, no-merge, **ancestros
del decision commit**, que tocan entre 2 y 50 archivos `.java` de `src/main/java` (1 archivo no tiene
pareja; > 50 es commit masivo, mismo umbral que D-04).

## Comandos (Git Bash)
```bash
cd repos/commons-collections
git log --no-merges --name-only --format='@@%h|%cs|%s' e96986a5c -- src/main/java > ../p1_cc.txt
git show --name-only --format='%h %cs %s' <SHA> -- src/main/java        # archivos que cambiaron juntos
git merge-base --is-ancestor <SHA> e96986a5c && echo "OK: es pasado"    # prueba de temporalidad
```

> La tabla la lleno yo en mi terminal; lo que sigue es la **clave de verificación**.

## A. commons-collections (mi piloto) — decision commit `e96986a5c` (2025-11-12)
Prefijo omitido: `src/main/java/org/apache/commons/collections4/`

| # | Commit | Fecha | Mensaje | Nº | Archivos que cambiaron juntos | ¿Ancestro? |
|---|---|---|---|---|---|---|
| 1 | f4d2b39ad | 2025-11-08 | Javadoc | 4 | CollectionUtils, MapUtils, MultiMap, map/MultiValueMap | ✔ |
| 2 | 8f97f5776 | 2025-10-07 | Javadoc | 2 | ArrayStack, list/AbstractLinkedList | ✔ |
| 3 | 845c0e540 | 2025-08-19 | [COLLECTIONS-722] deeply nested chainedIterator performance… | 2 | iterators/IteratorChain, iterators/UnmodifiableIterator | ✔ |
| 4 | 79ca330e5 | 2025-08-05 | Use Javadoc instead of HTML tag | 2 | iterators/ExtendedIterator, map/ConcurrentReferenceHashMap | ✔ |
| 5 | a4b0e7c79 | 2025-05-10 | Remove deprecation annotation of …Factory | 3 | Factory, Predicate, Transformer | ✔ |
| 6 | 643039944 | 2025-04-19 | Javadoc | 29 | Bag, CollectionUtils, EnumerationUtils, FluentIterable, IterableUtils, MultiSet, SetUtils, … | ✔ |
| 7 | cd8af14ad | 2025-04-19 | Javadoc | 2 | list/AbstractLinkedListJava21, properties/SortedProperties | ✔ |
| 8 | 022030c55 | 2025-04-18 | Javadoc | 8 | SetUtils, functors/AbstractPredicate, …, map/ConcurrentReferenceHashMap, multiset/AbstractMultiSet, … | ✔ |
| 9 | b4e7ff365 | 2025-03-23 | Javadoc | 2 | map/LRUMap, trie/AbstractPatriciaTrie | ✔ |
| 10 | 9ead80ce2 | 2025-03-05 | Javadoc | 2 | ArrayUtils, CollectionUtils | ✔ |

**Pares repetidos (≥ 2):** SetUtils ↔ map/ConcurrentReferenceHashMap ↔ multiset/AbstractMultiSet
(2 veces cada par) — **los tres vienen de commits de Javadoc** (#6 y #8).

**Pares con sentido de diseño (aparecen 1 vez):** IteratorChain ↔ UnmodifiableIterator (ticket
COLLECTIONS-722) y Factory ↔ Predicate ↔ Transformer (decisión de API sobre deprecaciones).

## B. commons-lang (piloto de Willian) — decision commit `598dfc163` (3.20.0, 2025-11-12)
Prefijo omitido: `src/main/java/org/apache/commons/lang3/`

| # | Commit | Fecha | Mensaje | Nº | Archivos |
|---|---|---|---|---|---|
| 1 | c9ff6aa44 | 2025-11-07 | [LANG-1786] Map deprecated TimeZone short IDs… | 3 | time/FastDateParser, FastTimeZone, TimeZones |
| 2 | b77073c2a | 2025-10-26 | Javadoc | 3 | StringUtils, time/FastDateFormat, time/FastDatePrinter |
| 3 | f24c027ff | 2025-10-16 | Add JavaVersion.JAVA_26 | 2 | JavaVersion, SystemUtils |
| 4 | f2f204d94 | 2025-10-08 | Javadoc | 4 | tuple/ImmutablePair, ImmutableTriple, MutablePair, MutableTriple |
| 5 | 7a55ebb45 | 2025-10-08 | Simplify Javadoc | 5 | tuple/ImmutablePair, ImmutableTriple, MutableTriple, Pair, Triple |
| 6 | ae061818e | 2025-10-07 | Javadoc | 4 | RegExUtils, StringEscapeUtils, StringUtils, time/FastDatePrinter |
| 7 | 70fa70691 | 2025-10-02 | Add JavaVersion.JAVA_25 | 2 | JavaVersion, SystemUtils |
| 8 | 28552e877 | 2025-09-29 | Javadoc | 2 | ObjectUtils, function/Failable |
| 9 | 4916a1f9b | 2025-09-25 | Javadoc | 37 | ArrayUtils, JavaVersion, ObjectUtils, Range, RegExUtils, StringUtils, SystemUtils, … |
| 10 | 1a49a5e33 | 2025-09-19 | Javadoc | 7 | mutable/Mutable, MutableByte, MutableDouble, MutableFloat, MutableInt, MutableLong, MutableShort |

**Pares repetidos:** JavaVersion ↔ SystemUtils (3 veces: **acoplamiento lógico real**, cada versión
nueva de Java obliga a tocar ambos); el resto (StringUtils ↔ FastDatePrinter, familia tuple/*,
RegExUtils ↔ StringEscapeUtils ↔ StringUtils) proviene de Javadoc.

## Lo que aprendí
1. **Co-change ≠ acoplamiento de diseño.** 8/10 (collections) y 6/10 (lang) commits son cosméticos. En
   collections, todos los pares repetidos son cosméticos. → hallazgo H-05.
2. Un commit de 29 o 37 archivos (por debajo del umbral) genera 406 o 666 pares de una sola vez.
3. Los 20 commits son ancestros de su decision commit y tienen fecha anterior: **no se usó futuro**.
4. Para la demostración: COLLECTIONS-722 (collections) y JavaVersion ↔ SystemUtils (lang) son los
   casos con sentido de diseño.
