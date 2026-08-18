# Modelo vectorial (pgvector): RAG del asistente

> Issue [#13](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/13).
> Depende de #7 y #11 (ambas cerradas). Implementación en
> [`db/estructura/vectorial_01_extension.sql`](../db/estructura/vectorial_01_extension.sql),
> [`..._02_material_fragmentos.sql`](../db/estructura/vectorial_02_material_fragmentos.sql),
> [`..._03_consultas_frecuentes.sql`](../db/estructura/vectorial_03_consultas_frecuentes.sql),
> seed en [`db/datos/vectorial_asistente_seed.sql`](../db/datos/vectorial_asistente_seed.sql) y
> consultas en [`db/consultas/vectorial_asistente_consultas.sql`](../db/consultas/vectorial_asistente_consultas.sql).
> Todo corrido contra el Postgres + pgvector del `docker-compose.yml` del repo.

## 1. Qué se vectoriza

| Colección | Elemento vectorizado | Por qué |
|---|---|---|
| `material_fragmentos_embeddings` | Fragmentos (chunks) del contenido de materiales de estudio: apuntes, guías prácticas, normativa | Es lo que el asistente recupera y cita como fuente para responder una consulta (RAG). |
| `consultas_frecuentes_embeddings` | Texto de consultas de estudiantes ya resueltas (FAQ) | Caché semántico: si una consulta nueva es casi idéntica a una ya respondida, se reutiliza la respuesta en vez de volver a generar una con el modelo de lenguaje. |

La consulta del estudiante en sí **no se persiste vectorizada**: se embebe al vuelo en el
momento de la consulta y se usa solo para comparar contra estas dos colecciones (no tiene
sentido guardar un índice de "consultas históricas vectorizadas" salvo para el caso de FAQ de
arriba, que sí se conserva por su valor de reutilización).

> **Nota sobre la dimensión:** los ejemplos usan `VECTOR(8)` con valores sintéticos (no
> generados por un modelo real) para que el seed sea legible en el repositorio. En producción
> correspondería la dimensión real del modelo de embeddings elegido (p. ej. 384 para
> `all-MiniLM-L6-v2`, 1536 para `text-embedding-3-small`); el resto del diseño (metadatos,
> índice, filtros de acceso) no cambia con la dimensión.

## 2. Metadatos almacenados junto al vector

- `material_fragmentos_embeddings`: `material_id`, `fragmento_id`, `curso_id`, `categoria`
  (apunte/faq/normativa/guia_practica), `texto_fragmento` (el texto original, para poder
  citarlo tal cual), `restringido`, `version`.
- `consultas_frecuentes_embeddings`: `curso_id`, `texto_consulta`, `respuesta_sugerida`,
  `veces_reutilizada`.

Estos metadatos cumplen dos roles: **filtrado previo a la búsqueda** (`curso_id`,
`restringido`) y **trazabilidad de la respuesta** (poder mostrar qué fragmento exacto,
de qué documento y versión, sustenta cada respuesta del asistente — el mismo
`fragmento_id`/`documento_id` que ya se registra embebido en
`conversaciones_asistente.mensajes[].fuentes_utilizadas`, ver [`nosql/asistente.md`](../nosql/asistente.md)).

## 3. Vínculo con los datos originales

`material_fragmentos_embeddings.material_id` + `fragmento_id` referencian el material
completo del subdominio de materiales de estudio (issue #10/#12, pendiente de integración en
#5): el vector nunca reemplaza al dato original, es un índice de recuperación sobre él. El
texto del fragmento se duplica en `texto_fragmento` (decisión de desnormalización deliberada)
para no tener que ir a buscar el documento original en el camino caliente de responder una
consulta; el costo es mantenerlo sincronizado si el material fuente se edita (se revectoriza
y se actualiza `version`).

## 4. Consultas por similitud esperadas

1. **Recuperación RAG**: dado el embedding de la consulta del estudiante, traer los `N`
   fragmentos más cercanos (distancia coseno) **del curso del estudiante** y **no
   restringidos**.
2. **Caché de FAQ**: ¿existe una consulta ya resuelta casi idéntica? Si la distancia está por
   debajo de un umbral (p. ej. 0.05), se reutiliza `respuesta_sugerida` sin invocar al modelo
   de lenguaje.
3. **Auditoría de contenido restringido**: listar fragmentos marcados `restringido = TRUE`,
   para verificar que nunca se cuelen como fuente (consulta de control, no de uso normal).

Las tres están implementadas en
[`vectorial_asistente_consultas.sql`](../db/consultas/vectorial_asistente_consultas.sql).

## 5. Índice: HNSW sobre IVFFlat

Se eligió **HNSW** (`vector_cosine_ops`) para ambas colecciones en vez de IVFFlat porque:

- No requiere una fase de "entrenamiento" (`ANALYZE`) ni un volumen mínimo de filas por lista
  para dar buen recall — relevante porque el volumen de fragmentos por curso puede ser chico
  al principio (un curso recién cargado).
- La consulta es interactiva (el estudiante espera la respuesta del asistente en el momento),
  y HNSW ofrece mejor latencia de búsqueda a costa de más memoria y un build algo más lento,
  trade-off aceptable para este caso de uso.
- IVFFlat sería preferible si el volumen de fragmentos creciera mucho (millones) y la memoria
  fuera la restricción dominante — no es el escenario esperado para materiales de un curso
  (ver `docs/relevamiento_datos.md` y la futura issue #15 de escalabilidad).

### Ejemplo real con `EXPLAIN ANALYZE`

```sql
EXPLAIN ANALYZE
SELECT id, fragmento_id
FROM material_fragmentos_embeddings
WHERE curso_id = 'cur-101'
  AND restringido = FALSE
ORDER BY embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 3;
```

```
Limit  (cost=8.17..8.18 rows=1 width=144) (actual time=0.013..0.013 rows=3 loops=1)
  ->  Sort  (cost=8.17..8.18 rows=1 width=144) (actual time=0.012..0.013 rows=3 loops=1)
        Sort Key: ((embedding <=> '[0.86,0.14,0.07,0.02,0.01,0,0,0]'::vector))
        Sort Method: quicksort  Memory: 25kB
        ->  Index Scan using idx_material_fragmentos_curso on material_fragmentos_embeddings
              (cost=0.14..8.16 rows=1 width=144) (actual time=0.007..0.008 rows=4 loops=1)
              Index Cond: ((curso_id)::text = 'cur-101'::text)
              Filter: (NOT restringido)
              Rows Removed by Filter: 1
Planning Time: 0.048 ms
Execution Time: 0.025 ms
```

**Lectura honesta del plan:** con solo 6 filas cargadas, el planificador decide que filtrar
por el índice B-tree de `curso_id` y ordenar en memoria (`quicksort`) es más barato que usar
el índice `idx_material_fragmentos_embedding_hnsw` — es la decisión correcta a esta escala. El
índice HNSW empieza a ser elegido por el planner cuando el volumen de filas por curso crece lo
suficiente como para que un escaneo + sort sea más caro que un recorrido aproximado del grafo
HNSW (miles de fragmentos en adelante). Esto se retoma en la issue #15 (escalabilidad): el
diseño ya deja el índice creado para que la transición sea automática, sin cambiar la consulta.

Los resultados de similitud sí son correctos semánticamente: para una consulta cercana al
cluster "normalización", el ranking devuelve `frag-002` y `frag-001` (ambos sobre
normalización) antes que `frag-003` (sobre claves foráneas), y el caché de FAQ devuelve
`faq-001` ("¿Cómo se calcula la forma normal de una tabla?") como la pregunta más parecida.

## 6. Restricciones de acceso y riesgos

- **Filtro obligatorio por curso y por `restringido`** en toda búsqueda de RAG: un estudiante
  nunca debe recibir como fuente un fragmento de un curso al que no pertenece, ni contenido
  marcado como restringido (p. ej. `frag-006`, normativa interna de uso exclusivo docente).
  Este filtro debe aplicarse **antes** del `ORDER BY embedding <=>`, no después, para no
  filtrar sobre un resultado ya truncado por `LIMIT`.
- **Riesgo de fuga por similitud semántica**: aunque el filtro de `curso_id`/`restringido` sea
  correcto, un embedding muy genérico podría igual recuperar contenido de otro curso si no se
  aplica el filtro de metadatos — la búsqueda vectorial *nunca* debe ser la única barrera de
  seguridad, siempre debe combinarse con el filtro relacional (ver issue #15, arquitectura de
  seguridad).
- **Desactualización**: si un material se edita o se da de baja y no se revectoriza, el
  asistente puede citar una versión vieja como si fuera vigente. `version` en
  `material_fragmentos_embeddings` existe para poder detectar y descartar fragmentos
  obsoletos.
- **Trazabilidad**: toda respuesta que cite un fragmento debe quedar registrada con
  `documento_id`/`fragmento_id` en `conversaciones_asistente.mensajes[].fuentes_utilizadas`
  (ya implementado en #11), de forma de poder auditar qué información concreta usó el
  asistente para cada respuesta.
