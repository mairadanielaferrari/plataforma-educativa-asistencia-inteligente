-- Consultas representativas del subdominio evaluación (issue #9).
-- Requiere haber corrido db/estructura/evaluacion_*.sql, db/datos/evaluacion_seed.sql
-- y db/indices_vistas/evaluacion_indices_vistas.sql.

-- 1) Selección y filtrado
-- ¿Qué actividades vigentes tiene un curso y cuándo vencen?
-- Útil para el estudiante/docente que quiere ver la agenda pendiente de un curso.
SELECT id, titulo, tipo, fecha_publicacion, fecha_limite, permite_reentrega
FROM actividades
WHERE curso_id = 'cur-101'
  AND estado = 'vigente'
ORDER BY fecha_limite;

-- 2) Información relacionada entre entidades (JOIN)
-- ¿Qué entregó un estudiante, para qué actividad, y qué nota tiene (si ya fue corregida)?
-- Es la vista de "mis entregas" que necesitaría el estudiante o su tutor.
SELECT
    e.id AS entrega_id,
    e.estudiante_id,
    a.titulo AS actividad,
    a.tipo,
    e.fecha_entrega,
    e.fuera_de_termino,
    c.nota,
    c.revisada
FROM entregas e
JOIN actividades a ON a.id = e.actividad_id
LEFT JOIN calificaciones c ON c.entrega_id = e.id
WHERE e.estudiante_id = 'est-001'
ORDER BY e.fecha_entrega;

-- 3) Agregación / indicador
-- ¿Qué actividades tienen bajo desempeño o mucho atraso en las entregas?
-- Indicador para que el docente priorice qué actividad revisar o reforzar.
SELECT
    a.id AS actividad_id,
    a.titulo,
    COUNT(e.id) AS cantidad_entregas,
    ROUND(AVG(c.nota), 2) AS promedio_nota,
    ROUND(100.0 * COUNT(*) FILTER (WHERE e.fuera_de_termino) / COUNT(*), 1) AS pct_fuera_termino
FROM entregas e
JOIN actividades a ON a.id = e.actividad_id
LEFT JOIN calificaciones c ON c.entrega_id = e.id
GROUP BY a.id, a.titulo
HAVING COUNT(e.id) > 0
ORDER BY promedio_nota NULLS LAST;

-- 4) Consulta orientada a la toma de decisiones
-- ¿Qué estudiantes están en riesgo académico y requieren seguimiento de un tutor?
-- Alimenta las alertas de riesgo académico del subdominio asistente (issue #13). Las
-- recomendaciones de estudio quedan fuera de alcance (ver modelo conceptual), no hay tabla propia.
SELECT
    p.estudiante_id,
    p.curso_id,
    p.periodo,
    p.porcentaje_avance,
    p.promedio_notas,
    p.actividades_completadas,
    p.actividades_totales
FROM progreso_academico p
WHERE p.en_riesgo = TRUE
ORDER BY p.porcentaje_avance ASC;

-- 5) Función de ventana / patrón que justifica una vista
-- ¿Cómo se ubica cada estudiante dentro del ranking de su curso y período?
-- Usa la vista vw_ranking_estudiantes_curso (RANK() sobre progreso_academico), apoyada en
-- el índice compuesto (curso_id, periodo) para no recalcular el particionado en cada
-- consulta del dashboard docente.
SELECT curso_id, periodo, estudiante_id, promedio_notas, ranking
FROM vw_ranking_estudiantes_curso
WHERE curso_id = 'cur-101' AND periodo = '2026-C1'
ORDER BY ranking;
