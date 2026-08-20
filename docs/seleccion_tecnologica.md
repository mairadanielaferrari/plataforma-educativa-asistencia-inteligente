# Selección tecnológica (justificación)

> Issue [#16](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/16), compartida.
> Justifica la decisión ya adoptada e implementada en todo el proyecto: un único **PostgreSQL
> multi-modelo** (relacional + documental JSONB + vectorial pgvector) para los cuatro
> subdominios (gestión académica #6, materiales #10/#12, evaluación #7/#11 y asistente #13).

## 1. La decisión

No se separó la solución en varios motores especializados (un relacional, un documental tipo
MongoDB, un vector store dedicado). Se usa **un solo PostgreSQL** con tres representaciones
conviviendo: tablas relacionales, columnas `JSONB` y columnas `vector` (pgvector). La
justificación no es "porque lo vimos en la materia": es que, para el volumen y los patrones de
consulta de este caso, separar motores agrega complejidad operativa y rompe consistencia
transaccional sin una ganancia de rendimiento que el caso necesite.

## 2. Justificación por componente

### 2.1 Relacional (núcleo académico y evaluación)

`usuarios`, `estudiantes`, `docentes`, `cursos`, `inscripciones` (#6); `actividades`,
`evaluaciones`, `entregas`, `calificaciones`, `progreso_academico` (#7).

- **Tipo y estructura de datos:** altamente estructurado, mismo esquema para todas las filas,
  con relaciones 1:N y 1:0..1 claras (curso→actividad, entrega→calificación).
- **Consistencia requerida:** alta. Una calificación no puede existir sin poder auditarse
  (issue #7/#14: cambio de nota + evento de auditoría en la misma transacción); una entrega no
  puede duplicar `(estudiante, actividad, intento)`. Esto pide ACID real, no eventual
  consistency.
- **Patrones de consulta:** JOINs entre pocas tablas, agregaciones (`AVG`, `HAVING`),
  funciones de ventana para ranking (#9) — el álgebra relacional es la herramienta hecha para
  esto.
- **Volumen esperado:** una institución educativa (miles de estudiantes, decenas de miles de
  entregas por período), no un caso de escala masiva que justifique un motor distribuido.
- **Alternativa descartada — documental puro:** modelar entregas/calificaciones como
  documentos habría obligado a duplicar datos de estudiante/curso en cada entrega y a resolver
  a mano una integridad que el relacional da gratis (FK, `UNIQUE`, `CHECK`).

### 2.2 Documental / JSONB (contenido variable)

`materiales.metadata` (#10), `conversaciones_asistente.mensajes` y `eventos_asistente.detalle`
(#11).

- **Tipo y estructura de datos:** semiestructurado y **variable según el tipo**: un video
  tiene duración y URL, una normativa tiene vigencia, un evento de auditoría tiene un
  `detalle` distinto según `tipo_evento`. Forzar esto a columnas fijas generaría decenas de
  columnas casi siempre `NULL` o una migración por cada tipo nuevo.
- **Patrón de consulta:** se lee/escribe el documento casi siempre completo (una conversación,
  un material), no campo por campo — encaja con un documento, no con una fila normalizada en
  varias tablas.
- **Alternativa descartada — MongoDB separado:** hubiera resuelto la flexibilidad del esquema,
  pero a costa de romper la transacción entre, por ejemplo, un material y su curso (`cursos`
  vive en Postgres), y de sumar un segundo motor a desplegar, respaldar y monitorear. JSONB en
  Postgres da la misma flexibilidad de esquema sin ese costo, con índices GIN (`jsonb_path_ops`)
  para consultar dentro del documento cuando hace falta.

### 2.3 Vectorial (pgvector, RAG)

`fragmento_embeddings` (#12), `material_fragmentos_embeddings`* y `consultas_frecuentes_embeddings`
(#13). *(unificado al modelo normalizado de #12 en la integración #5).*

- **Tipo de dato y patrón de consulta:** búsqueda por similitud semántica sobre embeddings de
  fragmentos de materiales — es exactamente el caso de uso de una base vectorial.
- **Volumen esperado:** fragmentos por curso en el orden de cientos o pocos miles, no
  cientos de millones — la escala de un vector store dedicado (Pinecone, Weaviate, Milvus) no
  se justifica.
- **Seguridad y control de acceso:** la ventaja decisiva de pgvector acá es poder hacer `JOIN`
  directo entre el vector y `materiales.nivel_acceso` dentro de la misma consulta (ver
  `vectorial/materiales.md` y `vectorial/asistente.md`). Con un vector store separado, ese
  filtro de acceso tendría que reimplementarse fuera de la base de datos, duplicando la lógica
  de seguridad y abriendo una ventana a que se desincronice (exactamente el riesgo de
  "recuperar material no autorizado" que señala la consigna).
- **Alternativa descartada — vector store dedicado:** mejor rendimiento a escala masiva, pero
  para este volumen agrega latencia de red, un sistema más a operar, y pierde la garantía de
  filtrar por acceso en la misma consulta.

## 3. Seguridad y control de acceso (transversal)

Row-Level Security nativo de PostgreSQL (#14) permite tener **un solo punto** de políticas de
aislamiento (`app.estudiante_id`) que aplica igual a tablas relacionales y, por extensión, al
filtro de acceso que usa la búsqueda vectorial. Repartir los datos en varios motores hubiera
significado reimplementar el control de acceso en cada uno, con el riesgo de que queden
inconsistentes entre sí.

## 4. Complejidad operativa

Un solo motor significa un solo `docker-compose.yml`, un solo backup, una sola versión a
actualizar. Para un equipo de dos personas (y, por extensión, para el equipo de datos chico de
una institución educativa real) eso pesa tanto como el rendimiento: tres sistemas distintos
(relacional + documental + vectorial) multiplican el esfuerzo de despliegue y monitoreo sin
que el caso de uso lo necesite a esta escala.

## 5. Escalabilidad

El análisis detallado está en `arquitectura_evaluacion_asistente.md` (#15) y en
`vectorial/asistente.md` (#13): los índices (HNSW, GIN, B-tree) y el candidato a particionado
(`conversaciones_asistente`/`eventos_asistente` por fecha) ya dejan margen de crecimiento sin
cambiar de motor. Si el volumen de fragmentos vectorizados creciera a un orden muy superior al
esperado, la migración de `fragmento_embeddings` a un servicio vectorial dedicado quedaría como
paso siguiente natural (arquitectura híbrida), no como necesidad de partida.

## 6. Cuadro comparativo (alternativas descartadas)

| Alternativa | Ventaja que ofrece | Por qué no se eligió para este caso |
|---|---|---|
| MongoDB para materiales/asistente | Esquema flexible nativo, buena ergonomía de documentos | Pierde transacciones ACID con las tablas relacionales relacionadas (curso, estudiante); motor adicional a operar |
| Motor de grafos (Neo4j) para relaciones estudiante-curso-material | Recorridos de relaciones muy expresivos | El caso no requiere navegación de grafo profunda (2-3 saltos como máximo); un JOIN relacional alcanza |
| Vector store dedicado (Pinecone/Weaviate/Milvus) | Mejor rendimiento a escala masiva (cientos de millones de vectores) | Escala no justificada por el volumen esperado; pierde el filtro de acceso por JOIN nativo; suma latencia de red y otro sistema a mantener |
| Data Warehouse separado para `progreso_academico` | Mejor para analítica histórica masiva y consultas OLAP pesadas | El volumen actual no lo justifica; queda como paso de escalabilidad futuro (#15) |

## 7. Conclusión

La elección no es "PostgreSQL porque sí": es que, componente por componente, cada alternativa
especializada resuelve un problema de escala o expresividad que **este caso no tiene todavía**,
a costa de una complejidad operativa y de consistencia que sí tiene un costo real desde el
día uno. PostgreSQL multi-modelo cubre los tres patrones de acceso (transaccional, documental,
similitud) con un solo motor, y deja un camino de escalabilidad claro (documentado en #15) para
cuando el volumen lo justifique.
