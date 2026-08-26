-- Subdominio transversal: seguridad (issue #14)
-- Row-Level Security (RLS): aislamiento fila a fila para que un estudiante solo acceda a SUS datos
-- y a los materiales no restringidos de SUS cursos, aunque comparta la tabla con todos los demás.
--
-- La identidad del estudiante autenticado viaja en la variable de sesión app.estudiante_id, que la
-- aplicación setea después de autenticar. current_setting('app.estudiante_id', true) devuelve NULL
-- si no está seteada, de modo que sin identidad no se ve ninguna fila (deny by default).
-- Idempotente: DROP POLICY IF EXISTS antes de cada CREATE.

-- Inscripciones: el estudiante ve solo las suyas.
ALTER TABLE inscripciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inscripciones_propias ON inscripciones;
CREATE POLICY inscripciones_propias ON inscripciones
    FOR SELECT TO app_estudiante
    USING (estudiante_id = current_setting('app.estudiante_id', true));

-- Estudiantes: el estudiante ve solo su propio registro.
ALTER TABLE estudiantes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS estudiante_propio ON estudiantes;
CREATE POLICY estudiante_propio ON estudiantes
    FOR SELECT TO app_estudiante
    USING (id = current_setting('app.estudiante_id', true));

-- Materiales: el estudiante ve los NO restringidos de los cursos en los que está inscripto activo.
-- Combina el filtro de acceso (nivel_acceso) con el aislamiento por inscripción: la búsqueda
-- vectorial (#12) nunca es la única barrera, este es el control relacional que la respalda.
ALTER TABLE materiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS materiales_visibles_estudiante ON materiales;
CREATE POLICY materiales_visibles_estudiante ON materiales
    FOR SELECT TO app_estudiante
    USING (
        nivel_acceso <> 'restringido'
        AND curso_id IN (
            SELECT i.curso_id
            FROM inscripciones i
            WHERE i.estudiante_id = current_setting('app.estudiante_id', true)
              AND i.estado = 'activa'
        )
    );

-- Políticas para los roles no-estudiante. Con RLS habilitada, un rol sin política no ve NINGUNA
-- fila aunque tenga GRANT; estas políticas permisivas (USING true) reponen el acceso amplio que ya
-- otorgan los GRANT de seguridad_01_roles_db.sql, sin aflojar el aislamiento del estudiante (cada
-- política está acotada al rol por TO ...). Se agrega una por cada rol GRANTeado sobre la tabla.
-- Idempotente: DROP POLICY IF EXISTS antes de cada CREATE.

-- inscripciones: docente y coordinador tienen GRANT SELECT amplio.
DROP POLICY IF EXISTS inscripciones_lectura_docente ON inscripciones;
CREATE POLICY inscripciones_lectura_docente ON inscripciones
    FOR SELECT TO app_docente USING (true);
DROP POLICY IF EXISTS inscripciones_lectura_coordinador ON inscripciones;
CREATE POLICY inscripciones_lectura_coordinador ON inscripciones
    FOR SELECT TO app_coordinador USING (true);

-- estudiantes: docente y administrador tienen GRANT SELECT amplio.
DROP POLICY IF EXISTS estudiantes_lectura_docente ON estudiantes;
CREATE POLICY estudiantes_lectura_docente ON estudiantes
    FOR SELECT TO app_docente USING (true);
DROP POLICY IF EXISTS estudiantes_lectura_administrador ON estudiantes;
CREATE POLICY estudiantes_lectura_administrador ON estudiantes
    FOR SELECT TO app_administrador USING (true);

-- materiales: docente y coordinador leen todo; el docente además da de alta y edita material
-- (GRANT SELECT, INSERT, UPDATE ON materiales), así que necesita políticas de escritura.
DROP POLICY IF EXISTS materiales_lectura_docente ON materiales;
CREATE POLICY materiales_lectura_docente ON materiales
    FOR SELECT TO app_docente USING (true);
DROP POLICY IF EXISTS materiales_lectura_coordinador ON materiales;
CREATE POLICY materiales_lectura_coordinador ON materiales
    FOR SELECT TO app_coordinador USING (true);
DROP POLICY IF EXISTS materiales_alta_docente ON materiales;
CREATE POLICY materiales_alta_docente ON materiales
    FOR INSERT TO app_docente WITH CHECK (true);
DROP POLICY IF EXISTS materiales_edicion_docente ON materiales;
CREATE POLICY materiales_edicion_docente ON materiales
    FOR UPDATE TO app_docente USING (true) WITH CHECK (true);
