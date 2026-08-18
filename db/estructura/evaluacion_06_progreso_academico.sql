-- Subdominio: evaluación y asistente (issue #7)
--
-- FK pendientes de integración (issue #5, subdominio de gestión académica #6):
--   estudiante_id -> estudiantes.id
--   curso_id      -> cursos.id
--
-- Tabla analítica (recalculada periódicamente, ver arquitectura #15): un registro por
-- estudiante, curso y período.

CREATE TABLE IF NOT EXISTS progreso_academico (
    id                        VARCHAR(20) PRIMARY KEY,
    estudiante_id             VARCHAR(20) NOT NULL,   -- FK pendiente -> estudiantes.id
    curso_id                  VARCHAR(20) NOT NULL,   -- FK pendiente -> cursos.id
    periodo                   VARCHAR(10) NOT NULL,
    actividades_completadas   SMALLINT NOT NULL DEFAULT 0 CHECK (actividades_completadas >= 0),
    actividades_totales       SMALLINT NOT NULL DEFAULT 0 CHECK (actividades_totales >= 0),
    promedio_notas            NUMERIC(4, 2) CHECK (promedio_notas IS NULL OR (promedio_notas >= 0 AND promedio_notas <= 10)),
    porcentaje_avance         NUMERIC(5, 2) CHECK (porcentaje_avance >= 0 AND porcentaje_avance <= 100),
    ultima_actividad          DATE,
    en_riesgo                 BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_progreso_estudiante_curso_periodo UNIQUE (estudiante_id, curso_id, periodo),
    CONSTRAINT chk_progreso_completadas CHECK (actividades_completadas <= actividades_totales)
);

CREATE INDEX IF NOT EXISTS idx_progreso_estudiante ON progreso_academico (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_progreso_curso ON progreso_academico (curso_id);
