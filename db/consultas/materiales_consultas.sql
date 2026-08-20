-- Consultas del modelo documental de materiales de estudio (issue #10).
-- Requiere gestion_academica_*.sql, materiales_01_materiales.sql y db/datos/materiales_seed.sql.

-- 1) Extracción de campos del JSONB
-- ¿Qué materiales accesibles tiene un curso y en qué formato están?
-- metadata ->> 'formato' saca un valor escalar; se excluye lo restringido para la vista del estudiante.
SELECT
    id,
    titulo,
    tipo,
    metadata ->> 'formato' AS formato,
    metadata ->> 'idioma'  AS idioma
FROM materiales
WHERE curso_id = 'cur-101'
  AND nivel_acceso <> 'restringido'
ORDER BY fecha_publicacion DESC;

-- 2) Contención sobre JSONB (aprovecha el índice GIN jsonb_path_ops)
-- ¿Qué materiales tratan un tema puntual (p. ej. normalizacion)?
-- El operador @> hace matching de contención dentro del array metadata->'temas'.
SELECT id, titulo, tipo, metadata -> 'temas' AS temas
FROM materiales
WHERE metadata @> '{"temas": ["normalizacion"]}'
ORDER BY id;

-- 3) Aplanado de un array embebido en el JSONB
-- ¿Cuáles son las preguntas frecuentes cargadas, una por fila?
-- jsonb_array_elements expande el array preguntas de la FAQ para poder listarlo o buscarlo.
SELECT
    m.id AS material_id,
    p ->> 'q' AS pregunta,
    p ->> 'a' AS respuesta
FROM materiales m,
     LATERAL jsonb_array_elements(m.metadata -> 'preguntas') AS p
WHERE m.tipo = 'faq';

-- 4) Consulta de control de seguridad
-- ¿Qué materiales están marcados como restringidos y nunca deben llegar al asistente?
-- Alimenta el filtro de acceso del RAG (issues #12 y #14): estos materiales no se vectorizan
-- para consumo del estudiante.
SELECT id, titulo, curso_id, metadata ->> 'ambito' AS ambito
FROM materiales
WHERE nivel_acceso = 'restringido'
ORDER BY curso_id;

-- 5) Agregación por tipo y curso
-- ¿Cómo se compone el material de cada curso por tipo?
-- Indicador de cobertura de contenidos para el docente.
SELECT
    curso_id,
    tipo,
    COUNT(*) AS cantidad,
    MAX(version) AS ultima_version
FROM materiales
GROUP BY curso_id, tipo
ORDER BY curso_id, tipo;
