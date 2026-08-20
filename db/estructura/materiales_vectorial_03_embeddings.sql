-- Subdominio: materiales de estudio, modelo vectorial (issue #12).
-- Embedding de un fragmento. Se separa del fragmento (tabla material_fragmentos) porque el mismo
-- texto puede re-vectorizarse con otro modelo o versión sin tocar el contenido; el vector es un
-- índice de recuperación sobre el texto, no lo reemplaza.
--
-- Diseño normalizado (a diferencia del modelo del asistente #13, que denormaliza texto_fragmento,
-- curso_id y restringido dentro de la tabla de embeddings): acá curso y nivel de acceso se derivan
-- de materiales por JOIN, evitando duplicar y desincronizar esos datos. La unificación de ambos
-- enfoques se resuelve en la integración (issue #5); el costo/beneficio se discute en la #16.
--
-- Nota sobre la dimensión: se usa vector(8) con valores sintéticos (agrupados por tema) para que
-- el seed sea legible, igual que el modelo del asistente. En producción correspondería la
-- dimensión real del modelo de embeddings (p. ej. 384 o 1536); el diseño no cambia con ella.

CREATE TABLE IF NOT EXISTS fragmento_embeddings (
    id           VARCHAR(30) PRIMARY KEY,
    fragmento_id VARCHAR(40) NOT NULL REFERENCES material_fragmentos(id),
    modelo       VARCHAR(60) NOT NULL DEFAULT 'sintetico-8d',
    dimension    INT NOT NULL DEFAULT 8,
    version      INT NOT NULL DEFAULT 1,
    embedding    vector(8) NOT NULL,

    CONSTRAINT uq_fragmento_modelo_version UNIQUE (fragmento_id, modelo, version)
);

-- HNSW con vector_cosine_ops: búsqueda aproximada por similitud coseno, sin fase de entrenamiento
-- y con buena latencia para la consulta interactiva del asistente (mismo criterio que en #13).
CREATE INDEX IF NOT EXISTS idx_fragmento_embeddings_hnsw
    ON fragmento_embeddings USING hnsw (embedding vector_cosine_ops);
