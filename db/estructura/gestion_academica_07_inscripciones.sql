-- Subdominio: gestión académica (issue #6)
-- Inscripción: resuelve la relación N:M entre estudiantes y cursos. Única por (estudiante, curso):
-- una reinscripción reactiva el estado en lugar de duplicar la fila.

CREATE TABLE IF NOT EXISTS inscripciones (
    id                VARCHAR(20) PRIMARY KEY,
    estudiante_id     VARCHAR(20) NOT NULL REFERENCES estudiantes(id),
    curso_id          VARCHAR(20) NOT NULL REFERENCES cursos(id),
    fecha_inscripcion DATE NOT NULL DEFAULT CURRENT_DATE,
    estado            VARCHAR(20) NOT NULL DEFAULT 'activa'
        CHECK (estado IN ('activa', 'baja', 'completada')),

    CONSTRAINT uq_inscripcion_estudiante_curso UNIQUE (estudiante_id, curso_id)
);

CREATE INDEX IF NOT EXISTS idx_inscripciones_curso ON inscripciones (curso_id);
CREATE INDEX IF NOT EXISTS idx_inscripciones_estudiante ON inscripciones (estudiante_id);
