# Modelo documental (JSONB): asistente

> Issue [#11](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/11).
> Depende de #7 (ya cerrada). Implementación real en
> [`db/estructura/evaluacion_07_conversaciones_asistente.sql`](../db/estructura/evaluacion_07_conversaciones_asistente.sql)
> y [`..._08_eventos_asistente.sql`](../db/estructura/evaluacion_08_eventos_asistente.sql), datos
> de ejemplo en [`db/datos/nosql_asistente_seed.sql`](../db/datos/nosql_asistente_seed.sql) y
> consultas en [`db/consultas/nosql_asistente_consultas.sql`](../db/consultas/nosql_asistente_consultas.sql).
> Todo probado contra el Postgres del `docker-compose.yml` del repo.

## 1. Por qué documental y no puramente relacional

Las conversaciones del asistente tienen una estructura variable (cantidad de mensajes,
presencia o no de fuentes citadas, campos que pueden crecer con el tiempo: p. ej. agregar
`confianza_respuesta` a futuro) y se leen casi siempre completas, no mensaje por mensaje. Eso
encaja mejor con un documento que con una tabla `mensajes` normalizada: evita joins para
reconstruir el hilo de la conversación y permite evolucionar el esquema de un mensaje sin
migraciones.

Se implementa **sobre PostgreSQL** (no una base documental separada como MongoDB), usando
columnas `JSONB`, en línea con la tecnología multi-modelo elegida por el equipo (ver README y
la justificación de la issue #16): mantiene una única base de datos, transacciones ACID entre
la parte relacional y la documental, y `pgvector` disponible en el mismo motor para el modelo
vectorial (#13).

## 2. Colecciones (tablas con columna JSONB)

### `conversaciones_asistente`

Documento raíz de una interacción estudiante-asistente.

- **Columnas promovidas** (fuera del JSONB, porque se filtran/agrupan en casi toda consulta):
  `id`, `estudiante_id`, `curso_id`, `fecha_inicio`, `fecha_fin`, `canal`,
  `calificacion_satisfaccion`, `derivada_a_docente`.
- **Documento `mensajes` (JSONB, array)**: cada elemento es un mensaje con `rol`
  (`estudiante`/`asistente`), `texto`, `timestamp` y, si es del asistente,
  `fuentes_utilizadas` (array embebido de `{documento_id, fragmento_id, similitud}`). La cita
  guarda solo la **referencia** al material (`documento_id`/`fragmento_id`), no una copia de su
  título ni de su contenido: el título se resuelve contra `materiales` cuando hace falta mostrarlo.

```json
{
  "id": "conv-001",
  "estudiante_id": "est-001",
  "curso_id": "cur-101",
  "mensajes": [
    { "rol": "estudiante", "texto": "¿Cómo se calcula la 3FN?", "timestamp": "2026-04-05T21:03:00-03:00" },
    {
      "rol": "asistente",
      "texto": "Una tabla está en 3FN si...",
      "timestamp": "2026-04-05T21:03:22-03:00",
      "fuentes_utilizadas": [
        { "documento_id": "mat-014", "fragmento_id": "mat-014#frag-3", "similitud": 0.87 }
      ]
    }
  ]
}
```

### `eventos_asistente`

Log de eventos del asistente (uso, derivación a docente, y a futuro bloqueos por fuente no
autorizada). El campo `detalle` es JSONB porque su forma cambia según `tipo_evento`
(`uso_asistente` guarda `documentos`/`fuentes_citadas`; `derivacion_a_docente` guarda
`motivo`/`docente_id`).

## 3. Embebido vs. referencia

| Relación | Decisión | Motivo |
|---|---|---|
| Conversación → Mensajes | **Embebido** | Sin existencia propia fuera de la conversación; siempre se leen juntos; evita N+1 al reconstruir el hilo. |
| Mensaje → Fuentes utilizadas | **Embebido** | Idem: la fuente citada es parte del contexto de esa respuesta puntual, no se consulta de forma aislada. |
| Fuente utilizada → Material | **Referencia** (`documento_id`) | El material (apunte, FAQ) pertenece al subdominio de materiales de estudio (#10, Maira), tiene ciclo de vida propio y puede ser editado o eliminado; por eso la cita guarda **solo** `documento_id`/`fragmento_id` (más `similitud`), nunca una copia del título o del contenido: así no puede quedar desactualizada respecto de `materiales`. El título se resuelve con un JOIN a `materiales` cuando se necesita mostrarlo (ver consulta 2). |
| Conversación → Estudiante / Curso | **Referencia** (`estudiante_id`, `curso_id`) | Pertenecen al subdominio de gestión académica (#6); son entidades con identidad propia consultadas desde muchos otros lugares. |
| Evento → Conversación | **Referencia** (`conversacion_id`) | Un evento puede no tener conversación asociada (p. ej. errores de indexación de documentos), y la conversación ya existe como entidad independiente. |

Esta misma lógica ya se había anticipado como decisión de diseño en
[`modelo_conceptual_evaluacion_asistente.md`](modelo_conceptual_evaluacion_asistente.md#5-decisión-de-diseño-consultaasistente-vs-conversacionasistente):
`ConsultaAsistente` (relacional, pendiente de implementar en el subdominio evaluación si el
análisis de consultas lo requiere) queda como proyección liviana para agregaciones SQL, mientras
que `conversaciones_asistente` es la fuente de verdad semiestructurada.

## 4. Índices

- `idx_conversaciones_estudiante`, `idx_conversaciones_curso`: filtros habituales ("mis
  conversaciones", "conversaciones del curso X").
- `idx_conversaciones_mensajes_gin` (GIN sobre `mensajes` con `jsonb_path_ops`): soporta
  consultas de contención (`@>`) como "¿qué conversaciones citaron el documento mat-014?" sin
  escanear y parsear el JSONB completo de cada fila.
- `idx_eventos_asistente_tipo`, `idx_eventos_asistente_conversacion`: filtros por tipo de
  evento y por conversación.
- `idx_eventos_asistente_detalle_gin`: mismo criterio que en conversaciones, para consultar
  dentro de `detalle` (p. ej. eventos que mencionan un `docente_id` puntual).

## 5. Consultas de ejemplo

Ver [`db/consultas/nosql_asistente_consultas.sql`](../db/consultas/nosql_asistente_consultas.sql),
probadas contra los datos de [`db/datos/nosql_asistente_seed.sql`](../db/datos/nosql_asistente_seed.sql):

1. Traer una conversación completa por `id`.
2. Aplanar fuentes citadas por el asistente (`jsonb_array_elements`) con su similitud.
3. Conversaciones que citaron un documento específico como fuente (`@>`, aprovecha el índice GIN).
4. Cantidad de conversaciones derivadas a un docente, agrupadas por curso.
5. Eventos del asistente en un rango de fechas, con su `detalle` variable.
