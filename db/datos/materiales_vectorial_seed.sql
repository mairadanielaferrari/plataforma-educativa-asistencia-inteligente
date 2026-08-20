-- Datos de ejemplo del modelo vectorial de materiales (issue #12).
-- Requiere materiales_01_materiales.sql + su seed, y materiales_vectorial_0{1,2,3}_*.sql.
-- Fragmentos y vectores coinciden con los del modelo del asistente (db/datos/vectorial_asistente_seed.sql,
-- issue #13): mismos ids de fragmento y mismos embeddings sintéticos de 8 dimensiones, agrupados
-- por tema, para que la integración (issue #5) unifique ambos modelos sin reprocesar.

-- Fragmentos (chunks) de los materiales.
INSERT INTO material_fragmentos (id, material_id, orden, texto, version) VALUES
    ('mat-014#frag-1', 'mat-014', 1, 'La normalizacion organiza los atributos de una tabla para reducir redundancia e inconsistencias.', 1),
    ('mat-014#frag-3', 'mat-014', 3, 'Una tabla esta en 3FN si, ademas de cumplir 2FN, ningun atributo no clave depende transitivamente de la clave primaria.', 1),
    ('mat-002#frag-1', 'mat-002', 1, 'La clave primaria identifica de forma unica cada fila; la clave foranea referencia la clave primaria de otra tabla.', 1),
    ('mat-002#frag-2', 'mat-002', 2, 'Ejemplo: entregas.estudiante_id es clave foranea que referencia a estudiantes.id.', 1),
    ('mat-021#frag-1', 'mat-021', 1, 'Un indice B-tree acelera busquedas por igualdad y rango sobre la columna indexada.', 1),
    ('mat-099#frag-1', 'mat-099', 1, 'Criterios internos de recalificacion y manejo de reclamos de nota (uso exclusivo docente).', 1)
ON CONFLICT (id) DO NOTHING;

-- Embeddings sintéticos (8 dim). El acceso (restringido) y el curso NO se guardan acá: se derivan
-- de materiales por JOIN (ver materiales_vectorial_consultas.sql).
INSERT INTO fragmento_embeddings (id, fragmento_id, modelo, dimension, version, embedding) VALUES
    ('emb-001', 'mat-014#frag-1', 'sintetico-8d', 8, 1, '[0.90,0.10,0.05,0.02,0.01,0.00,0.00,0.00]'),
    ('emb-002', 'mat-014#frag-3', 'sintetico-8d', 8, 1, '[0.88,0.12,0.06,0.01,0.00,0.00,0.00,0.00]'),
    ('emb-003', 'mat-002#frag-1', 'sintetico-8d', 8, 1, '[0.05,0.02,0.90,0.10,0.05,0.00,0.00,0.00]'),
    ('emb-004', 'mat-002#frag-2', 'sintetico-8d', 8, 1, '[0.03,0.01,0.87,0.12,0.06,0.00,0.00,0.00]'),
    ('emb-005', 'mat-021#frag-1', 'sintetico-8d', 8, 1, '[0.00,0.00,0.02,0.01,0.05,0.90,0.10,0.03]'),
    ('emb-006', 'mat-099#frag-1', 'sintetico-8d', 8, 1, '[0.10,0.05,0.02,0.00,0.00,0.02,0.01,0.85]')
ON CONFLICT (id) DO NOTHING;
