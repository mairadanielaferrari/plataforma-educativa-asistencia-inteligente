-- Subdominio: gestión académica (issue #6)
-- Catálogo de roles de la plataforma. Este subdominio es el dueño del catálogo (ver decisión
-- 5.1 del modelo conceptual #3); reconcilia la tabla homónima que el subdominio de evaluación
-- había creado como "compartida tras la integración" (evaluacion_01_roles.sql). El esquema y
-- los datos son idénticos e idempotentes, de modo que ambos scripts pueden convivir hasta la
-- integración (issue #5).

CREATE TABLE IF NOT EXISTS roles (
    id          VARCHAR(20) PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
);

INSERT INTO roles (id, nombre, descripcion) VALUES
    ('rol-estudiante',    'estudiante',    'Accede a sus cursos, entregas, calificaciones y al asistente'),
    ('rol-docente',       'docente',       'Publica actividades, corrige entregas y asigna calificaciones'),
    ('rol-tutor',         'tutor',         'Realiza seguimiento del progreso académico de estudiantes asignados'),
    ('rol-coordinador',   'coordinador',   'Supervisa cursos y accede a reportes agregados'),
    ('rol-administrador', 'administrador', 'Administra la plataforma y la configuración de cursos')
ON CONFLICT (id) DO NOTHING;
