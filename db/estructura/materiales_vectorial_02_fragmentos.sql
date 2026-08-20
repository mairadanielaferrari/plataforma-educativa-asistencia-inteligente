-- Subdominio: materiales de estudio, modelo vectorial (issue #12).
-- Fragmento (chunk) de un material: la unidad de contenido que se recupera y se cita en el RAG.
-- Se separa del material (JSONB, #10) porque un material se parte en varios fragmentos y cada
-- fragmento se vectoriza por separado. material_id es FK real a materiales (#10).

CREATE TABLE IF NOT EXISTS material_fragmentos (
    id          VARCHAR(40) PRIMARY KEY,   -- p. ej. mat-014#frag-1
    material_id VARCHAR(20) NOT NULL REFERENCES materiales(id),
    orden       INT NOT NULL,
    texto       TEXT NOT NULL,
    version     INT NOT NULL DEFAULT 1,

    CONSTRAINT uq_material_fragmento_orden UNIQUE (material_id, orden)
);

CREATE INDEX IF NOT EXISTS idx_material_fragmentos_material ON material_fragmentos (material_id);
