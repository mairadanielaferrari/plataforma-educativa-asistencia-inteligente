-- Datos de ejemplo del modelo documental del asistente (issue #11), equivalentes a
-- data/ejemplos/conversaciones_asistente.json. Requiere haber corrido antes
-- db/estructura/evaluacion_07_conversaciones_asistente.sql y ..._08_eventos_asistente.sql.

INSERT INTO conversaciones_asistente (id, estudiante_id, curso_id, fecha_inicio, fecha_fin, canal, calificacion_satisfaccion, derivada_a_docente, mensajes) VALUES
('conv-001', 'est-001', 'cur-101', '2026-04-05 21:03:00-03', '2026-04-05 21:07:00-03', 'chat_web', 5, FALSE, '[
    {
        "rol": "estudiante",
        "texto": "¿Cómo se calcula la forma normal de una tabla con dependencias transitivas?",
        "timestamp": "2026-04-05T21:03:00-03:00"
    },
    {
        "rol": "asistente",
        "texto": "Una tabla está en 3FN si, además de cumplir 2FN, ningún atributo no clave depende transitivamente de la clave primaria...",
        "timestamp": "2026-04-05T21:03:22-03:00",
        "fuentes_utilizadas": [
            {"documento_id": "mat-014", "titulo": "Apunte: Normalización de bases de datos", "fragmento_id": "mat-014#frag-3", "similitud": 0.87}
        ]
    }
]'::jsonb),
('conv-002', 'est-002', 'cur-101', '2026-03-20 15:12:00-03', '2026-03-20 15:14:30-03', 'chat_web', 4, FALSE, '[
    {
        "rol": "estudiante",
        "texto": "No entiendo la diferencia entre clave primaria y clave foránea, ¿me das un ejemplo?",
        "timestamp": "2026-03-20T15:12:00-03:00"
    },
    {
        "rol": "asistente",
        "texto": "La clave primaria identifica de forma única cada fila de una tabla, y la clave foránea referencia la clave primaria de otra tabla para modelar una relación.",
        "timestamp": "2026-03-20T15:12:40-03:00",
        "fuentes_utilizadas": [
            {"documento_id": "mat-002", "titulo": "Apunte: Modelo relacional", "fragmento_id": "mat-002#frag-1", "similitud": 0.91}
        ]
    }
]'::jsonb),
('conv-003', 'est-004', 'cur-102', '2026-03-09 12:20:00-03', '2026-03-09 12:25:00-03', 'chat_web', 2, TRUE, '[
    {
        "rol": "estudiante",
        "texto": "¿Por qué mi calificación del cuestionario no coincide con lo que esperaba?",
        "timestamp": "2026-03-09T12:20:00-03:00"
    },
    {
        "rol": "asistente",
        "texto": "No tengo acceso a revisar calificaciones individuales en detalle. Te derivo con el docente del curso para que revise tu caso.",
        "timestamp": "2026-03-09T12:20:15-03:00",
        "fuentes_utilizadas": []
    }
]'::jsonb);

INSERT INTO eventos_asistente (id, tipo_evento, estudiante_id, conversacion_id, fecha, detalle) VALUES
('aev-001', 'uso_asistente', 'est-001', 'conv-001', '2026-04-05 21:03:22-03', '{"fuentes_citadas": 1, "documentos": ["mat-014"]}'::jsonb),
('aev-002', 'uso_asistente', 'est-002', 'conv-002', '2026-03-20 15:12:40-03', '{"fuentes_citadas": 1, "documentos": ["mat-002"]}'::jsonb),
('aev-003', 'derivacion_a_docente', 'est-004', 'conv-003', '2026-03-09 12:20:15-03', '{"motivo": "consulta sobre calificacion individual", "docente_id": "doc-003"}'::jsonb);
