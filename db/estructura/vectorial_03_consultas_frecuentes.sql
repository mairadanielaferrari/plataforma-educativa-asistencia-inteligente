-- Subdominio: asistente / RAG (issue #13)
--
-- Caché semántico de preguntas frecuentes: antes de resolver una consulta contra todos los
-- fragmentos de materiales, se compara contra consultas ya resueltas para reusar una
-- respuesta validada en vez de regenerarla (reduce costo de inferencia y latencia).
--
-- FK pendiente de integración (issue #5): curso_id -> cursos.id

CREATE TABLE IF NOT EXISTS consultas_frecuentes_embeddings (
    id                  VARCHAR(20) PRIMARY KEY,
    curso_id            VARCHAR(20),   -- FK pendiente -> cursos.id (NULL = pregunta general)
    texto_consulta      TEXT NOT NULL,
    respuesta_sugerida  TEXT NOT NULL,
    veces_reutilizada   INT NOT NULL DEFAULT 0,
    embedding           VECTOR(8) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_consultas_frecuentes_embedding_hnsw
    ON consultas_frecuentes_embeddings USING hnsw (embedding vector_cosine_ops);
