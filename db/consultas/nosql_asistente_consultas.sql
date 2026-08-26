-- Consultas de ejemplo sobre el modelo documental del asistente (issue #11).
-- Requiere haber corrido el DDL y el seed de conversaciones_asistente / eventos_asistente.
-- La consulta 2 resuelve el título del material citado por JOIN a materiales (subdominio #10): la
-- cita solo guarda documento_id, no una copia del título (modelo por referencia, ver nosql/asistente.md).

-- 1) Traer una conversación completa con sus mensajes y fuentes embebidas.
-- Pregunta: "¿qué se dijeron el estudiante y el asistente en esta conversación?"
SELECT id, estudiante_id, curso_id, mensajes
FROM conversaciones_asistente
WHERE id = 'conv-001';

-- 2) Fuentes citadas en cada mensaje del asistente, aplanadas (jsonb_array_elements).
-- Pregunta: "¿qué documentos usó el asistente para responder, y con qué similitud?"
SELECT
    c.id AS conversacion_id,
    msg->>'timestamp' AS timestamp,
    fuente->>'documento_id' AS documento_id,
    m.titulo AS titulo,
    (fuente->>'similitud')::numeric AS similitud
FROM conversaciones_asistente c,
     jsonb_array_elements(c.mensajes) AS msg,
     jsonb_array_elements(msg->'fuentes_utilizadas') AS fuente
LEFT JOIN materiales m ON m.id = fuente->>'documento_id'
WHERE msg->>'rol' = 'asistente';

-- 3) Conversaciones que citaron un documento específico como fuente (containment @>).
-- Pregunta: "¿en qué conversaciones se usó el material mat-014?" — útil para medir uso de
-- materiales y para el análisis de riesgo de fuentes no autorizadas (issue #15).
SELECT id, estudiante_id, curso_id
FROM conversaciones_asistente
WHERE mensajes @> '[{"fuentes_utilizadas": [{"documento_id": "mat-014"}]}]'::jsonb;

-- 4) Indicador: cantidad de conversaciones derivadas a un docente, por curso.
-- Pregunta: "¿en qué cursos el asistente deriva más seguido a un humano?" (calidad del RAG).
SELECT curso_id, COUNT(*) AS derivadas_a_docente
FROM conversaciones_asistente
WHERE derivada_a_docente = TRUE
GROUP BY curso_id
ORDER BY derivadas_a_docente DESC;

-- 5) Eventos de auditoría del asistente por tipo, con su detalle variable.
-- Pregunta: "¿qué eventos de uso/derivación registró el asistente en un período?"
SELECT tipo_evento, estudiante_id, fecha, detalle
FROM eventos_asistente
WHERE fecha >= '2026-03-01' AND fecha < '2026-05-01'
ORDER BY fecha;
