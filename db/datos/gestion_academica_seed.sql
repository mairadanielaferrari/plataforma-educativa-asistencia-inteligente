-- Datos de ejemplo del subdominio gestión académica (issue #6).
-- Requiere haber corrido antes db/estructura/gestion_academica_*.sql.
-- Los ids coinciden con las referencias externas del subdominio de evaluación/asistente
-- (est-001..004, doc-001..003, cur-101/102) para que las FKs cierren en la integración (issue #5).
-- Se agregan estudiantes (est-005/006) para que la ocupación de los cursos sea representativa.
-- Idempotente: ON CONFLICT (id) DO NOTHING permite re-correr el seed.

-- Usuarios (identidad + cuenta). El rol referencia el catálogo de gestion_academica_01_roles.sql.
INSERT INTO usuarios (id, rol_id, nombre, apellido, email, activo, fecha_alta) VALUES
    ('usr-001', 'rol-estudiante', 'Ana',      'Gomez',  'ana.gomez@plataforma.edu',     TRUE, '2026-02-15'),
    ('usr-002', 'rol-estudiante', 'Bruno',    'Diaz',   'bruno.diaz@plataforma.edu',    TRUE, '2026-02-15'),
    ('usr-003', 'rol-estudiante', 'Carla',    'Ruiz',   'carla.ruiz@plataforma.edu',    TRUE, '2026-02-16'),
    ('usr-004', 'rol-estudiante', 'Diego',    'Sosa',   'diego.sosa@plataforma.edu',    TRUE, '2025-02-20'),
    ('usr-008', 'rol-estudiante', 'Hernan',   'Luna',   'hernan.luna@plataforma.edu',   TRUE, '2026-02-17'),
    ('usr-009', 'rol-estudiante', 'Irina',    'Mora',   'irina.mora@plataforma.edu',    TRUE, '2025-02-18'),
    ('usr-005', 'rol-docente',    'Elena',    'Vidal',  'elena.vidal@plataforma.edu',   TRUE, '2024-03-01'),
    ('usr-006', 'rol-docente',    'Fabian',   'Coll',   'fabian.coll@plataforma.edu',   TRUE, '2024-03-01'),
    ('usr-007', 'rol-docente',    'Gabriela', 'Paz',    'gabriela.paz@plataforma.edu',  TRUE, '2023-08-10')
ON CONFLICT (id) DO NOTHING;

-- Estudiantes (especialización 1:1 de usuario).
INSERT INTO estudiantes (id, usuario_id, legajo, cohorte) VALUES
    ('est-001', 'usr-001', 'E-2026-001', '2026'),
    ('est-002', 'usr-002', 'E-2026-002', '2026'),
    ('est-003', 'usr-003', 'E-2026-003', '2026'),
    ('est-004', 'usr-004', 'E-2025-018', '2025'),
    ('est-005', 'usr-008', 'E-2026-004', '2026'),
    ('est-006', 'usr-009', 'E-2025-021', '2025')
ON CONFLICT (id) DO NOTHING;

-- Docentes (especialización 1:1 de usuario).
INSERT INTO docentes (id, usuario_id, area, titulo_academico) VALUES
    ('doc-001', 'usr-005', 'Bases de Datos',      'Doctora en Ciencias de la Computacion'),
    ('doc-002', 'usr-006', 'Bases de Datos',      'Magister en Ingenieria de Software'),
    ('doc-003', 'usr-007', 'Ingenieria de Datos', 'Ingeniera en Sistemas')
ON CONFLICT (id) DO NOTHING;

-- Período académico.
INSERT INTO periodos_academicos (id, nombre, fecha_inicio, fecha_fin, activo) VALUES
    ('per-2026-c1', '2026-C1', '2026-03-01', '2026-07-31', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Cursos. Cupos de seminario para que la ocupación del ejemplo sea significativa.
INSERT INTO cursos (id, docente_titular_id, periodo_id, nombre, descripcion, cupo, estado) VALUES
    ('cur-101', 'doc-001', 'per-2026-c1', 'Bases de Datos Relacionales', 'Modelado conceptual, logico y fisico; normalizacion y SQL.', 8, 'en_curso'),
    ('cur-102', 'doc-003', 'per-2026-c1', 'Diseno de Soluciones de Datos', 'Arquitecturas de datos, indices, NoSQL y proyecto integrador.', 6, 'en_curso')
ON CONFLICT (id) DO NOTHING;

-- Inscripciones (N:M estudiante-curso). Varios estudiantes cursan las dos materias (cardinalidad
-- N:M) y hay una inscripción dada de baja (no cuenta como activa en la ocupación).
INSERT INTO inscripciones (id, estudiante_id, curso_id, fecha_inscripcion, estado) VALUES
    ('ins-001', 'est-001', 'cur-101', '2026-02-28', 'activa'),
    ('ins-002', 'est-002', 'cur-101', '2026-02-28', 'activa'),
    ('ins-003', 'est-003', 'cur-101', '2026-03-01', 'activa'),
    ('ins-004', 'est-005', 'cur-101', '2026-03-01', 'activa'),
    ('ins-005', 'est-006', 'cur-101', '2026-03-02', 'activa'),
    ('ins-006', 'est-004', 'cur-101', '2026-03-02', 'activa'),
    ('ins-007', 'est-001', 'cur-102', '2026-03-02', 'activa'),
    ('ins-008', 'est-004', 'cur-102', '2026-02-27', 'activa'),
    ('ins-009', 'est-005', 'cur-102', '2026-03-03', 'activa'),
    ('ins-010', 'est-006', 'cur-102', '2026-03-03', 'baja')
ON CONFLICT (id) DO NOTHING;
