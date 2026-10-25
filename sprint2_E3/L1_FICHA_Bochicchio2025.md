# L1 — Ficha de lectura: Bochicchio et al. (2025)

**Lectora:** Yatana Roa Moreno (ZS23020600) · **Fecha:** 2026-10-25 · **Sprint 2, línea E3**

**Referencia:** Bochicchio, M., Sas, D., Gilardi, A., & Arcelli Fontana, F. (2025). *An empirical study on
architectural smells through a pipeline for continuous technical debt assessment.* Information and
Software Technology, 185, 107783. https://doi.org/10.1016/j.infsof.2025.107783 (acceso abierto, CC BY)

---

## 1. Objetivo
Los autores construyeron un *pipeline* que **mide** la deuda técnica arquitectónica de forma automática
en muchos proyectos (no la elimina: la detecta y la registra, para no hacerlo a mano). Con esos datos
estudiaron una sola pregunta: **¿los archivos con *smells* arquitectónicos cambian juntos más seguido que
los que no tienen?**

Un *smell* arquitectónico es un mal diseño en cómo se conectan las partes del sistema (por ejemplo, un
archivo del que dependen demasiados otros, o archivos que dependen unos de otros en círculo).

## 2. Unidad de análisis
**Parejas de archivos** del mismo proyecto, porque el co-change es una relación entre dos archivos (no son
clones ni duplicados). Cada pareja se clasifica en:
- ***smelly***: los dos archivos tienen smell;
- ***mixed***: sólo uno tiene smell;
- ***clean***: ninguno tiene smell.

## 3. Definición de co-change
Dos archivos que se modifican juntos. Ellos lo cuentan **por día** y no por commit: si A y B cambian el
mismo día, aunque sea en commits distintos, cuenta como co-change. Problema: se mezclan cambios que no
tienen relación entre sí. Yo lo cuento **por commit**.

## 4. Fuente de datos
Proyectos de **GitHub** en **Java y C#** (≥ 100 estrellas, ≥ 10,000 líneas de código). Los smells se
detectaron con la herramienta **Arcan** (4 tipos de smell). **112 proyectos** con resultados completos.

## 5. Construcción temporal
**No separan pasado y futuro**: toman el smell de la última versión y cuentan los co-changes de **toda**
la historia, incluido lo que pasó después. Para mi trabajo eso es **fuga de información del futuro**
(*temporal leakage*). Por eso yo sólo uso commits **anteriores al `decision_time`**.
Ejemplo de mi práctica manual: el commit `845c0e540` (COLLECTIONS-722) es de agosto de 2025, posterior
al snapshot CIMPS 4.5.0 (19-abr-2025), y mi extractor **no lo usa**; en total quedaron fuera 507 commits
posteriores.

## 6. Variables
| Variable | Rol |
|---|---|
| Tipo de pareja (*smelly*, *mixed*, *clean*) | Independiente: lo que se compara |
| Qué tan seguido cambia junta la pareja (*co-change rate*) | Dependiente: lo que se mide |
| Tamaño de los archivos (líneas de código) | Control: un archivo grande cambia más sólo por ser grande |

## 7. Comparación realizada
En **cada proyecto por separado** (para que los proyectos grandes no dominen el resultado) comparan
*smelly* contra *clean*, *mixed* contra *clean* y *smelly* contra *mixed* con una prueba estadística
(Mann-Whitney), corrigiendo por hacer muchas pruebas a la vez, y lo repiten por tamaño de archivo.

## 8. Resultados
- En casi **8 de cada 10 proyectos** (78.6 %), las parejas *smelly* cambian juntas más que las *clean*.
- El efecto es **más fuerte en archivos grandes**.
- En *mixed* contra *clean* el efecto típico fue **casi nulo o al revés**, aunque el artículo lo presenta
  como "mixed > clean"; vale la pena señalarlo.
- La mayoría de las parejas casi nunca cambian juntas.

## 9. Amenazas a la validez
**La más importante para mi trabajo: usan el futuro.** Al contar co-changes con toda la historia, sin
corte de fecha, el resultado puede verse mejor de lo que es.

Otras:
- No quitan los **commits masivos** (cambios de licencia o formato que tocan cientos de archivos), que
  inflan el co-change. Yo los quito con un límite de 50 archivos.
- Contar por día mezcla cambios no relacionados.
- Todo depende de lo que detecte **Arcan**; otra herramienta podría encontrar smells distintos. Sólo 4
  tipos de smell y sólo Java y C#.
- Muestra que smell y co-change van juntos (correlación), no que uno cause el otro.

## 10. Qué uso de este artículo y qué aporta lo mío
**Lo que tomo:**
1. El **co-change como señal de conexión** entre dos archivos (base de mis medidas M1 y M2).
2. **Controlar el tamaño** del archivo: ya lo tengo en E1 (líneas de código de SonarQube).

**Lo que ya no es novedad:** que los smells o la deuda técnica van de la mano con el co-change; eso ya lo
demostraron ellos (y Sas et al., 2021).

**Lo nuevo de mi trabajo:** medir el co-change **por archivo y por fecha sin usar información del
futuro**, y juntarlo con E1 (cómo está el código) y E2 (historia del archivo) bajo **la misma llave**
`project + artifact_id + decision_time`.
