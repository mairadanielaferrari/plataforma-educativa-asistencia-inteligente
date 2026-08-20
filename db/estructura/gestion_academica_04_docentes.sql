-- Subdominio: gestión académica (issue #6)
-- Docente: especialización de Usuario (1:1) con los atributos propios del rol docente.
-- Es la tabla que el subdominio de evaluación/asistente referencia como docentes.id.

CREATE TABLE IF NOT EXISTS docentes (
    id               VARCHAR(20) PRIMARY KEY,
    usuario_id       VARCHAR(20) NOT NULL UNIQUE REFERENCES usuarios(id),
    area             VARCHAR(80),
    titulo_academico VARCHAR(120)
);

CREATE INDEX IF NOT EXISTS idx_docentes_usuario ON docentes (usuario_id);
