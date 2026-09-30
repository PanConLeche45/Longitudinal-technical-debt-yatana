# Provenance e integridad de los resultados

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Gate:** G1A · **Versión:** v1.0 — 2026-09-30

Objetivo: que cualquier resultado de este repositorio pueda rastrearse hasta
sus entradas y hasta la versión del código que lo generó.

---

## 1. Entorno de ejecución

**Declaración honesta de entorno.** Los artefactos de datos de esta entrega se
generaron en un contenedor Linux (entorno de trabajo asistido), no en el equipo
personal de la autora. Esto no afecta a la validez de los datos —el historial
de Git de `commons-collections` es idéntico en cualquier clon, y todos los
scripts son deterministas— pero debe constar, y los comandos de verificación de
la §5 existen precisamente para que la autora reproduzca y confirme cada número
en su propio equipo.

| Elemento | Entorno de generación | Equipo de la autora |
|---|---|---|
| Sistema operativo | Linux 6.18.44 (contenedor) | Windows 10, Git Bash / MINGW64 |
| Git | 2.43.0 | 2.54.0.windows.1 |
| Java | OpenJDK 21.0.10 | OpenJDK 25.0.3 LTS (2026-04-21) |
| Python | 3.11.15 | 3.x (no utilizado en el pipeline principal) |
| RefactoringMiner | 3.0.10 | — pendiente de ejecución local |
| Fecha de ejecución | 2026-09-30 | — |

RefactoringMiner 3.0.10 requiere Java 17 o superior; ambas versiones (21 y 25)
lo satisfacen. Se espera salida idéntica; la verificación está pendiente.

## 2. Entradas

| Entrada | Origen | Identificador exacto |
|---|---|---|
| Repositorio piloto | `https://github.com/apache/commons-collections` | commit de referencia `e96986a5c61e8fc9e7a180579ef793253161b7c3` |
| Corpus completo | 8 repositorios GitHub (ver `D2_CIMPS8_OBSERVABILIDAD.csv`) | clonados 2026-09-30 |
| Momento de decisión | parámetro | `decision_time = 2025-11-12` |
| Ventana RefactoringMiner | rango de commits | `7f7fb0244abc940a2e9dd28b67508c0483a58c3e` → `e96986a5c61e8fc9e7a180579ef793253161b7c3` |

## 3. Cadena raw → processed → analysis → output

```
RAW                          PROCESSED                        ANALYSIS / OUTPUT
───                          ─────────                        ─────────────────

8 repos Git clonados
  │
  ├─ build_observability_inventory.sh ──▶ D2_CIMPS8_OBSERVABILIDAD.csv ──▶ README §5
  │
repo commons-collections
  │
  ├─ build_artifact_identity.sh ────────▶ D3_ARTIFACT_IDENTITY.csv ──────▶ D3_Analisis_Evolucion.md §2
  │     entrada: docs/D3_SELECCION_IDENTIDAD.txt
  │
  ├─ build_evolution_dataset.sh ────────▶ D3_EVOLUTION_DATASET.csv ──────┐
  │                                       D3_SELECCION_30.txt            │
  │                                                                       ├─▶ D3_Analisis_Evolucion.md §3-4
  ├─ add_corrected_recency.sh ──────────▶ D3_EVOLUTION_DATASET_          ┘
  │     entrada: D3_EVOLUTION_DATASET.csv   CORREGIDO.csv
  │
  └─ RefactoringMiner 3.0.10 -bc ───────▶ D4_REFACTORING_EVENTS_RAW.json
        │                                  docs/D4_refactoringminer_run.log
        │
        └─ parse_refactoring_events.py ──▶ D4_REFACTORING_EVENTS_RAW.csv ─┐
                                           D4_REFACTORING_TIPOS.csv       ├─▶ D4_Analisis_Refactorings.md
                                           D4_REFACTORING_AUDIT_30.csv    ┘
```

Cada flecha es un script versionado en `scripts/`. Ningún archivo de datos se
editó a mano.

## 4. Hashes de integridad (SHA-256)

Generados con `sha256sum` el 2026-09-30 sobre los artefactos entregados.

### Datos

