# Sprint 1 — Línea E3: hotspot / co-change

**Estudiante:** Yatana Roa Moreno — ZS23020600 · **Asesor:** Prof. Martín Mancilla Gómez
**Línea paralela:** William Tehuatle Sosa (E2, cierre longitudinal de G1A)
**Fecha:** 2026-10-05 · **Rama:** `sprint1-e3`

> Todos los resultados de esta carpeta son **piloto / exploratorios**, no confirmatorios.
> Mismas distinciones que en G1A: co-change ≠ deuda técnica · asociación ≠ causalidad ·
> script escrito ≠ resultado obtenido.

---

## 1. Pregunta de cierre de mi línea

> ¿Podemos representar de forma reproducible cuánto y con qué otros artefactos cambia un archivo
> utilizando únicamente su historia previa?

**Respuesta: Sí, con dos salvedades de constructo** (co-change cosmético y linaje de identidad, §7).
El extractor genera `project + artifact_id + decision_time + cochanged_file + cochange_count` para 30
archivos por piloto, en tres decision_time, con verificación temporal automática y sin modificar los
repositorios analizados.

## 2. Qué piloto y por qué dos (decisión D-08)

El correo pide trabajar "sobre el mismo proyecto piloto" e integrar con la llave
`project + artifact_id + decision_time`. Como el extractor es genérico, E3 se construyó en ambos:

| Piloto | E2 que se integra | Para qué |
|---|---|---|
| **commons-collections** (mi piloto de G1A) | mi E2 recalculado en el snapshot CIMPS (`data/E2_commons-collections_2025-04-19/`) | integración principal con evidencia propia |
| **commons-lang** (piloto de Willian) | su `D3_EVOLUTION_DATASET.csv` (copia en `data/`) | observación conjunta para la demostración |

⚠️ **Pendiente de confirmar con el profesor** cuál es el piloto oficial de la tabla integrada.

## 3. Qué significa observar un artefacto en un momento

Observar el archivo *f* en `decision_time` = tomar el árbol del **decision commit** y calcular toda
variable sólo con los commits **ancestros** de ese commit. Lo demás es futuro.

| Piloto | Momento | decision_time | Commit | Rol |
|---|---|---|---|---|
| commons-collections | T_a | 2024-12-15 | `a67032e0e` (rel 4.5.0-M3) | pasado |
| commons-collections | **T_CIMPS** | **2025-04-19** | **`7f7fb0244` (rel 4.5.0 = snapshot CIMPS)** | **observación principal** |
| commons-collections | T_c | 2025-11-12 | `e96986a5c` (el de G1A) | posterior; misma muestra observada después |
| commons-lang | T3 / T4 / **T5** | 2025-07-06 / 2025-09-19 / **2025-11-12** | `5b5948780` / `3d1eb7718` / **`598dfc163` (3.20.0 = snapshot CIMPS)** | snapshots de Willian |

**Decisión D-13 (2026-10-15):** el decision_time principal de commons-collections se alinea al
snapshot que analizó CIMPS (Tabla 1 del artículo: `rel/commons-collections-4.5.0`, `7f7fb0244abc`).
El decision_time de G1A (2025-11-12) venía del release 3.20.0 de commons-lang y **no** coincide con
el snapshot CIMPS de mi piloto (error E-07). La muestra de 30 archivos se **re-seleccionó con
información ≤ 4.5.0** (`data/E2_commons-collections_2025-04-19/`): 29 coinciden con G1A, sale
`trie/package-info` (C021) y entra `ConcurrentReferenceHashMap` (C031). Los `artifact_id` son
estables por ruta (`data/ARTIFACTS_commons-collections.csv`).

Nota: estos momentos **no** cierran el punto 7 de G1A (serie T0…Tn de E2).

## 4. Reproducción

```bash
# desde la raíz del repositorio (Git Bash)
bash sprint1_E3/scripts/run_e3.sh
```
Clona los dos repositorios en `repos/` si no existen, corre el extractor en los 3 momentos de cada
piloto (+ sensibilidad del umbral), integra E1+E2+E3 y ejecuta `check_temporal.py`.

| Script | Función |
|---|---|
| `extract_cochange.py` | Extractor E3 (pares + medidas por archivo + commits usados + manifest) |
| `integrate_e1_e2_e3.py` | Tabla integrada por la llave común; nunca a mano |
| `check_temporal.py` | Verificación temporal de todos los manifests y monotonía entre momentos |
| `run_e3.sh` | Orquesta todo lo anterior |

