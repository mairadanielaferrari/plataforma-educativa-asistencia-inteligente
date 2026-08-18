-- Índices y vista del subdominio evaluación (issues #7, #9)

-- Acelera el PARTITION BY de la vista de ranking (consulta 5) y cualquier filtro
-- "progreso de un curso en un período" (uso frecuente desde el dashboard docente, #15).
CREATE INDEX IF NOT EXISTS idx_progreso_curso_periodo ON progreso_academico (curso_id, periodo);

-- Ranking de estudiantes por curso y período según su promedio de notas.
-- Se expone como vista (no vista materializada) porque progreso_academico ya es una tabla
-- analítica recalculada periódicamente (ver relevamiento_datos.md); no hace falta duplicar
-- el costo de cómputo en una vista materializada aparte.
CREATE OR REPLACE VIEW vw_ranking_estudiantes_curso AS
SELECT
    p.curso_id,
    p.periodo,
    p.estudiante_id,
    p.promedio_notas,
    p.porcentaje_avance,
    RANK() OVER (
        PARTITION BY p.curso_id, p.periodo
        ORDER BY p.promedio_notas DESC NULLS LAST
    ) AS ranking
FROM progreso_academico p;
