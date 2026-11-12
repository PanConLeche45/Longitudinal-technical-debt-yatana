# Índice de entregables — Sprint 2, línea E3

**Estudiante:** Yatana Roa Moreno · ZS23020600 · **Asesor:** Prof. Martín Mancilla Gómez
**Rama:** `sprint2-e3` · **Corte de este índice:** 2026-11-12

Formato solicitado: entregable → estado → archivo o enlace → rama y commit → evidencia verificable →
pendiente residual.

---

## 1. Extractor E3 validado

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/scripts/extract_cochange.py` |
| **Rama y commit** | `sprint2-e3` · `8c51f75` |
| **Evidencia** | `out/*/E3_RUN_MANIFEST_*.json` registra `ancestry_check` con el método, el número de ancestros del SHA de decisión, los commits verificados y los no ancestros. En commons-collections 4.5.0: 4,851 ancestros, 1,889 commits verificados, 0 fuera de la historia. Reejecutar el extractor desde cero reproduce los CSV de medidas sin diferencias. |
| **Pendiente residual** | Ninguno en el control de ancestría. El universo se fija en el commit de decisión, así que los archivos borrados antes del corte no aportan pares: documentado como limitación en `M_MEDIDAS_CANDIDATAS.md`. |

## 2. Medidas M1 y M2 con evidencia manual y automatizada

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/M_MEDIDAS_CANDIDATAS.md` · `sprint2_E3/P1_PRACTICA_MANUAL_COCHANGE.md` |
| **Rama y commit** | `sprint2-e3` · `ffa2a87` |
| **Evidencia** | Dos ejemplos calculados a mano que coinciden con la salida del script: `SynchronizedQueue` (C028) en commons-collections, 6 commits, 2 masivos excluidos, 4 elegibles, M1 = 7 y M2 = 0.50; y `DoubleRange` (F026) en commons-lang. Documentado el efecto de los commits masivos, los cambios cosméticos, los umbrales y los archivos con poca historia. Sensibilidad 50 contra 100: ρ = 0.97 en ambos pilotos. |
| **Pendiente residual** | Las correlaciones entre M1, M2 y E2 se presentan como resultado exploratorio, no como valor predictivo. No se agregaron métricas nuevas, conforme a la instrucción. |

## 3. Verificación temporal reforzada

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/scripts/check_temporal.py` · `out/*/TEMPORAL_CHECK.json` |
| **Rama y commit** | `sprint2-e3` · `ffa2a87` (verificador) y `8c51f75` (ancestría) |
| **Evidencia** | Cero violaciones de monotonía en los tres momentos de los dos pilotos. Todas las fechas de commit usadas son anteriores o iguales al `decision_time`. 507 commits posteriores en el clon de commons-collections y 1,033 en el de commons-lang quedan sin usar. `ByteSupplier` (F020) detectado como inexistente en su corte y excluido en lugar de rellenado con ceros. |
| **Pendiente residual** | Ninguno. |

## 4. Rechazo de llaves duplicadas y existencia en el corte

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/scripts/integrate_e1_e2_e3.py` · `sprint2_E3/scripts/test_integracion.sh` |
| **Rama y commit** | `sprint2-e3` · `8c51f75` |
| **Evidencia** | Tres pruebas, dos negativas y una positiva, reproducibles con `bash sprint2_E3/scripts/test_integracion.sh <clon>`. La llave duplicada termina con código 1 y no escribe ningún CSV; el archivo inexistente en el corte queda registrado en `issues`; el caso correcto integra 30 filas. Resultado en la última ejecución: 3 de 3 pasan. |
| **Pendiente residual** | Decidir con el asesor si un archivo inexistente en el corte debe abortar la integración o basta con registrarlo. |