**Entorno de la ejecución de referencia** (misma declaración honesta que G1A §4): contenedor Linux,
Git 2.43.0, Python 3.13, 2026-10-05. Debo re-ejecutar `run_e3.sh` en mi equipo (Windows 10, Git Bash)
y comparar; el manifest de cada corrida registra comando, versiones y fecha.

## 5. Decisiones de diseño (detalle en la bitácora, D-08 a D-12)

| Decisión | Valor | Por qué |
|---|---|---|
| Transacción | 1 commit | El agrupamiento por día (Bochicchio et al.) mezcla trabajo no relacionado |
| Merges | excluidos | Ya validado en G1A (L-07) |
| Universo | `.java` en `src/main/java` vivos en el decision commit | Tests excluidos: Clase↔ClaseTest co-cambia por convención |
| Commits masivos | > 50 archivos del universo, excluidos | **Mismo umbral que D-04 de G1A**; 100 (D'Ambros et al., 2009) como sensibilidad |
| Renombres | `git log -M` por commit, mapeados a la ruta vigente | **No** `--follow` (ver H-04) |
| Repetición mínima | k = 2 | Un par visto una vez no es patrón |
| Corte temporal | ancestros del decision commit + chequeo de fechas | Más estricto que `--before=fecha` |
| Llave en commons-collections | `artifact_id` = C001…C031, estable por ruta | `entity_id` no es único (3 × `package-info`), ver E-06 |

## 6. Resultados (decision_time = snapshot CIMPS, umbral 50)

| | commons-collections (4.5.0, 2025-04-19) | commons-lang (3.20.0, 2025-11-12) |
|---|---|---|
| Archivos del universo | 359 | 259 |
| Commits en la historia (no-merge) | 4,744 | 8,764 |
| Commits que tocan producción y se usan | 1,889 | 4,418 |
| Commits masivos excluidos | 33 (cambio de paquete 279 arch., layout 237…) | 16 |
| Pares en la salida (30 artefactos) | 4,055 | 1,912 |
| Último commit usado | 2025-04-19 | 2025-11-11 |
| Commits posteriores en el clon **no usados** | 507 | 1,033 |

**Medidas candidatas** (`M_MEDIDAS_CANDIDATAS.md`): **M1** grado de co-change y **M2** confianza
máxima. Ejemplos manuales que coinciden con el script: `SynchronizedQueue` (C028) y `DoubleRange` (F026).

**Verificación temporal** (`out/*/TEMPORAL_CHECK.json`): todos los manifests con fechas ≤ decision_time
y sólo ancestros; **0 violaciones de monotonía** entre los tres momentos en ambos pilotos; `ByteSupplier`
(F020) detectado como inexistente en T3 → *leakage* prevenido.

**Sensibilidad 50 vs 100**: ρ(M1) = 0.97 y ρ(M2) = 0.97 en commons-collections; 0.99 / 0.99 en
commons-lang. El umbral no cambia el orden de los archivos.

**H-07 — La contaminación de la recencia depende del corte.** En 4.5.0 sólo 1 de 30 archivos tiene la
recencia contaminada por commits masivos (SynchronizedQueue); en 2025-11-12 eran 26 de 30. La
diferencia es el barrido de licencia del 2025-05-20, que es **posterior** al snapshot CIMPS: el
hallazgo central de G1A es real, pero su magnitud es propia del corte elegido.

## 7. Hallazgos principales

1. **H-04 — `git log --follow` construye linajes falsos.** Al cruzar E2 con E3, la diferencia
   `prior_commits − (n_commits_e3 + commits masivos)` es **exactamente 0** en los archivos sanos, pero
   llega a 62 en otros. En **mi propio E2** hay 8 de 30 archivos afectados (p. ej. `Get.java` hereda
   historia de `TestAll`, `HashBag`, `TestLRUMap`; `ListOrderedSet` de clases de colecciones primitivas),
   y 8 de 30 en el de Willian. Detalle: `HALLAZGO_LINAJE_FOLLOW.md`.
2. **H-05 — El co-change reciente es mayoritariamente cosmético.** En la práctica manual, 8 de 10
   commits de commons-collections y 6 de 10 de commons-lang son de Javadoc. Los commits "medianos"
   (28–46 archivos) que quedan por debajo del umbral generan la mayoría de pares de un archivo poco activo.
3. **H-06 — M1 es casi redundante con E2** (ρ = 0.96 con `prior_commits` en collections, 0.87 en lang);
   **M2 no lo es** (ρ = −0.07 y 0.33), pero en collections se vuelve inestable en archivos pequeños
   (ρ = −0.59 con LOC).
4. **E-06 — La llave de G1A no es única** en commons-collections (`entity_id = package-info` ×3).
5. **E-07 — El decision_time de G1A no era el snapshot CIMPS** de commons-collections (ver §3 y D-13).

## 8. Guion de la demostración de cierre (≈ 8 min)

1. **Caso manual** (`P1_PRACTICA_MANUAL_COCHANGE.md`, ejecutado en mi equipo): par IteratorChain ↔
   UnmodifiableIterator (COLLECTIONS-722, `845c0e540`).
2. **Leakage prevenido**: ese commit es de 2025-08-19 → en vivo
   `git merge-base --is-ancestor 845c0e540 7f7fb0244 || echo FUTURO` → **FUTURO**: no se usa en el
   snapshot CIMPS; los 10 commits con pareja disponibles en 4.5.0 son cosméticos.
3. **Salida del extractor**: `run_e3.sh` y abrir `E3_COCHANGE_PAIRS_commons-collections_2025-04-19_mf50.csv`
   filtrado por C028.
4. **Medida a mano vs script**: `SynchronizedQueue` en 4.5.0 → 6 commits, 2 masivos excluidos,
   4 elegibles → M1 = 7, M2 = 0.5 (tabla en `M_MEDIDAS_CANDIDATAS.md`) = fila C028 del CSV.
5. **Evidencia temporal**: `TEMPORAL_CHECK.json` + manifest (último commit 2025-04-19; 507 posteriores no usados).
6. **Observación integrada** (con Willian), fila de `INTEGRATED_E1_E2_E3_commons-collections_2025-04-19_mf50.csv`:
   C003 `ListUtils` — E1 719 LOC (provisional, hasta tener SonarQube) · E2 131 commits, 23 contribuidores,
   109 días sin cambios · E3 M1 = 147, M2 = 0.50 con `CollectionUtils`.

## 9. Pendientes

- [ ] Confirmar con el profesor el piloto oficial de la tabla integrada (D-08).
- [x] Leer el artículo CIMPS: E1 de CIMPS es **por proyecto** (16 indicadores SonarQube); no hay E1 por archivo.
- [ ] Generar E1 por archivo con SonarQube local en `7f7fb0244` → `data/E1_FILE_METRICS_commons-collections_2025-04-19.csv` (run_e3.sh lo integra solo).
- [x] Práctica manual en mi terminal (2026-10-14, 10/10 coincide) — repetir el filtro en `7f7fb0244` (tabla A2).
- [ ] Revisar con Willian H-04 antes de cerrar la tabla integrada (no borrar archivos: documentar).
- [ ] Re-ejecutar `run_e3.sh` en mi equipo y registrar versiones.
- [x] Verificación local de G1A en mi equipo: `CollectionUtils` = 225 commits / 22 contribuidores (2026-10-14).
- [ ] Reescribir la ficha L1 con mis palabras.

## 10. Archivos de esta carpeta

```
sprint1_E3/
├── README.md                         (este archivo)
├── 00_RECAPITULACION_PROYECTO.md     contexto CIMPS → Gate G1A → Sprint 1
├── L1_FICHA_Bochicchio2025.md        lectura asignada
├── P1_PRACTICA_MANUAL_COCHANGE.md    práctica manual (10 commits por piloto)
├── M_MEDIDAS_CANDIDATAS.md           M1 y M2: fórmula, ejemplo manual, limitaciones
├── HALLAZGO_LINAJE_FOLLOW.md         H-04, para revisar con Willian
├── data/   ARTIFACTS_commons-collections.csv · E2_commons-lang_Willian_D3_EVOLUTION_DATASET.csv
├── scripts/ extract_cochange.py · integrate_e1_e2_e3.py · check_temporal.py · run_e3.sh
└── out/commons-collections/ · out/commons-lang/
```
