-- Subdominio: materiales de estudio (issue #10)
-- Material de estudio de un curso. El contenido variable según el tipo (un video tiene duración
-- y url, una normativa una vigencia, un apunte una lista de temas) se guarda en la columna
-- metadata JSONB para no dejar decenas de columnas en NULL. Es la tabla que el subdominio de
-- evaluación/asistente referencia como documento_id / material_id al citar una fuente.
--
-- curso_id y autor_id son FK reales dentro de este subdominio (tablas de gestión académica #6):
-- este script debe correr después de db/estructura/gestion_academica_*.sql.

CREATE TABLE IF NOT EXISTS materiales (
    id                VARCHAR(20) PRIMARY KEY,
    curso_id          VARCHAR(20) NOT NULL REFERENCES cursos(id),
    autor_id          VARCHAR(20) NOT NULL REFERENCES docentes(id),
    titulo            VARCHAR(200) NOT NULL,
    tipo              VARCHAR(30) NOT NULL
        CHECK (tipo IN ('apunte', 'guia_practica', 'video', 'normativa', 'faq')),
    nivel_acceso      VARCHAR(20) NOT NULL DEFAULT 'curso'
        CHECK (nivel_acceso IN ('publico', 'curso', 'restringido')),
    version           INT NOT NULL DEFAULT 1 CHECK (version >= 1),
    fecha_publicacion DATE NOT NULL,
    metadata          JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_materiales_curso ON materiales (curso_id);
-- GIN con jsonb_path_ops: soporta contención (@>) sobre metadata sin escanear cada fila,
-- p. ej. "materiales que tratan el tema normalizacion".
CREATE INDEX IF NOT EXISTS idx_materiales_metadata_gin ON materiales USING gin (metadata jsonb_path_ops);
