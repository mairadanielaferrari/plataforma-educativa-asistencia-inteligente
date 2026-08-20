-- Integración de subdominios (issue #17, revisión cruzada)
--
-- seguridad.md (#14) documentaba que el aislamiento por estudiante se extendería a las tablas
-- de evaluación/asistente "en la integración" (issue #5), pero integracion_01_fks.sql solo
-- agregó las claves foráneas cross-subdominio, no las políticas RLS. Este script completa esa
-- extensión, reutilizando el mismo patrón de seguridad_02_rls.sql (#14): current_setting
-- ('app.estudiante_id', true) devuelve NULL si no hay identidad seteada, así que sin sesión no
-- se ve ninguna fila (deny by default). Requiere haber corrido seguridad_01/02 y
-- integracion_01_fks.sql.

-- Permisos de lectura sobre las tablas de evaluación y asistente, acotados por RLS más abajo.
GRANT SELECT ON actividades, evaluaciones, entregas, calificaciones, progreso_academico, conversaciones_asistente
    TO app_estudiante;
GRANT SELECT ON actividades, evaluaciones, entregas, progreso_academico, conversaciones_asistente
    TO app_docente;
GRANT SELECT, INSERT, UPDATE ON calificaciones, actividades, evaluaciones TO app_docente;
GRANT SELECT ON actividades, evaluaciones, entregas, calificaciones, progreso_academico, conversaciones_asistente, eventos_asistente
    TO app_coordinador;
-- eventos_asistente (log de auditoría) NO se otorga a app_estudiante: es información operativa
-- de la plataforma, no un dato que el estudiante deba consultar directamente (mismo criterio
-- que materiales/embeddings en #12: el acceso sensible pasa siempre por un servicio, no por
-- consulta directa del rol estudiante).
GRANT SELECT ON eventos_asistente TO app_docente;

-- Actividades y evaluaciones: visibles para el estudiante solo si está inscripto activo en el
-- curso (mismo patrón que materiales_visibles_estudiante en seguridad_02_rls.sql).
ALTER TABLE actividades ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS actividades_visibles_estudiante ON actividades;
CREATE POLICY actividades_visibles_estudiante ON actividades
    FOR SELECT TO app_estudiante
    USING (
        curso_id IN (
            SELECT i.curso_id FROM inscripciones i
            WHERE i.estudiante_id = current_setting('app.estudiante_id', true)
              AND i.estado = 'activa'
        )
    );

ALTER TABLE evaluaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS evaluaciones_visibles_estudiante ON evaluaciones;
CREATE POLICY evaluaciones_visibles_estudiante ON evaluaciones
    FOR SELECT TO app_estudiante
    USING (
        actividad_id IN (
            SELECT a.id FROM actividades a
            JOIN inscripciones i ON i.curso_id = a.curso_id
            WHERE i.estudiante_id = current_setting('app.estudiante_id', true)
              AND i.estado = 'activa'
        )
    );

-- Entregas: el estudiante ve solo las suyas (nunca las de un compañero de curso).
ALTER TABLE entregas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS entregas_propias ON entregas;
CREATE POLICY entregas_propias ON entregas
    FOR SELECT TO app_estudiante
    USING (estudiante_id = current_setting('app.estudiante_id', true));

-- Calificaciones: el estudiante ve solo las de sus propias entregas.
ALTER TABLE calificaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS calificaciones_propias ON calificaciones;
CREATE POLICY calificaciones_propias ON calificaciones
    FOR SELECT TO app_estudiante
    USING (
        entrega_id IN (
            SELECT id FROM entregas
            WHERE estudiante_id = current_setting('app.estudiante_id', true)
        )
    );

-- Progreso académico: el estudiante ve solo el propio (dato sensible de desempeño individual).
ALTER TABLE progreso_academico ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS progreso_propio ON progreso_academico;
CREATE POLICY progreso_propio ON progreso_academico
    FOR SELECT TO app_estudiante
    USING (estudiante_id = current_setting('app.estudiante_id', true));

-- Conversaciones con el asistente: el estudiante ve solo las propias. El asistente opera
-- siempre en nombre del estudiante que lo invoca (docs/analisis_caso_uso.md, sección 2).
ALTER TABLE conversaciones_asistente ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS conversaciones_propias ON conversaciones_asistente;
CREATE POLICY conversaciones_propias ON conversaciones_asistente
    FOR SELECT TO app_estudiante
    USING (estudiante_id = current_setting('app.estudiante_id', true));
