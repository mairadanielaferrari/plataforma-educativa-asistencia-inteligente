-- Subdominio: evaluación y asistente (issue #7)
--
-- FK pendiente de integración (issue #5, subdominio de gestión académica #6):
--   estudiante_id -> estudiantes.id

CREATE TABLE IF NOT EXISTS entregas (
    id                    VARCHAR(20) PRIMARY KEY,
    estudiante_id         VARCHAR(20) NOT NULL,   -- FK pendiente -> estudiantes.id
    actividad_id          VARCHAR(20) NOT NULL
        REFERENCES actividades (id) ON DELETE CASCADE,
    fecha_entrega         TIMESTAMPTZ NOT NULL,
    intento               SMALLINT NOT NULL DEFAULT 1 CHECK (intento > 0),
    archivo_url           TEXT,
    estado                VARCHAR(20) NOT NULL
        CHECK (estado IN ('entregado', 'reentregado', 'pendiente', 'no_entregado')),
    fuera_de_termino      BOOLEAN NOT NULL DEFAULT FALSE,
    comentario_estudiante TEXT,

    CONSTRAINT uq_entregas_estudiante_actividad_intento
        UNIQUE (estudiante_id, actividad_id, intento)
);

CREATE INDEX IF NOT EXISTS idx_entregas_estudiante ON entregas (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_entregas_actividad ON entregas (actividad_id);
