-- Subdominio: evaluación y asistente (issue #7)
-- Una actividad evaluable tiene a lo sumo una evaluación asociada (relación 1:0..1).

CREATE TABLE IF NOT EXISTS evaluaciones (
    id                    VARCHAR(20) PRIMARY KEY,
    actividad_id          VARCHAR(20) NOT NULL UNIQUE
        REFERENCES actividades (id) ON DELETE CASCADE,
    titulo                VARCHAR(200) NOT NULL,
    tipo                  VARCHAR(30) NOT NULL
        CHECK (tipo IN ('parcial', 'practico_evaluable', 'proyecto_final', 'cuestionario')),
    modalidad             VARCHAR(20) NOT NULL
        CHECK (modalidad IN ('individual', 'grupal')),
    fecha                 DATE NOT NULL,
    ponderacion           NUMERIC(4, 2) NOT NULL
        CHECK (ponderacion > 0 AND ponderacion <= 1),
    criterios_evaluacion  TEXT[] NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_evaluaciones_actividad ON evaluaciones (actividad_id);
