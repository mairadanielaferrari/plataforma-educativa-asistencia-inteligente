-- Subdominio: asistente (issue #11)
-- Modelo documental sobre PostgreSQL: la tabla mantiene columnas relacionales para los
-- campos que se filtran/agregan con frecuencia (estudiante_id, curso_id, canal,
-- derivada_a_docente) y un documento JSONB para la parte variable de la conversación
-- (mensajes embebidos, cada uno con sus fuentes_utilizadas embebidas).
--
-- FK pendientes de integración (issue #5, subdominio de gestión académica #6):
--   estudiante_id -> estudiantes.id
--   curso_id      -> cursos.id

CREATE TABLE IF NOT EXISTS conversaciones_asistente (
    id                       VARCHAR(20) PRIMARY KEY,
    estudiante_id            VARCHAR(20) NOT NULL,   -- FK pendiente -> estudiantes.id
    curso_id                 VARCHAR(20),            -- FK pendiente -> cursos.id (opcional)
    fecha_inicio             TIMESTAMPTZ NOT NULL,
    fecha_fin                TIMESTAMPTZ,
    canal                    VARCHAR(20) NOT NULL
        CHECK (canal IN ('chat_web', 'app_movil')),
    calificacion_satisfaccion SMALLINT
        CHECK (calificacion_satisfaccion IS NULL OR (calificacion_satisfaccion BETWEEN 1 AND 5)),
    derivada_a_docente        BOOLEAN NOT NULL DEFAULT FALSE,
    mensajes                  JSONB NOT NULL DEFAULT '[]'::jsonb,

    CONSTRAINT chk_conversaciones_mensajes_array CHECK (jsonb_typeof(mensajes) = 'array')
);

CREATE INDEX IF NOT EXISTS idx_conversaciones_estudiante ON conversaciones_asistente (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_curso ON conversaciones_asistente (curso_id);

-- Índice GIN para consultar dentro del documento (p. ej. filtrar por documento_id citado
-- como fuente, o por rol de un mensaje) sin tener que traer y parsear todo el JSONB en la app.
CREATE INDEX IF NOT EXISTS idx_conversaciones_mensajes_gin ON conversaciones_asistente USING GIN (mensajes jsonb_path_ops);
