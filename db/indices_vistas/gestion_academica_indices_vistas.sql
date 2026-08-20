-- Vistas del subdominio gestión académica (issue #8).
-- Los índices del subdominio están definidos inline en db/estructura/gestion_academica_*.sql
-- (por FK y por columnas de filtro habitual). Acá se agrega una vista de apoyo a las consultas.

-- Ocupación de cada curso: inscriptos activos sobre el cupo. Evita repetir la agregación en
-- cada consulta del dashboard de coordinación y centraliza la definición de "inscripto activo".
CREATE OR REPLACE VIEW vw_ocupacion_cursos AS
SELECT
    c.id         AS curso_id,
    c.nombre,
    c.periodo_id,
    c.cupo,
    COUNT(i.id) FILTER (WHERE i.estado = 'activa') AS inscriptos_activos,
    ROUND(
        100.0 * COUNT(i.id) FILTER (WHERE i.estado = 'activa') / c.cupo,
        1
    ) AS ocupacion_pct
FROM cursos c
LEFT JOIN inscripciones i ON i.curso_id = c.id
GROUP BY c.id, c.nombre, c.periodo_id, c.cupo;
