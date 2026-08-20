-- Subdominio: gestión académica (issue #6)
-- Período académico (cuatrimestre / año lectivo) en el que se dictan los cursos.

CREATE TABLE IF NOT EXISTS periodos_academicos (
    id           VARCHAR(20) PRIMARY KEY,
    nombre       VARCHAR(30) NOT NULL UNIQUE,
    fecha_inicio DATE NOT NULL,
    fecha_fin    DATE NOT NULL,
    activo       BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_periodos_fechas CHECK (fecha_fin > fecha_inicio)
);
