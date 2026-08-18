-- Subdominio: evaluación y asistente (issue #7)
--
-- FK pendiente de integración (issue #5, subdominio de gestión académica #6):
--   docente_id -> docentes.id
--
-- Cada entrega tiene a lo sumo una calificación vigente (relación 1:0..1).

CREATE TABLE IF NOT EXISTS calificaciones (
    id                VARCHAR(20) PRIMARY KEY,
    entrega_id        VARCHAR(20) NOT NULL UNIQUE
        REFERENCES entregas (id) ON DELETE CASCADE,
    docente_id        VARCHAR(20) NOT NULL,   -- FK pendiente -> docentes.id
    nota              NUMERIC(4, 2)
        CHECK (nota IS NULL OR (nota >= 0 AND nota <= 10)),
    escala            VARCHAR(10) NOT NULL DEFAULT '0-10',
    feedback          TEXT,
    fecha_correccion  TIMESTAMPTZ,
    revisada          BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT chk_calificaciones_revisada CHECK (
        (revisada = FALSE) OR (revisada = TRUE AND nota IS NOT NULL AND fecha_correccion IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_calificaciones_docente ON calificaciones (docente_id);
