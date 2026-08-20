-- Datos de ejemplo del modelo vectorial del asistente (issue #13).
-- Integración (issue #5): los embeddings de fragmentos de materiales se unificaron en el modelo
-- normalizado del subdominio de materiales (material_fragmentos + fragmento_embeddings, #12); su
-- seed está en db/datos/materiales_vectorial_seed.sql. Acá queda solo el caché semántico de FAQ,
-- que es propio del asistente y no se solapa con materiales.
-- Los embeddings son vectores sintéticos de 8 dimensiones agrupados por tema.

INSERT INTO consultas_frecuentes_embeddings (id, curso_id, texto_consulta, respuesta_sugerida, veces_reutilizada, embedding) VALUES
('faq-001', 'cur-101', '¿Cómo se calcula la forma normal de una tabla?', 'Se evalúa el cumplimiento de 1FN, 2FN y 3FN revisando dependencias funcionales y transitivas.', 4, '[0.87,0.13,0.06,0.01,0.00,0.00,0.00,0.00]'),
('faq-002', 'cur-101', '¿Qué diferencia hay entre clave primaria y clave foránea?', 'La primaria identifica la fila; la foránea referencia la primaria de otra tabla para modelar la relación.', 6, '[0.04,0.02,0.88,0.11,0.05,0.00,0.00,0.00]')
ON CONFLICT (id) DO NOTHING;
