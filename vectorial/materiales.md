# Modelo vectorial (pgvector): materiales de estudio

> Issue [#12](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/12).
> Implementación en [`db/estructura/materiales_vectorial_01_extension.sql`](../db/estructura/materiales_vectorial_01_extension.sql),
> [`..._02_fragmentos.sql`](../db/estructura/materiales_vectorial_02_fragmentos.sql),
> [`..._03_embeddings.sql`](../db/estructura/materiales_vectorial_03_embeddings.sql), seed en
> [`db/datos/materiales_vectorial_seed.sql`](../db/datos/materiales_vectorial_seed.sql) y consultas
> en [`db/consultas/materiales_vectorial_consultas.sql`](../db/consultas/materiales_vectorial_consultas.sql).
> Probado contra el Postgres + pgvector del `docker-compose.yml`.

## 1. Qué se vectoriza

Los **fragmentos** (chunks) de los materiales de estudio (issue #10): apuntes, guías y videos se
parten en unidades de contenido, y cada fragmento se embebe como un vector. Es lo que el asistente
recupera y cita como fuente (RAG). El contenido restringido (p. ej. la normativa `mat-099`) no debe
recuperarse para un estudiante y se filtra por acceso (ver sección 4 e issue #14).

## 2. Diseño normalizado: `material_fragmentos` + `fragmento_embeddings`

Se modela en dos tablas separadas del material:

- `material_fragmentos`: el chunk (id, `material_id` FK a `materiales`, `orden`, `texto`, `version`).
- `fragmento_embeddings`: el vector (`fragmento_id` FK, `modelo`, `dimension`, `version`, `embedding`).

Se separan el contenido y su representación vectorial porque un mismo fragmento puede
re-vectorizarse con otro modelo o versión sin tocar el texto, y porque el vector es un índice de
recuperación sobre el texto, no lo reemplaza.

**Diferencia con el modelo del asistente (#13, Sebastián):** aquel denormaliza `texto_fragmento`,
`curso_id` y `restringido` dentro de la tabla de embeddings para no hacer JOINs en el camino
caliente. Este modelo, del lado de los materiales, los mantiene normalizados: `curso_id` y
`nivel_acceso` se derivan de `materiales` por JOIN, evitando duplicar y desincronizar. Son dos
vistas del mismo dato (por eso el seed usa los mismos fragmentos y vectores); la unificación en una
sola representación, con el trade-off JOIN vs. denormalización, se decide en la integración (issue
#5) y se justifica en la #16.

## 3. Índice: HNSW

`fragmento_embeddings` usa un índice **HNSW** (`vector_cosine_ops`) para la búsqueda por similitud
coseno (`<=>`): no requiere entrenamiento previo ni un volumen mínimo, y da buena latencia para la
consulta interactiva del asistente (mismo criterio que el modelo del asistente #13).

> Nota sobre el plan: con el volumen del seed (6 vectores) el planificador ordena en memoria en vez
> de recorrer el grafo HNSW, que es correcto a esa escala; el índice se vuelve elegible cuando la
> cantidad de fragmentos por curso crece. El diseño ya lo deja creado para que la transición sea
> automática sin cambiar la consulta.

## 4. Control de acceso en la búsqueda

El filtro por `curso_id` y `nivel_acceso <> 'restringido'` se aplica **antes** del `ORDER BY
embedding <=>`, no después, para no filtrar sobre un resultado ya truncado por `LIMIT`. La búsqueda
vectorial nunca es la única barrera de seguridad: siempre se combina con el filtro relacional sobre
`materiales`. Un embedding genérico podría acercarse a contenido de otro curso o restringido, y el
JOIN a `materiales` es lo que lo impide (se retoma en la arquitectura de seguridad, issue #14).

## 5. Consultas de ejemplo

Ver [`db/consultas/materiales_vectorial_consultas.sql`](../db/consultas/materiales_vectorial_consultas.sql):

1. Recuperación RAG: los 3 fragmentos más cercanos del curso, no restringidos.
2. Auditoría: fragmentos de materiales restringidos (nunca deben devolverse).
3. Trazabilidad: material, versión y modelo de embedding de un fragmento citado.

## 6. Frontera con el asistente (integración issue #5)

`fragmento_embeddings` y `material_fragmentos` son la fuente normalizada; la tabla del asistente
`material_fragmentos_embeddings` (#13) es la representación denormalizada para RAG. En la
integración se unifican en un único modelo y el `material_id` / `fragmento_id` pasa a ser clave
foránea real hacia `materiales` y `material_fragmentos`.
