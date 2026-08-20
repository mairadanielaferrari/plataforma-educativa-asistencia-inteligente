-- Consultas de ejemplo sobre el modelo vectorial del asistente (issue #13).
-- Integración (issue #5): las consultas de RAG se repuntaron al modelo normalizado de materiales
-- (fragmento_embeddings + material_fragmentos + materiales, #12). El curso y el nivel de acceso
-- ahora salen de materiales por JOIN, en vez de estar denormalizados en la tabla de embeddings.
-- El caché de FAQ (consulta 2) es propio del asistente y no cambia.

-- 1) Búsqueda por similitud (RAG): dado el embedding de una consulta del estudiante, traer los
-- fragmentos más relevantes DEL CURSO del estudiante y a los que tiene acceso (excluye los de
-- materiales restringidos). <=> es distancia coseno (pgvector); menor distancia = mayor similitud.
-- Pregunta: "¿qué fragmentos debería citar el asistente para responder esta consulta?"
SELECT
    f.id  AS fragmento_id,
    m.id  AS material_id,
    f.texto AS texto_fragmento,
    e.embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]' AS distancia
FROM fragmento_embeddings e
JOIN material_fragmentos f ON f.id = e.fragmento_id
JOIN materiales m ON m.id = f.material_id
WHERE m.curso_id = 'cur-101'
  AND m.nivel_acceso <> 'restringido'
ORDER BY e.embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 3;

-- 1b) La misma consulta con EXPLAIN ANALYZE, para observar el índice HNSW.
EXPLAIN ANALYZE
SELECT f.id
FROM fragmento_embeddings e
JOIN material_fragmentos f ON f.id = e.fragmento_id
JOIN materiales m ON m.id = f.material_id
WHERE m.curso_id = 'cur-101'
  AND m.nivel_acceso <> 'restringido'
ORDER BY e.embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 3;

-- 2) Caché semántico de FAQ: ¿ya existe una consulta muy similar resuelta antes?
-- Si la distancia es menor a un umbral (p. ej. 0.05), se reutiliza la respuesta_sugerida en vez
-- de volver a generar una respuesta con el modelo de lenguaje. (Propio del asistente, sin cambios.)
SELECT id, texto_consulta, respuesta_sugerida, veces_reutilizada,
       embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]' AS distancia
FROM consultas_frecuentes_embeddings
ORDER BY embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 1;

-- 3) Fragmentos que un estudiante NO debería recibir nunca como fuente, por pertenecer a un
-- material restringido (verificación del control de acceso, no un caso de uso normal).
SELECT f.id AS fragmento_id, m.id AS material_id, m.tipo AS categoria
FROM material_fragmentos f
JOIN materiales m ON m.id = f.material_id
WHERE m.nivel_acceso = 'restringido';
