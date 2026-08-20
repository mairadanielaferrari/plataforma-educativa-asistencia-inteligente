-- Consultas representativas del subdominio gestión académica (issue #8).
-- Requiere haber corrido db/estructura/gestion_academica_*.sql, db/datos/gestion_academica_seed.sql
-- y db/indices_vistas/gestion_academica_indices_vistas.sql.

-- 1) Selección y filtrado con JOIN
-- ¿Qué cursos se dictan en un período y quién es el docente titular de cada uno?
-- Es la oferta académica que ve un coordinador al planificar el cuatrimestre.
SELECT
    c.id AS curso_id,
    c.nombre,
    c.estado,
    c.cupo,
    u.apellido || ', ' || u.nombre AS docente_titular
FROM cursos c
JOIN docentes d ON d.id = c.docente_titular_id
JOIN usuarios u ON u.id = d.usuario_id
WHERE c.periodo_id = 'per-2026-c1'
ORDER BY c.nombre;

-- 2) Recorrido de la relación N:M (mis cursos)
-- ¿En qué cursos está inscripto un estudiante, con qué estado y con qué docente?
-- Es la pantalla de "mis cursos" del estudiante.
SELECT
    e.id AS estudiante_id,
    c.id AS curso_id,
    c.nombre AS curso,
    ud.apellido || ', ' || ud.nombre AS docente,
    i.estado,
    i.fecha_inscripcion
FROM inscripciones i
JOIN cursos c ON c.id = i.curso_id
JOIN estudiantes e ON e.id = i.estudiante_id
JOIN docentes d ON d.id = c.docente_titular_id
JOIN usuarios ud ON ud.id = d.usuario_id
WHERE e.id = 'est-001'
ORDER BY c.nombre;

-- 3) Agregación / distribución
-- ¿Cómo se distribuyen los usuarios activos por rol?
-- Indicador simple para administración (cuántos estudiantes, docentes, etc.).
SELECT
    r.nombre AS rol,
    COUNT(u.id) AS cantidad_usuarios
FROM roles r
LEFT JOIN usuarios u ON u.rol_id = r.id AND u.activo = TRUE
GROUP BY r.nombre
ORDER BY cantidad_usuarios DESC;

-- 4) Consulta orientada a la decisión (usa la vista vw_ocupacion_cursos)
-- ¿Qué cursos superan el 75% de ocupación y son candidatos a abrir una nueva comisión?
-- Alimenta la decisión de coordinación sobre desdoblar cursos con alta demanda.
SELECT
    curso_id,
    nombre,
    inscriptos_activos,
    cupo,
    ocupacion_pct
FROM vw_ocupacion_cursos
WHERE ocupacion_pct >= 75.0
ORDER BY ocupacion_pct DESC;

-- 5) Función de ventana
-- ¿Cómo se ordenan los cursos por ocupación dentro de cada período?
-- RANK() particionado por período: el dashboard de coordinación muestra los cursos más
-- demandados de cada cuatrimestre sin recalcular el orden por curso.
SELECT
    periodo_id,
    curso_id,
    nombre,
    ocupacion_pct,
    RANK() OVER (PARTITION BY periodo_id ORDER BY ocupacion_pct DESC) AS ranking_ocupacion
FROM vw_ocupacion_cursos
ORDER BY periodo_id, ranking_ocupacion;
