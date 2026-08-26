-- Subdominio transversal: seguridad (issue #14)
-- Roles de base de datos (NOLOGIN: son roles de permisos que se asignan a los usuarios reales que
-- se conectan). Modela el principio de menor privilegio: cada rol recibe solo los permisos que su
-- función necesita. El aislamiento fila a fila se agrega en seguridad_02_rls.sql.
-- Requiere las tablas de gestión académica (#6) y materiales (#10).

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_estudiante')    THEN CREATE ROLE app_estudiante    NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_docente')       THEN CREATE ROLE app_docente       NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_coordinador')   THEN CREATE ROLE app_coordinador   NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_administrador') THEN CREATE ROLE app_administrador NOLOGIN; END IF;
END $$;

-- Rol de conexión de la aplicación: login dedicado, NO dueño de las tablas y NOINHERIT, de modo
-- que NO herede permisos por sí mismo y no pueda saltear RLS (el dueño de las tablas sí la saltea,
-- por eso la app nunca se conecta como dueño; ver docs/seguridad.md). La aplicación se conecta como
-- app_conexion y hace SET ROLE <rol> + SET LOCAL app.estudiante_id = <id> en cada request. Los GRANT
-- de abajo le permiten asumir cualquiera de los roles de permisos.
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_conexion') THEN
        CREATE ROLE app_conexion LOGIN NOINHERIT;
    END IF;
END $$;

GRANT app_estudiante, app_docente, app_coordinador, app_administrador TO app_conexion;

GRANT USAGE ON SCHEMA public TO app_estudiante, app_docente, app_coordinador, app_administrador;

-- Estudiante: solo lectura de su información académica y del material (acotado por RLS). NO recibe
-- acceso directo a las tablas de fragmentos/embeddings: la recuperación RAG la hace el servicio del
-- asistente aplicando el filtro de acceso sobre materiales (defensa en profundidad, ver #12).
GRANT SELECT ON estudiantes, inscripciones, cursos, materiales TO app_estudiante;

-- Docente: lectura de la información de sus cursos y gestión del material.
GRANT SELECT ON estudiantes, inscripciones, cursos, docentes TO app_docente;
GRANT SELECT, INSERT, UPDATE ON materiales, material_fragmentos TO app_docente;

-- Coordinador: lectura agregada de la oferta académica.
GRANT SELECT ON cursos, inscripciones, materiales TO app_coordinador;

-- Administrador: gestión de usuarios y catálogos.
GRANT SELECT, INSERT, UPDATE ON usuarios, roles, estudiantes, docentes, periodos_academicos, cursos TO app_administrador;
