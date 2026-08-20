-- Subdominio: gestión académica (issue #6)
-- Usuario: identidad y cuenta de acceso de toda persona de la plataforma. Es el supertipo del
-- que se especializan estudiantes y docentes (issues #6, tablas 03 y 04); centraliza nombre,
-- email y estado para evitar redundancia (decisión 5.1 del modelo conceptual #3).

CREATE TABLE IF NOT EXISTS usuarios (
    id          VARCHAR(20) PRIMARY KEY,
    rol_id      VARCHAR(20) NOT NULL REFERENCES roles(id),
    nombre      VARCHAR(80)  NOT NULL,
    apellido    VARCHAR(80)  NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta  DATE    NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT chk_usuarios_email CHECK (position('@' in email) > 1)
);

CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios (rol_id);
