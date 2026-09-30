# D0 — Objetivo de investigación

**Estudiante:** Yatana Roa Moreno — Matrícula ZS23020600
**Universidad Veracruzana — Facultad de Ingeniería**
**Línea:** Ruta B — archivos que concentran cambios (*hotspots*) y contexto de commits, issues y pull requests
**Proyecto piloto:** `apache/commons-collections`
**Versión:** v1.0 — 2026-09-30
**Gate:** G1A

---

## 1. Antecedente

El artículo enviado a CIMPS 2026 analizó deuda técnica de código en ocho
proyectos Java de código abierto **en un único momento del tiempo**: un
*snapshot* por proyecto. Un snapshot permite describir el estado de la deuda,
pero no permite afirmar nada sobre su **evolución, acumulación, persistencia o
predicción**, porque para eso se requiere observar la misma entidad en varios
momentos.

CIMPS funciona, por tanto, como **línea base (baseline)**, no como evidencia
longitudinal.

## 2. Pregunta de investigación

> **¿Es metodológicamente factible reconstruir la evolución temporal de los
> proyectos del corpus CIMPS de forma trazable —siguiendo la misma entidad a
> través del historial y sin utilizar información posterior al momento de
> decisión— de manera que se pueda diseñar sobre ella un estudio experimental
> de deuda técnica?**

La pregunta es de **factibilidad metodológica**, no de resultado sustantivo.
En esta etapa no se pretende medir deuda técnica ni predecir nada: se pretende
determinar si el sustrato de datos soporta el estudio que se quiere construir.

## 3. Sub-preguntas operativas

Esta etapa se considera resuelta cuando existe evidencia ejecutada para las
tres preguntas siguientes:

- **SQ1 — Identidad.** ¿Puede seguirse el mismo archivo a través del historial
  cuando cambia de ruta, paquete o layout, con evidencia verificable y no por
  suposición?
- **SQ2 — Temporalidad limpia.** ¿Pueden calcularse métricas de un archivo en
  un momento dado usando exclusivamente información anterior a ese momento?
- **SQ3 — Señal utilizable.** ¿La actividad registrada en el historial
  (commits, refactorings) refleja trabajo real sobre cada entidad, o está
  dominada por eventos que afectan al proyecto entero?

## 4. Conocimiento nuevo que se pretende producir

Respecto al artículo CIMPS, este trabajo no repite la medición de deuda: aporta
la **caracterización de las condiciones de validez** bajo las cuales esa
medición puede extenderse en el tiempo. En concreto:

1. Un procedimiento reproducible para establecer la identidad longitudinal de
   artefactos, con el tipo de evidencia que la sostiene (similitud de renombre
   y mensaje de commit ligado a ticket del tracker).
2. Una regla temporal explícita (`feature_timestamp <= decision_time`) aplicada
   y verificada en la generación del dataset.
3. La cuantificación de un sesgo sistemático —los **eventos globales de
   proyecto**— que contamina simultáneamente las métricas de recencia y los
   conteos de refactorings, y una regla de filtrado para mitigarlo.

## 5. Lo que este trabajo NO afirma

Delimitación explícita, para no sobre-interpretar la evidencia:

- No mide deuda técnica total; el análisis estático y el historial de cambios
  son indicadores parciales.
- Alta frecuencia de cambio **no** equivale a deuda técnica.
- Un refactoring detectado **no** equivale a pago de deuda.
- Ninguna asociación observada se interpreta como causalidad.
- No se entrena ningún modelo ni se emite ningún claim predictivo: el punto 10
  del checklist G1A lo prohíbe expresamente mientras el control de fuga
  temporal permanezca abierto.

## 6. Relación con el entregable paralelo

Este trabajo se desarrolla en paralelo y con la misma metodología (Ruta B) que
el entregable de **William Tehuatle Sosa**, sobre el mismo corpus de ocho
proyectos, con **proyecto piloto distinto**:

| | Piloto | decision_time |
|---|---|---|
| W. Tehuatle Sosa | `commons-lang` | 2025-11-12 |
| **Y. Roa Moreno (este trabajo)** | **`commons-collections`** | **2025-11-12** |

La coincidencia de `decision_time` es deliberada: permite que ambos resultados
sean comparables. La divergencia de piloto es igualmente deliberada: permite
comprobar si los hallazgos metodológicos son propios de un proyecto o
sistémicos del corpus. La sección 8 del README documenta los puntos donde los
dos pilotos **coinciden** y donde **divergen**.
