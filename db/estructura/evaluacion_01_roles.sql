-- Subdominio: evaluación y asistente (issue #7)
-- Catálogo de roles usado por el subdominio de evaluación/asistente y, potencialmente,
-- compartido con el resto de la plataforma tras la integración (issue #5).
-- La definición de `roles` es idéntica a la de gestion_academica_01_roles.sql (dueño del catálogo):
-- la duplicación es intencional e idempotente (CREATE TABLE IF NOT EXISTS + ON CONFLICT DO NOTHING),
-- de modo que ambos scripts convivan sin conflicto hasta consolidarse en la integración (issue #5).

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
