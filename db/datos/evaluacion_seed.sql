-- Datos de ejemplo del subdominio evaluación (issue #7), equivalentes a los JSON de
-- data/ejemplos/*.json. Requiere haber corrido antes db/estructura/evaluacion_*.sql.
--
-- Nota: estudiante_id, docente_id y curso_id son referencias externas al subdominio de
-- gestión académica (issue #6) y todavía no tienen FK real (ver comentarios en el DDL).

INSERT INTO actividades (id, curso_id, docente_id, titulo, tipo, fecha_publicacion, fecha_limite, descripcion, estado, permite_reentrega) VALUES
    ('act-001', 'cur-101', 'doc-001', 'Práctico 1: Modelado relacional', 'practico', '2026-03-10', '2026-03-24 23:59:00-03', 'Diseñar el modelo ER de un caso de estudio y normalizar hasta 3FN.', 'vigente', TRUE),
    ('act-002', 'cur-101', 'doc-001', 'Parcial 1 - Modelado de datos', 'examen_parcial', '2026-04-01', '2026-04-15 20:00:00-03', 'Evaluación individual sobre modelado conceptual, lógico y normalización.', 'vigente', FALSE),
    ('act-003', 'cur-101', 'doc-002', 'Foro: Trade-offs SQL vs NoSQL', 'foro', '2026-03-15', '2026-03-29 23:59:00-03', 'Participación obligatoria con al menos dos intervenciones fundamentadas.', 'vigente', FALSE),
    ('act-004', 'cur-102', 'doc-003', 'Cuestionario: Índices y consultas', 'cuestionario', '2026-03-05', '2026-03-08 23:59:00-03', 'Autoevaluación de opción múltiple, corrección automática.', 'cerrado', TRUE),
    ('act-005', 'cur-102', 'doc-003', 'Proyecto final: Diseño de solución de datos', 'proyecto_final', '2026-02-20', '2026-06-14 23:59:00-03', 'Entrega integradora grupal con informe técnico y repositorio.', 'vigente', TRUE);

INSERT INTO evaluaciones (id, actividad_id, titulo, tipo, modalidad, fecha, ponderacion, criterios_evaluacion) VALUES
    ('eva-001', 'act-002', 'Parcial 1 - Modelado de datos', 'parcial', 'individual', '2026-04-15', 0.30, ARRAY['correctitud del modelo conceptual', 'aplicación correcta de normalización', 'justificación de decisiones de diseño']),
    ('eva-002', 'act-001', 'Práctico 1 - Modelado relacional', 'practico_evaluable', 'individual', '2026-03-25', 0.10, ARRAY['entidades y relaciones identificadas', 'cardinalidades correctas']),
    ('eva-003', 'act-005', 'Proyecto final', 'proyecto_final', 'grupal', '2026-06-15', 0.40, ARRAY['comprensión del caso de uso', 'modelado de la solución', 'justificación tecnológica', 'implementación mínima']),
    ('eva-004', 'act-004', 'Cuestionario índices y consultas', 'cuestionario', 'individual', '2026-03-08', 0.05, ARRAY['corrección automática por opción múltiple']);

INSERT INTO entregas (id, estudiante_id, actividad_id, fecha_entrega, intento, archivo_url, estado, fuera_de_termino, comentario_estudiante) VALUES
    ('ent-001', 'est-001', 'act-001', '2026-03-23 18:42:00-03', 1, 's3://plataforma-edu/entregas/est-001/act-001_v1.pdf', 'entregado', FALSE, 'Adjunto el diagrama ER y el script DDL.'),
    ('ent-002', 'est-002', 'act-001', '2026-03-25 09:10:00-03', 1, 's3://plataforma-edu/entregas/est-002/act-001_v1.pdf', 'entregado', TRUE, 'Entrego con un día de atraso, tuve problemas de conexión.'),
    ('ent-003', 'est-001', 'act-002', '2026-04-15 19:55:00-03', 1, 's3://plataforma-edu/entregas/est-001/act-002_v1.pdf', 'entregado', FALSE, NULL),
    ('ent-004', 'est-003', 'act-001', '2026-03-24 21:30:00-03', 2, 's3://plataforma-edu/entregas/est-003/act-001_v2.pdf', 'reentregado', FALSE, 'Corrijo la normalización según feedback previo.'),
    ('ent-005', 'est-004', 'act-004', '2026-03-08 22:58:00-03', 1, NULL, 'entregado', FALSE, NULL);

INSERT INTO calificaciones (id, entrega_id, docente_id, nota, escala, feedback, fecha_correccion, revisada) VALUES
    ('cal-001', 'ent-001', 'doc-001', 8.5, '0-10', 'Buen modelo, revisar la cardinalidad entre Curso y Docente.', '2026-03-28 10:15:00-03', TRUE),
    ('cal-002', 'ent-002', 'doc-001', 6.0, '0-10', 'Entrega tardía. El modelo no llega a 3FN.', '2026-03-29 11:00:00-03', TRUE),
    ('cal-003', 'ent-004', 'doc-001', 9.0, '0-10', 'Correcta normalización tras la reentrega.', '2026-03-26 08:40:00-03', TRUE),
    ('cal-004', 'ent-003', 'doc-001', NULL, '0-10', NULL, NULL, FALSE);

INSERT INTO progreso_academico (id, estudiante_id, curso_id, periodo, actividades_completadas, actividades_totales, promedio_notas, porcentaje_avance, ultima_actividad, en_riesgo) VALUES
    ('prog-001', 'est-001', 'cur-101', '2026-Q1', 4, 6, 7.8, 66.7, '2026-04-15', FALSE),
    ('prog-002', 'est-002', 'cur-101', '2026-Q1', 2, 6, 6.0, 33.3, '2026-03-25', TRUE),
    ('prog-003', 'est-003', 'cur-101', '2026-Q1', 5, 6, 8.9, 83.3, '2026-04-10', FALSE),
    ('prog-004', 'est-004', 'cur-102', '2026-Q1', 1, 5, 5.5, 20.0, '2026-03-08', TRUE);
