-- Consultas de ejemplo sobre el modelo vectorial del asistente (issue #13).
-- Requiere haber corrido vectorial_01/02/03 y el seed correspondiente.

-- 1) Búsqueda por similitud (RAG): dado el embedding de una consulta del estudiante,
-- traer los fragmentos más relevantes DEL CURSO del estudiante y a los que tiene acceso
-- (control de acceso: excluye restringido = TRUE). <=> es distancia coseno (pgvector);
-- menor distancia = mayor similitud.
-- Pregunta: "¿qué fragmentos debería citar el asistente para responder esta consulta?"
SELECT id, material_id, fragmento_id, texto_fragmento,
       embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]' AS distancia
FROM material_fragmentos_embeddings
WHERE curso_id = 'cur-101'
  AND restringido = FALSE
ORDER BY embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 3;

-- 1b) La misma consulta con EXPLAIN ANALYZE, para justificar el índice HNSW.
EXPLAIN ANALYZE
SELECT id, fragmento_id
FROM material_fragmentos_embeddings
WHERE curso_id = 'cur-101'
  AND restringido = FALSE
ORDER BY embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 3;

-- 2) Caché semántico de FAQ: ¿ya existe una consulta muy similar resuelta antes?
-- Si la distancia es menor a un umbral (p. ej. 0.05), se reutiliza la respuesta_sugerida en
-- vez de volver a generar una respuesta con el modelo de lenguaje.
SELECT id, texto_consulta, respuesta_sugerida, veces_reutilizada,
       embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]' AS distancia
FROM consultas_frecuentes_embeddings
ORDER BY embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 1;

-- 3) Fragmentos restringidos que un estudiante NO debería recibir nunca como fuente
-- (verificación del control de acceso, no un caso de uso normal del asistente).
SELECT id, material_id, categoria
FROM material_fragmentos_embeddings
WHERE restringido = TRUE;
