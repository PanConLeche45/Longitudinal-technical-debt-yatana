# Separación temporal de entrenamiento, validación y evaluación

**Estudiante:** Yatana Roa Moreno — ZS23020600
**Piloto:** `apache/commons-collections` · **Gate:** G1A · 2026-09-30

> **Estado:** DISEÑO, NO EJECUTADO.
> Este documento define cómo se separarán los conjuntos cuando se autorice el
> entrenamiento. **Ningún modelo ha sido entrenado.** El punto 10 del checklist
> (control de fuga temporal) permanece abierto por el riesgo L-05, y el propio
> checklist prohíbe el entrenamiento mientras eso ocurra.

---

## 1. Principio

En datos longitudinales, la separación aleatoria (el `train_test_split` habitual)
es inválida: reparte al azar observaciones de distintos momentos, de modo que el
conjunto de entrenamiento contiene futuro respecto del de prueba. El modelo
aprende con información que en producción no tendría.

La separación debe ser **por corte temporal**: todo lo anterior a una fecha
entrena, todo lo posterior evalúa, sin solapamiento.

```
   pasado ────────────────────────────────────────────────▶ futuro

   │◀── ENTRENAMIENTO ──▶│◀─ VALIDACIÓN ─▶│◀── EVALUACIÓN ──▶│
   │                     │                │                  │
  T_ini              corte_1          corte_2            T_fin

   Ninguna característica a la izquierda de un corte puede calcularse
   con información situada a su derecha.
```

## 2. Esquema propuesto: *walk-forward* con origen expansivo

Es el esquema usado por Robredo et al. (2025) y el adecuado cuando se quiere
simular el uso real: en cada iteración el modelo se reentrena con todo lo
conocido hasta un corte y se evalúa sobre el periodo inmediatamente siguiente.

```
Iteración 1:  entrena [T0 .. T3]   evalúa [T4]
Iteración 2:  entrena [T0 .. T4]   evalúa [T5]
Iteración 3:  entrena [T0 .. T5]   evalúa [T6]
...
```

**Ventaja sobre un corte único:** produce varias estimaciones de error en vez de
una, lo que permite ver si el rendimiento se degrada con el horizonte.

## 3. Pseudocódigo

```python
# NO EJECUTADO - diseño para el siguiente sprint

snapshots = cargar_snapshots_ordenados()       # T0 < T1 < ... < Tn
MIN_ENTRENAMIENTO = 3                           # mínimo de snapshots para ajustar

resultados = []

for k in range(MIN_ENTRENAMIENTO, len(snapshots)):

    corte = snapshots[k - 1].fecha              # frontera explícita

    # --- Entrenamiento: SOLO observaciones anteriores al corte ---
    train = dataset[dataset.decision_time <= corte]

    # --- Evaluación: el snapshot inmediatamente siguiente ---
    test  = dataset[dataset.decision_time == snapshots[k].fecha]

    # --- Aserción defensiva: la frontera debe ser infranqueable ---
    assert train.feature_timestamp.max() <= corte, \
        f"FUGA TEMPORAL: característica posterior al corte {corte}"
    assert test.decision_time.min() > corte, \
        f"FUGA TEMPORAL: observación de prueba anterior al corte {corte}"

    modelo = ajustar(train)
    resultados.append(evaluar(modelo, test))
```

La aserción no es decorativa: es el mecanismo que convierte la regla temporal en
algo que falla ruidosamente si se viola, en lugar de degradar el resultado en
silencio.

## 4. Cortes concretos

**No pueden fijarse todavía.** Requieren la serie T0…Tn, que no está construida
(ver `SNAPSHOTS_TEMPORALES.md` §3: con la regla adoptada, la ventana reciente
aporta un solo snapshot válido). Fijar cortes ahora sería inventarlos.

Lo que sí está fijado y verificado:

| Elemento | Valor |
|---|---|
| Frontera temporal absoluta | `decision_time = 2025-11-12` |
| Commit que la materializa | `e96986a5c` |
| Regla aplicada en la generación | `feature_timestamp <= decision_time` |
| Implementación | `--before="$DECISION_TIME"` en todas las llamadas a `git log` |
| Verificación | `grep -n 'before' scripts/build_evolution_dataset.sh` |

## 5. Riesgo específico de este dominio

Los **eventos globales de proyecto** (§L-03, §L-04) atraviesan cualquier corte
temporal: el barrido de licencia del 2025-05-20 afecta simultáneamente a todos
los archivos vivos. Si un corte cae justo después de un barrido, el conjunto de
entrenamiento queda saturado de actividad falsa.

**Implicación para el diseño:** el filtrado de eventos masivos debe aplicarse
**antes** del particionado, no después, y el manifest de cortes debe registrar
qué commits masivos caen en cada periodo.