## 5. Métricas E1 reales y su procedencia

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/data/E1_FILE_METRICS_commons-collections_2025-04-19.csv` · `data/E1_RUN_MANIFEST_commons-collections_2025-04-19.json` |
| **Rama y commit** | `sprint2-e3` · `b886d23` (datos) y `c2788f6` (análisis frente a CIMPS) |
| **Evidencia** | Corrida real de SonarQube sobre el SHA `7f7fb0244`, con versión del analizador, perfil de calidad, número de reglas activas, fecha de análisis y alcance de archivos registrados en el manifiesto. El NCLOC a nivel archivo coincide exactamente con la Tabla 2 de CIMPS (32,688), lo que acota la diferencia en code smells y deuda al analizador y al perfil, no al conjunto de archivos medidos. |
| **Pendiente residual** | Las métricas ausentes a nivel archivo se rellenaron con cero y así está anotado en el manifiesto; conviene distinguir "ausente" de "cero" antes de usarlas en cualquier análisis. |

## 6. Tabla integrada E1 + E2 + E3

| | |
|---|---|
| **Estado** | Completo para los dos pilotos, sujeto a la decisión del piloto oficial |
| **Archivo** | `sprint2_E3/out/commons-collections/INTEGRATED_E1_E2_E3_commons-collections_2025-04-19_mf50.csv` · `sprint2_E3/out/commons-lang/INTEGRATED_E1_E2_E3_commons-lang_2025-11-12_mf50.csv` |
| **Rama y commit** | `sprint2-e3` · `8c51f75` (collections) y `a828410` (lang) |
| **Evidencia** | Llave `project + artifact_id + decision_time`, con el SHA de decisión conservado como procedencia. Los `INTEGRATION_CHECKS_*.json` reportan unicidad de llaves, incidencias y casos de linaje marcados. En commons-collections quedan 8 casos marcados con `REVISAR_LINAJE`, visibles en la columna `check_e2_vs_e3_history`. En commons-lang, al reconstruir la tabla con el E2 corregido del compañero, cambian 11 filas y los 8 casos marcados se resuelven. Todo se regenera por script, sin ediciones manuales. |
| **Pendiente residual** | Confirmar con el asesor el piloto oficial de la tabla integrada (decisión D-08) y si los casos marcados se excluyen o basta con señalarlos. |

## 7. Hallazgo sobre el linaje heredado

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/HALLAZGO_LINAJE_FOLLOW.md` |
| **Rama y commit** | `sprint2-e3` · `ffa2a87` |
| **Evidencia** | El cruce entre E2 y E3 da diferencia exactamente cero en los archivos sanos y llega a 62 commits en otros. 8 de 30 archivos afectados en cada piloto. La reconstrucción de commons-lang con el E2 corregido confirma la dirección: el procedimiento heredado contaba de más. |
| **Pendiente residual** | Ninguno de mi lado; la corrección del linaje es responsabilidad de la línea E2. |

## 8. Ficha de lectura L1

| | |
|---|---|
| **Estado** | Completo |
| **Archivo** | `sprint2_E3/L1_FICHA_Bochicchio2025.md` |
| **Rama y commit** | `sprint2-e3` · `392c6c6` |
| **Evidencia** | Versión final redactada con mis palabras, incluidas las respuestas de la autora. |
| **Pendiente residual** | Ninguno. |

---

## Pendientes que no son entregables

| Asunto | Quién decide | Por qué está abierto |
|---|---|---|
| Piloto oficial de la tabla integrada (D-08) | Asesor | El extractor es genérico y E3 se construyó en los dos pilotos |
| Tratamiento de los casos de linaje marcados | Asesor | "Sin tratarlos como observaciones válidas" admite excluirlos o señalarlos |
| Serie de snapshots T0…Tn de mi piloto | Mía | Punto 7 del Sprint 1, no cerrado |
| Propuesta de preparación del experimento, cinco preguntas | Conjunta con William | Él tiene un borrador en su rama `sprint2-e2` |

## Restricción respetada

No se entrenaron modelos, no se optimizaron hiperparámetros y no se ejecutaron comparaciones
predictivas. Las correlaciones reportadas son exploratorias y no se presentan como evidencia de
valor predictivo.