| Archivo | SHA-256 |
|---|---|
| `D2_CIMPS8_OBSERVABILIDAD.csv` | `f3b105a7118b94b1e95c14529da446b0c9081b79a94dd0181dfe53038122f3bd` |
| `D3_ARTIFACT_IDENTITY.csv` | `446691e26e7987127f751eb15603b9ff6826410dab1a5d33ae48d73ce1326788` |
| `D3_EVOLUTION_DATASET.csv` | `2b149ba223e7446cca071d5d44c3a19ab8efdf308bf4237a84113c947f841ea2` |
| `D3_EVOLUTION_DATASET_CORREGIDO.csv` | `a0413b82dfb878fb42c052ef5dbb273ac06a681268d8b3a80aa8fd8df06cb2be` |
| `D4_REFACTORING_EVENTS_RAW.json` | `af6e117ae502f597991d5763fc92bd216cf1e0a5f517ddf39c91425edb897acc` |
| `D4_REFACTORING_EVENTS_RAW.csv` | `e365b7bf269c3f3c04d8a5966d4c38de88483459284c5401b23e65edd24bea52` |
| `D4_REFACTORING_TIPOS.csv` | `cf7804a04180481b874ed7568a4a15adcaaf9bff10d36585011a79bfa1335916` |
| `D4_REFACTORING_AUDIT_30.csv` | `61b3814481062d6a27057f0e235d0b4badab45b060059d7f6f4f1c13ef28b0f5` |

### Scripts

| Archivo | SHA-256 |
|---|---|
| `scripts/build_observability_inventory.sh` | `e518ccedba9db3bc287f272dc1044172f4f13a7568d477e7e7c2e5d76b18a1dd` |
| `scripts/build_artifact_identity.sh` | `40e75d49f911ed025e1451fde552b868c7f1d0c4e712c74a6a10c39be4a5cc3a` |
| `scripts/build_evolution_dataset.sh` | `db582e82f3fc602817ade94647bc8658be3be18a23e9de5bb576379669ffbbb3` |
| `scripts/add_corrected_recency.sh` | `275de0ae2d42ad761077d82d477f3172f45d71ee2789c1626d88e0d2305ca616` |
| `scripts/parse_refactoring_events.py` | `4d621e821ee4af208437d804a478eb0335375bdb2581b5d1303152a968660113` |

Para verificar: `sha256sum -c HASHES.txt` desde la raíz del repositorio.

## 5. Comandos de verificación independiente

Cualquier revisor puede confirmar los números centrales sin ejecutar el
pipeline completo:

```bash
# --- Commit de referencia y su fecha ---
git -C repos/commons-collections log -1 --format='%H %cd' --date=short e96986a5c

# --- prior_commits de CollectionUtils (debe dar 225) ---
git -C repos/commons-collections log --before=2025-11-12 --oneline --follow \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java | wc -l

# --- distinct_contributors de CollectionUtils (debe dar 22) ---
git -C repos/commons-collections log --before=2025-11-12 --follow --format='%an' \
  -- src/main/java/org/apache/commons/collections4/CollectionUtils.java | sort -u | wc -l

# --- Tamaño del commit de licencia (debe dar 711 archivos) ---
git -C repos/commons-collections show --stat --format='' 8ee475dcc | tail -1

# --- Los tres commits de convención JUnit 5 ---
git -C repos/commons-collections log -1 --format='%h %ad %s' --date=short d1a4c56c3
git -C repos/commons-collections log -1 --format='%h %ad %s' --date=short 48afb43fa
git -C repos/commons-collections log -1 --format='%h %ad %s' --date=short 3d737b007

# --- Total de refactorings detectados (debe dar 1979) ---
tail -n +2 D4_REFACTORING_EVENTS_RAW.csv | wc -l

# --- Refactorings en commits masivos (debe dar 1934) ---
tail -n +2 D4_REFACTORING_EVENTS_RAW.csv | awk -F, '$14=="SI"' | wc -l
```

## 6. Limitación de provenance pendiente

Los repositorios clonados (`repos/`) están excluidos por `.gitignore` y no
forman parte del versionado, por peso. La reproducibilidad depende de que los
repositorios remotos sigan disponibles y de que los commits citados no sean
reescritos. Mitigación pendiente: registrar en un manifest el hash del `HEAD`
de cada clon en el momento de la ejecución.
