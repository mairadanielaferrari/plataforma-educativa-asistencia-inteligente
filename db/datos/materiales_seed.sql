-- Datos de ejemplo del subdominio materiales de estudio (issue #10).
-- Requiere db/estructura/gestion_academica_*.sql (cursos, docentes) y materiales_01_materiales.sql.
-- Los ids mat-014/mat-002/mat-021/mat-099 coinciden con los que el subdominio del asistente cita
-- como fuente (ver db/datos/vectorial_asistente_seed.sql), para que la integración (issue #5) cierre.
-- El metadata cambia de forma según el tipo: esa es la razón de usar JSONB.

INSERT INTO materiales (id, curso_id, autor_id, titulo, tipo, nivel_acceso, version, fecha_publicacion, metadata) VALUES
    ('mat-014', 'cur-101', 'doc-001', 'Apunte: Normalizacion', 'apunte', 'curso', 1, '2026-03-05',
        '{"formato":"pdf","paginas":12,"idioma":"es","temas":["normalizacion","1FN","2FN","3FN"]}'),
    ('mat-002', 'cur-101', 'doc-001', 'Apunte: Claves primarias y foraneas', 'apunte', 'curso', 2, '2026-03-03',
        '{"formato":"pdf","paginas":8,"idioma":"es","temas":["clave primaria","clave foranea","integridad referencial"]}'),
    ('mat-030', 'cur-101', 'doc-002', 'Video: Introduccion a SQL', 'video', 'publico', 1, '2026-03-08',
        '{"formato":"mp4","duracion_min":18,"url":"https://cdn.plataforma.edu/videos/sql-intro.mp4","subtitulos":true,"temas":["select","where","join"]}'),
    ('mat-040', 'cur-101', 'doc-001', 'Preguntas frecuentes de la cursada', 'faq', 'curso', 3, '2026-03-10',
        '{"formato":"html","preguntas":[{"q":"Como entrego un practico?","a":"Desde la seccion Actividades, subiendo el archivo antes de la fecha limite."},{"q":"Se puede reentregar?","a":"Solo si la actividad permite reentrega."}]}'),
    ('mat-021', 'cur-102', 'doc-003', 'Guia practica: Indices y consultas', 'guia_practica', 'curso', 1, '2026-03-04',
        '{"formato":"pdf","ejercicios":8,"idioma":"es","temas":["indice B-tree","EXPLAIN","optimizacion"]}'),
    ('mat-099', 'cur-101', 'doc-001', 'Criterios internos de recalificacion', 'normativa', 'restringido', 1, '2026-02-25',
        '{"formato":"pdf","vigencia_desde":"2026-01-01","ambito":"docente","confidencial":true}')
ON CONFLICT (id) DO NOTHING;
