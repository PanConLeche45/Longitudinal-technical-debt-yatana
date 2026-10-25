# Recapitulación del proyecto — Gestión de la Deuda Técnica (continuidad post-CIMPS)

**Estudiante:** Yatana Roa Moreno — ZS23020600 · **Asesor:** Prof. Martín Mancilla Gómez
**Línea paralela:** William Tehuatle Sosa · **Corte:** 2026-10-05

---

## 1. Punto de partida: CIMPS 2026
El artículo CIMPS midió deuda técnica de código en **8 proyectos Java** (checkstyle,
commons-collections, commons-lang, commons-math, httpcomponents-client, junit4, maven, pdfbox) en
**un único snapshot** por proyecto. Funciona como **línea base**, no como evidencia longitudinal: una
foto no permite afirmar evolución, acumulación, persistencia ni predicción.

> Leído (2026-10-15): unidad de análisis = **proyecto**; 16 indicadores de SonarQube por proyecto,
> normalizados por KLOC. No hay métricas por archivo → E1 por archivo × tiempo se genera con SonarQube
> local en el snapshot CIMPS. El snapshot de commons-collections es 4.5.0 (`7f7fb0244`), no 2025-11-12 (E-07).

## 2. Sprint 1 — Gate G1A (Ruta B: hotspots y contexto de commits/issues/PR)

| | Yatana (este repo) | Willian |
|---|---|---|
| Piloto | **commons-collections** | commons-lang |
| decision_time | G1A: 2025-11-12 · `e96986a5c` → **Sprint 1: 2025-04-19 · `7f7fb0244` (rel 4.5.0 = snapshot CIMPS, D-13)** | 2025-11-12 · `598dfc163` (rel 3.20.0 = snapshot CIMPS) |
| D2 inventario 8 proyectos | Completo (E-04 maven doble tracker; E-05 rutas multi-módulo **abierto**) | Completo |
| D3 identidad | 10 archivos, 21 eventos; cambio de paquete con **R095–R099** | 10 archivos, R100 |
| D3 dataset | 30 × 6 + **recencia corregida** (84 commits masivos ≥ 50; 26/30 contaminados; sesgo máx. 2,509 días en SynchronizedQueue) | 30 × 6 |
| D4 RefactoringMiner 3.0.10 | 1,979 refactorings; **97.73 %** de 3 commits de convención JUnit 5 | en curso (archivos D4 en su repo) |
| Leakage | 7 riesgos; **L-05 (etiquetas con futuro) abierto** | — |
| Snapshots T0…Tn | **No construidos** (punto 7) | T0–T5 = releases 3.15.0–3.20.0 |
| D1 estado del arte | 2 de 8 artículos | en curso |
| D5 plan de evolución | Completo | pendiente |
| Autoevaluación | **G1A = INCONCLUSIVE** | — |

**Convergencias que ya demostraste:** el barrido de licencia del 2025-05-20 (711 vs 511 archivos) es
sistémico del corpus; las migraciones globales arrastran todos los archivos vivos; la regla "identidad
= R100" no generaliza.

## 3. Sprint 2 — tres familias de evidencia con una sola llave

```
                project + artifact_id + decision_time
 E1 estática (CIMPS)  ·  E2 historia individual (Willian)  ·  E3 hotspot/co-change (Yatana)
 ¿cómo está el archivo?   ¿cuánto y quién lo cambió?          ¿con quién cambia y con qué fuerza?
                      todo con información ≤ decision_time
```
Restricciones: sin modelos finales, sin hiperparámetros, sin splits aleatorios, sin mover ventanas, sin
quitar archivos incómodos, sin futuro, refactor ≠ pago de deuda, métricas documentadas, repos intactos.

## 4. Mapa de literatura para E3

| Referencia | Aporte |
|---|---|
| Gall, Hajek & Jazayeri (1998), ICSM | Origen de *logical coupling* desde la historia |
| Ying et al. (2004), IEEE TSE 30(9); Zimmermann et al. (2005), IEEE TSE 31(6) | Reglas de asociación sobre commits: *support* y **confidence** → M2 |
| D'Ambros, Lanza & Robbes (2009), WCRE | NOCC y SOC por archivo; filtro de transacciones > 100 clases → M1 y sensibilidad |
| Kouroshfar et al. (2015), MSR | Co-changes que cruzan módulos se asocian a más bugs |
| Mo, Cai, Kazman & Xiao (2015), WICSA | *Hotspot patterns* arquitectónicos |
| Sas et al. (2021), SN Comput. Sci. 2(1) | ~90 % de los co-changes aparecen **antes** del smell |
| **Bochicchio et al. (2025), IST 185** (mi lectura) | Pares con smells co-cambian más (ficha L1) |
| Robredo et al. (2025), JSS 230 (lectura de Willian) | Deuda dependiente del tiempo; *walk-forward*, sin split aleatorio |
| Herzig, Just & Zeller (2016) — pendiente en mi D1 | *Tangled changes*: commits que mezclan cambios no relacionados (explica H-05) |
| Tornhill, *Your Code as a Crime Scene* | Hotspot = frecuencia × complejidad (cruce E2 × E1) |

**Ya no es novedad:** co-change como proxy de acoplamiento; asociación smells/deuda ↔ co-change;
pipelines continuos de datasets de deuda. **Nuestro aporte posible:** observación archivo × tiempo con
corte estricto, E1+E2+E3 integrados por la misma llave, para medir después el **valor incremental** de
cada familia con separación temporal.

## 5. Estado de mis actividades del Sprint 2

| # | Actividad | Estado |
|---|---|---|
| 1 | Revisar CIMPS / estructura existente | Estructura de E2 de ambos pilotos entendida; **falta el artículo para E1** |
| 2 | Lectura Bochicchio et al. (2025) | Borrador de ficha (`L1_FICHA_Bochicchio2025.md`) |
| 3 | Práctica manual (≥ 10 commits) | Clave para ambos pilotos; **hacerla en mi terminal** |
| 4 | Extractor | Hecho; 3 momentos × 2 pilotos + sensibilidad |
| 5 | ≤ 2 medidas | M1 y M2 con 2 ejemplos manuales |
| 6 | Verificación temporal | Hecha (`check_temporal.py`) |
| 7 | Integración ≥ 10 archivos | 30 + 30 filas por script; E1 provisional |
| 8 | Demostración | Guion en README §8 |

## 6. Hallazgos nuevos que afectan a G1A
- **H-04:** `--follow` infla E2 en ~8/30 archivos por piloto → revisar puntos 6 y 8 de G1A.
- **E-06:** `entity_id` no es único en mi D3 (3 × `package-info`) → la llave necesita `artifact_id`.
