-- Consultas del modelo vectorial de materiales (issue #12).
-- Requiere gestion_academica_*.sql, materiales_01_materiales.sql + seed,
-- materiales_vectorial_0{1,2,3}_*.sql y db/datos/materiales_vectorial_seed.sql.
-- El vector de la consulta se pasa embebido (en producción lo genera el servicio de embeddings).

-- 1) Recuperación RAG con filtro de acceso
-- Dado el embedding de una consulta, traer los 3 fragmentos mas cercanos (distancia coseno <=>)
-- del curso del estudiante y NO restringidos. El filtro por curso y nivel_acceso se aplica ANTES
-- del ORDER BY, para no recuperar contenido de otro curso ni material restringido. curso_id y
-- nivel_acceso salen de materiales por JOIN (no estan denormalizados en la tabla de embeddings).
SELECT
    f.id AS fragmento_id,
    m.id AS material_id,
    m.titulo,
    f.texto,
    ROUND((e.embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]')::numeric, 4) AS distancia
FROM fragmento_embeddings e
JOIN material_fragmentos f ON f.id = e.fragmento_id
JOIN materiales m ON m.id = f.material_id
WHERE m.curso_id = 'cur-101'
  AND m.nivel_acceso <> 'restringido'
ORDER BY e.embedding <=> '[0.86,0.14,0.07,0.02,0.01,0.00,0.00,0.00]'
LIMIT 3;

-- 2) Control: fragmentos de materiales restringidos
-- ¿Qué fragmentos pertenecen a materiales restringidos y por lo tanto nunca deben devolverse como
-- fuente a un estudiante? Consulta de auditoría de seguridad (issue #14), no de uso normal.
SELECT f.id AS fragmento_id, m.id AS material_id, m.titulo, m.nivel_acceso
FROM material_fragmentos f
JOIN materiales m ON m.id = f.material_id
WHERE m.nivel_acceso = 'restringido';

-- 3) Trazabilidad de una respuesta
-- Para un fragmento citado, ¿de qué material, versión y autor proviene? Permite mostrar y auditar
-- la fuente exacta de cada afirmación del asistente.
SELECT
    f.id AS fragmento_id,
    m.titulo AS material,
    m.version AS version_material,
    e.modelo AS modelo_embedding,
    e.version AS version_embedding
FROM fragmento_embeddings e
JOIN material_fragmentos f ON f.id = e.fragmento_id
JOIN materiales m ON m.id = f.material_id
WHERE f.id = 'mat-014#frag-1';
