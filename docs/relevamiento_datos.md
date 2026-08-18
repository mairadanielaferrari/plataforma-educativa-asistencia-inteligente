# Relevamiento y clasificación de datos

> Issue [#2](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/2).
> Alcance: subdominio **evaluación** y **asistente** (actividades, evaluaciones, entregas,
> calificaciones, progreso académico, consultas/conversaciones del asistente, recomendaciones
> y auditoría). El subdominio de gestión académica y materiales de estudio se releva en la
> tarea de Maira Ferrari; ambas partes se integran en la issue #5.

## 1. Entidades identificadas

| Entidad | Descripción | Ejemplo |
|---|---|---|
| `actividades` | Tareas, prácticos, exámenes y proyectos que un docente publica en un curso | [`data/ejemplos/actividades.json`](../data/ejemplos/actividades.json) |
| `evaluaciones` | Instancia evaluable asociada a una actividad, con criterios y ponderación | [`data/ejemplos/evaluaciones.json`](../data/ejemplos/evaluaciones.json) |
| `entregas` | Entrega de un estudiante para una actividad, con reintentos | [`data/ejemplos/entregas.json`](../data/ejemplos/entregas.json) |
| `calificaciones` | Nota y feedback de una entrega, asignada por un docente | [`data/ejemplos/calificaciones.json`](../data/ejemplos/calificaciones.json) |
| `progreso_academico` | Métricas agregadas de avance por estudiante y curso | [`data/ejemplos/progreso_academico.json`](../data/ejemplos/progreso_academico.json) |
| `consultas_asistente` | Consulta puntual en lenguaje natural hecha al asistente | [`data/ejemplos/consultas_asistente.json`](../data/ejemplos/consultas_asistente.json) |
| `conversaciones_asistente` | Conversación completa (mensajes + fuentes usadas en cada respuesta) | [`data/ejemplos/conversaciones_asistente.json`](../data/ejemplos/conversaciones_asistente.json) |
| `recomendaciones_estudio` | Sugerencia de material o actividad generada por el asistente | [`data/ejemplos/recomendaciones_estudio.json`](../data/ejemplos/recomendaciones_estudio.json) |
| `eventos_auditoria` | Registro de acciones sensibles (cambios de nota, accesos, uso del asistente) | [`data/ejemplos/eventos_auditoria.json`](../data/ejemplos/eventos_auditoria.json) |

Entidades referenciadas pero no relevadas en este subdominio (pertenecen a gestión académica /
materiales de estudio o son transversales): `estudiantes`, `docentes`, `cursos`, `materiales`,
`roles`.

## 2. Clasificación por tipo de dato

| Entidad | Estructura | Uso | Sensibilidad / auditoría |
|---|---|---|---|
| `actividades` | Estructurado | Operacional | — |
| `evaluaciones` | Estructurado | Operacional | — |
| `entregas` | Estructurado (con adjuntos no estructurados vía `archivo_url`) | Operacional | Sensible (identifica autoría del trabajo del estudiante) |
| `calificaciones` | Estructurado | Operacional | Sensible · genera evento de auditoría en cada cambio |
| `progreso_academico` | Estructurado (agregado) | Analítico | Sensible (desempeño individual) |
| `consultas_asistente` | Semiestructurado (texto libre + metadata) | Operacional | Sensible (puede revelar dificultades del estudiante) |
| `conversaciones_asistente` | Semiestructurado (documento JSON con mensajes y fuentes embebidos) | Operacional | Sensible · registra fuentes usadas para trazabilidad |
| `recomendaciones_estudio` | Semiestructurado | Analítico | — |
| `eventos_auditoria` | Semiestructurado (campo `detalle` variable según `tipo_evento`) | Auditoría | Por definición, es el registro de auditoría del subdominio |

**No estructurado:** el contenido de los archivos adjuntos en `entregas.archivo_url` (PDFs,
código, documentos) y el texto libre de `consultas_asistente.texto_consulta` /
`conversaciones_asistente.mensajes[].texto` antes de ser vectorizado (ver issue #13, modelo
vectorial).

## 3. Riesgos identificados sobre los datos

- **Exposición cruzada entre estudiantes:** una consulta mal aislada podría devolver
  calificaciones, entregas o conversaciones de otro estudiante. Se resuelve con control de
  acceso por `estudiante_id` (ver issue #15, arquitectura y #14, seguridad de Maira).
- **Fuentes no autorizadas en RAG:** `conversaciones_asistente.mensajes[].fuentes_utilizadas`
  debe filtrar por permisos de acceso al material antes de recuperarlo (issue #13).
- **Trazabilidad de cambios de nota:** toda modificación en `calificaciones` debe dejar un
  registro correspondiente en `eventos_auditoria`, dado que es un dato sensible con impacto
  académico directo.
- **Derivación a docente:** cuando el asistente no puede resolver una consulta (por ejemplo,
  sobre una calificación puntual), debe derivarla en vez de responder con datos que no debería
  exponer (`conversaciones_asistente.derivada_a_docente`).

## 4. Datos de ejemplo

Los 9 archivos JSON en [`data/ejemplos/`](../data/ejemplos/) contienen entre 3 y 5 registros
cada uno, con IDs consistentes entre sí (`est-00N`, `act-00N`, `ent-00N`, `cal-00N`, `conv-00N`)
para poder validar relaciones y consultas de ejemplo. Los IDs de estudiantes, docentes, cursos
y materiales (`est-*`, `doc-*`, `cur-*`, `mat-*`) son referencias externas al subdominio de
gestión académica / materiales de estudio, y se reconciliarán con los datos de ejemplo de ese
subdominio en la integración (issue #5).
