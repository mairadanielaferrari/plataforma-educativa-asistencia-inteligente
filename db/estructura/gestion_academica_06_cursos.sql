-- Subdominio: gestión académica (issue #6)
-- Curso dictado por un docente titular dentro de un período académico. Es la tabla que el
-- subdominio de evaluación/asistente referencia como cursos.id.

CREATE TABLE IF NOT EXISTS cursos (
    id                 VARCHAR(20) PRIMARY KEY,
    docente_titular_id VARCHAR(20) NOT NULL REFERENCES docentes(id),
    periodo_id         VARCHAR(20) NOT NULL REFERENCES periodos_academicos(id),
    nombre             VARCHAR(150) NOT NULL,
    descripcion        TEXT,
    cupo               INT NOT NULL DEFAULT 30 CHECK (cupo > 0),
    estado             VARCHAR(20) NOT NULL DEFAULT 'en_curso'
        CHECK (estado IN ('planificado', 'en_curso', 'finalizado'))
);

CREATE INDEX IF NOT EXISTS idx_cursos_docente ON cursos (docente_titular_id);
CREATE INDEX IF NOT EXISTS idx_cursos_periodo ON cursos (periodo_id);
