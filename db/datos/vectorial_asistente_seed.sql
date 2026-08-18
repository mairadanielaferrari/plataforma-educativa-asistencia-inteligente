-- Datos de ejemplo del modelo vectorial del asistente (issue #13).
-- Los embeddings son VECTORES SINTÉTICOS de 8 dimensiones (no salen de un modelo real), pero
-- están agrupados a propósito por tema para que las consultas de similitud del ejemplo
-- devuelvan resultados coherentes: cluster A ~ normalización, cluster B ~ claves primarias
-- y foráneas, cluster C ~ índices, cluster D ~ normativa de evaluación (restringido).

INSERT INTO material_fragmentos_embeddings (id, material_id, fragmento_id, curso_id, categoria, texto_fragmento, restringido, version, embedding) VALUES
('frag-001', 'mat-014', 'mat-014#frag-1', 'cur-101', 'apunte', 'La normalización organiza los atributos de una tabla para reducir redundancia e inconsistencias.', FALSE, 1, '[0.90,0.10,0.05,0.02,0.01,0.00,0.00,0.00]'),
('frag-002', 'mat-014', 'mat-014#frag-3', 'cur-101', 'apunte', 'Una tabla está en 3FN si, además de cumplir 2FN, ningún atributo no clave depende transitivamente de la clave primaria.', FALSE, 1, '[0.88,0.12,0.06,0.01,0.00,0.00,0.00,0.00]'),
('frag-003', 'mat-002', 'mat-002#frag-1', 'cur-101', 'apunte', 'La clave primaria identifica de forma única cada fila; la clave foránea referencia la clave primaria de otra tabla.', FALSE, 1, '[0.05,0.02,0.90,0.10,0.05,0.00,0.00,0.00]'),
('frag-004', 'mat-002', 'mat-002#frag-2', 'cur-101', 'apunte', 'Ejemplo: entregas.estudiante_id es clave foránea que referencia a estudiantes.id.', FALSE, 1, '[0.03,0.01,0.87,0.12,0.06,0.00,0.00,0.00]'),
('frag-005', 'mat-021', 'mat-021#frag-1', 'cur-102', 'apunte', 'Un índice B-tree acelera búsquedas por igualdad y rango sobre la columna indexada.', FALSE, 1, '[0.00,0.00,0.02,0.01,0.05,0.90,0.10,0.03]'),
('frag-006', 'mat-099', 'mat-099#frag-1', 'cur-101', 'normativa', 'Criterios internos de recalificación y manejo de reclamos de nota (uso exclusivo docente).', TRUE, 1, '[0.10,0.05,0.02,0.00,0.00,0.02,0.01,0.85]');

INSERT INTO consultas_frecuentes_embeddings (id, curso_id, texto_consulta, respuesta_sugerida, veces_reutilizada, embedding) VALUES
('faq-001', 'cur-101', '¿Cómo se calcula la forma normal de una tabla?', 'Se evalúa el cumplimiento de 1FN, 2FN y 3FN revisando dependencias funcionales y transitivas.', 4, '[0.87,0.13,0.06,0.01,0.00,0.00,0.00,0.00]'),
('faq-002', 'cur-101', '¿Qué diferencia hay entre clave primaria y clave foránea?', 'La primaria identifica la fila; la foránea referencia la primaria de otra tabla para modelar la relación.', 6, '[0.04,0.02,0.88,0.11,0.05,0.00,0.00,0.00]');
