-- Subdominio: evaluación y asistente (issue #7)
--
-- FK pendientes de integración (issue #5, tablas del subdominio de gestión académica #6):
--   curso_id    -> cursos.id
--   docente_id  -> docentes.id
-- Se declaran como columnas sin REFERENCES hasta que exista el schema de gestión académica;
-- agregar los ALTER TABLE ... ADD CONSTRAINT correspondientes en la integración.

CREATE TABLE IF NOT EXISTS actividades (
    id                  VARCHAR(20) PRIMARY KEY,
    curso_id            VARCHAR(20) NOT NULL,   -- FK pendiente -> cursos.id
    docente_id          VARCHAR(20) NOT NULL,   -- FK pendiente -> docentes.id
    titulo              VARCHAR(200) NOT NULL,
    tipo                VARCHAR(30) NOT NULL
        CHECK (tipo IN ('practico', 'examen_parcial', 'foro', 'cuestionario', 'proyecto_final')),
    fecha_publicacion   DATE NOT NULL,
    fecha_limite        TIMESTAMPTZ NOT NULL,
    descripcion         TEXT,
    estado              VARCHAR(20) NOT NULL DEFAULT 'vigente'
        CHECK (estado IN ('vigente', 'cerrado', 'archivado')),
    permite_reentrega   BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT chk_actividades_fechas CHECK (fecha_limite >= fecha_publicacion)
);

CREATE INDEX IF NOT EXISTS idx_actividades_curso ON actividades (curso_id);
CREATE INDEX IF NOT EXISTS idx_actividades_docente ON actividades (docente_id);
