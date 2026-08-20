-- Subdominio: gestión académica (issue #6)
-- Estudiante: especialización de Usuario (1:1) con los atributos propios del rol estudiante.
-- Es la tabla que el subdominio de evaluación/asistente referencia como estudiantes.id.

CREATE TABLE IF NOT EXISTS estudiantes (
    id          VARCHAR(20) PRIMARY KEY,
    usuario_id  VARCHAR(20) NOT NULL UNIQUE REFERENCES usuarios(id),
    legajo      VARCHAR(20) NOT NULL UNIQUE,
    cohorte     VARCHAR(9)
);

CREATE INDEX IF NOT EXISTS idx_estudiantes_usuario ON estudiantes (usuario_id);
