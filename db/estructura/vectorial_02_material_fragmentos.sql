-- Subdominio: asistente / RAG (issue #13)
--
-- Fragmentos de materiales de estudio vectorizados para la recuperación semántica del
-- asistente (RAG). Cada fila es un chunk de un documento del subdominio de materiales de
-- estudio (issue #10/#12, Maira) con su embedding, el texto original (para poder citarlo tal
-- cual como "fuente" en conversaciones_asistente) y los metadatos necesarios para filtrar por
-- acceso antes de devolver un resultado al estudiante.
--
-- Dimensión del vector: se usa VECTOR(8) para que el ejemplo sea legible en el repositorio.
-- En producción correspondería a la dimensión real del modelo de embeddings elegido
-- (p. ej. 384 para all-MiniLM-L6-v2, 1536 para text-embedding-3-small); ver vectorial/asistente.md.
--
-- FK pendiente de integración (issue #5, subdominio de materiales de estudio):
--   material_id -> materiales.id
--   curso_id    -> cursos.id

CREATE TABLE IF NOT EXISTS material_fragmentos_embeddings (
    id                VARCHAR(20) PRIMARY KEY,
    material_id       VARCHAR(20) NOT NULL,   -- FK pendiente -> materiales.id
    fragmento_id      VARCHAR(30) NOT NULL,
    curso_id          VARCHAR(20),            -- FK pendiente -> cursos.id
    categoria         VARCHAR(30) NOT NULL
        CHECK (categoria IN ('apunte', 'faq', 'normativa', 'guia_practica')),
    texto_fragmento   TEXT NOT NULL,
    restringido       BOOLEAN NOT NULL DEFAULT FALSE,
    version           SMALLINT NOT NULL DEFAULT 1,
    embedding         VECTOR(8) NOT NULL,

    CONSTRAINT uq_material_fragmentos_material_fragmento UNIQUE (material_id, fragmento_id)
);

CREATE INDEX IF NOT EXISTS idx_material_fragmentos_curso ON material_fragmentos_embeddings (curso_id);
CREATE INDEX IF NOT EXISTS idx_material_fragmentos_restringido ON material_fragmentos_embeddings (restringido);

-- HNSW: buen recall/latencia sin necesidad de "entrenar" el índice con datos previos
-- (a diferencia de IVFFlat, que requiere ANALYZE y un volumen mínimo de filas por lista para
-- ser efectivo). Se prioriza HNSW porque el volumen esperado de fragmentos por curso es
-- moderado y la consulta es interactiva (el estudiante espera respuesta en tiempo real).
CREATE INDEX IF NOT EXISTS idx_material_fragmentos_embedding_hnsw
    ON material_fragmentos_embeddings USING hnsw (embedding vector_cosine_ops);
