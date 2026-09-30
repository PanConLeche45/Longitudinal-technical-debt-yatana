# D4 — Análisis: RefactoringMiner y eventos de refactoring

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Piloto:** `apache/commons-collections` · **Gate:** G1A · 2026-09-30

---

## 1. Ejecución

| Elemento | Valor |
|---|---|
| Herramienta | RefactoringMiner **3.0.10** |
| Java | OpenJDK 21.0.10 |
| Modo | `-bc` (detección entre dos commits) |
| Commit inicial | `7f7fb0244abc940a2e9dd28b67508c0483a58c3e` (`rel/commons-collections-4.5.0`, 2025-04-22) |
| Commit final | `e96986a5c61e8fc9e7a180579ef793253161b7c3` (`decision_time`, 2025-11-09) |
| Commits en el rango | 119 |
| Commits procesados | **115** |
| Errores | **0** |
| Refactorings detectados | **1,979** |
| Log de ejecución | `docs/D4_refactoringminer_run.log` |
| Salida cruda | `D4_REFACTORING_EVENTS_RAW.json` (1.9 MB) |

Comando exacto:

```bash
./tools/RefactoringMiner-3.0.10/bin/RefactoringMiner -bc \
  repos/commons-collections \
  7f7fb0244abc940a2e9dd28b67508c0483a58c3e \
  e96986a5c61e8fc9e7a180579ef793253161b7c3 \
  -json D4_REFACTORING_EVENTS_RAW.json
```

**Justificación del rango:** la ventana va del último release final anterior al
snapshot CIMPS hasta el propio `decision_time`. Es un intervalo acotado,
semánticamente delimitado por el proyecto, y enteramente anterior al corte
temporal, por lo que no introduce fuga.

---

## 2. Hallazgo central: el 97.73% de los refactorings son un barrido mecánico

### 2.1 Distribución bruta por tipo

| Tipo de refactoring | Frecuencia | % |
|---|---|---|
| Change Method Access Modifier | 1,836 | 92.77% |
| Change Class Access Modifier | 98 | 4.95% |
| Rename Class | 12 | 0.61% |
| Remove Class Annotation | 4 | 0.20% |
| Extract Method | 4 | 0.20% |
| Rename Parameter | 3 | 0.15% |
| *(16 tipos más)* | 22 | 1.12% |

Una distribución tan degenerada —un solo tipo con el 93%— no describe actividad
de diseño. Describe una operación automatizada.

### 2.2 Los tres commits responsables

| Commit | Fecha | Autor | Mensaje | Refactorings | Archivos |
|---|---|---|---|---|---|
| `d1a4c56c3` | 2025-06-07 | Gary D. Gregory | *Use JUnit 5 convention for @Test method visibility* | **1,424** | 194 |
| `48afb43fa` | 2025-06-07 | Gary D. Gregory | *Use JUnit 5 convention for test method visibility* | **401** | 139 |
| `3d737b007` | 2025-06-08 | Gary D. Gregory | *Use JUnit 5 convention for class visibility* | **109** | 99 |

Los tres son el mismo trabajo: eliminar el modificador `public` de los métodos y
clases de prueba, porque JUnit 5 no lo requiere. Es un cambio de convención
aplicado mecánicamente sobre toda la suite de pruebas, en dos días.

### 2.3 Separación señal / ruido

Marcando como *evento masivo* todo refactoring que ocurre en un commit que toca
≥ 50 archivos:

| Categoría | Eventos | % |
|---|---|---|
| En commits masivos (ruido de convención) | **1,934** | 97.73% |
| En commits individuales (señal de diseño) | **45** | 2.27% |

### 2.4 Los 45 refactorings genuinos

Al filtrar, la distribución se vuelve plausible: variada, dominada por
operaciones que sí reflejan decisiones de diseño.

| Tipo | Frecuencia |
|---|---|
| Rename Class | 12 |
| Remove Class Annotation | 4 |
| Extract Method | 4 |
| Rename Parameter | 3 |
| Modify Method Annotation | 2 |
| Remove Variable Annotation | 2 |
| Change Attribute Access Modifier | 2 |
| Assert Throws | 2 |
| Rename Method | 2 |
| Inline Variable | 2 |
| *(10 tipos con 1 evento cada uno)* | 10 |

*Extract Method*, *Rename Method* e *Inline Method* son operaciones de diseño
real. Que solo haya 4, 2 y 1 en siete meses de desarrollo es un dato en sí
mismo: el proyecto está maduro y estabilizado.

---

## 3. Implicación metodológica

RefactoringMiner **no se equivoca**: los 1,934 eventos del barrido son
formalmente refactorings —cambiar un modificador de acceso es la operación
*Change Method Access Modifier* del catálogo—. El problema no es la detección,
es la **interpretación**.

> Un estudio que use el conteo bruto de refactorings como proxy de "esfuerzo de
> mejora" o "pago de deuda técnica" concluiría que entre abril y noviembre de
> 2025 `commons-collections` vivió una intensa campaña de refactorización. Lo
> que ocurrió fue que un desarrollador actualizó la convención de visibilidad de
> las pruebas en dos días.

Esta es la conexión directa con el gap (§D1): Iammarino et al. (2021) relacionan
conteos de refactoring con eliminación de deuda auto-admitida sin reportar un
filtrado explícito de barridos mecánicos. Este resultado sugiere que ese
filtrado no es un detalle de implementación, sino una condición de validez.

---

## 4. Auditoría de 30 eventos

`D4_REFACTORING_AUDIT_30.csv` contiene una muestra aleatoria reproducible
(semilla fija `20250930`) de 30 eventos, cada uno con:

- identificador, commit, fecha, tipo y archivo afectado;
- el **comando de verificación** para comprobarlo contra el historial real;
- verificación automática de que el archivo reportado aparece efectivamente
  entre los archivos modificados por ese commit;
- veredicto: `COHERENTE` / `REVISAR`.

La comprobación automática confirma que los eventos detectados corresponden a
archivos realmente tocados por los commits citados: **no hay eventos
fantasma**. La revisión manual caso por caso del contenido semántico de cada
refactoring está pendiente.

---

## 5. Limitaciones de D4

1. **Ventana única.** Se analizó un solo intervalo entre releases. No permite
   comparar la tasa de refactoring entre periodos, que es lo que un estudio
   longitudinal necesita.
2. **Umbral no validado.** El corte de 50 archivos separa bien en este caso
   (1,934 vs. 45 es una brecha nítida), pero no se ha probado su
   comportamiento en casos límite.
3. **Precisión/recall no verificados localmente.** Se asumen los valores
   publicados de la herramienta; la ficha bibliográfica correspondiente está
   pendiente (§D1.2).
4. **Sin cruce con el dataset de evolución.** Los eventos de refactoring no se
   han unido todavía con `D3_EVOLUTION_DATASET.csv` por `(entity_id, commit)`.
   Ese cruce es el siguiente paso natural y no está hecho.
5. **Un solo autor.** Los tres commits del barrido son del mismo desarrollador,
   que además es el contribuidor dominante del proyecto. No se ha analizado si
   la concentración de autoría sesga el resultado.
