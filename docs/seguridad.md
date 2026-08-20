# Seguridad, permisos y aislamiento

> Issue [#14](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/14).
> Modelo de seguridad transversal de la capa de datos. Implementación en
> [`db/estructura/seguridad_01_roles_db.sql`](../db/estructura/seguridad_01_roles_db.sql) (roles y
> permisos) y [`db/estructura/seguridad_02_rls.sql`](../db/estructura/seguridad_02_rls.sql)
> (row-level security). Probado contra el Postgres del `docker-compose.yml`. La extensión de estas
> políticas a las tablas del subdominio de evaluación/asistente (entregas, calificaciones,
> progreso académico, conversaciones) se completó en
> [`db/integracion/integracion_02_rls_evaluacion.sql`](../db/integracion/integracion_02_rls_evaluacion.sql)
> durante la revisión cruzada (issue #17): el mismo patrón, aislamiento por
> `app.estudiante_id` verificado con `SET ROLE app_estudiante`.

## 1. Objetivos

Los datos de la plataforma son sensibles (desempeño, entregas, consultas que revelan dificultades
del estudiante). El modelo de seguridad de la capa de datos persigue tres cosas:

1. **Aislamiento por estudiante:** un estudiante nunca accede a datos de otro.
2. **Menor privilegio:** cada rol accede solo a lo que su función necesita.
3. **Trazabilidad:** las acciones sensibles quedan auditadas (issue #7, tabla `eventos_auditoria`).

## 2. Roles y permisos (menor privilegio)

Se definen roles de base de datos `NOLOGIN` que se asignan a los usuarios reales:

| Rol | Acceso |
|---|---|
| `app_estudiante` | Lectura de su información académica y de materiales, siempre acotada por RLS. |
| `app_docente` | Lectura de sus cursos e inscriptos; alta y edición de materiales y fragmentos. |
| `app_coordinador` | Lectura agregada de la oferta académica. |
| `app_administrador` | Gestión de usuarios, roles y catálogos. |

El estudiante **no** recibe acceso directo a las tablas de fragmentos y embeddings: la
recuperación RAG la ejecuta el servicio del asistente aplicando el filtro de acceso sobre
`materiales` (ver issue #12). Esto evita que el estudiante consulte el índice vectorial sin pasar
por el control de acceso.

## 3. Aislamiento por estudiante (Row-Level Security)

La identidad del estudiante autenticado viaja en la variable de sesión `app.estudiante_id`, que la
aplicación setea después de autenticar. Las políticas usan
`current_setting('app.estudiante_id', true)`, que devuelve NULL si no está seteada: sin identidad
no se ve ninguna fila (deny by default).

- `inscripciones`: el estudiante ve solo las suyas.
- `estudiantes`: ve solo su propio registro.
- `materiales`: ve los no restringidos de los cursos en los que está inscripto activo.

Verificado: con `app.estudiante_id = 'est-001'` bajo el rol `app_estudiante`, la tabla
`inscripciones` devuelve solo sus 2 inscripciones y `materiales` oculta la normativa restringida
`mat-099`; con `est-002` (inscripto en un solo curso) el conjunto visible es menor. Un estudiante
no puede ver las inscripciones de otro aunque consulte la tabla completa.

## 4. Control de acceso a materiales y RAG (defensa en profundidad)

El material marcado `nivel_acceso = restringido` (p. ej. normativa interna) nunca debe llegar a un
estudiante, ni de forma directa ni como fuente del asistente. Se aplican dos barreras:

1. **Relacional:** la política RLS de `materiales` excluye lo restringido; la búsqueda vectorial
   (#12) filtra por `materiales.nivel_acceso` mediante JOIN antes del `ORDER BY embedding <=>`.
2. **Aislamiento por curso:** solo se recuperan fragmentos de cursos en los que el estudiante está
   inscripto.

La búsqueda por similitud nunca es la única barrera: siempre se combina con el filtro relacional,
porque un embedding genérico podría acercarse a contenido de otro curso o restringido.

## 5. Auditoría

Las acciones sensibles (cambios de calificación, uso del asistente, accesos) se registran en
`eventos_auditoria` (issue #7). Toda modificación de una calificación debe generar su evento en la
misma transacción (todo o nada), de modo que el registro de auditoría no pueda divergir del dato.

## 6. Frontera con evaluación y asistente (issue #17)

Las tablas del otro subdominio (`actividades`, `evaluaciones`, `entregas`, `calificaciones`,
`progreso_academico`, `conversaciones_asistente`) reciben el mismo patrón de `app.estudiante_id`:
un estudiante ve solo sus propias entregas, calificaciones, progreso y conversaciones, y las
actividades/evaluaciones de los cursos en los que está inscripto activo. `eventos_asistente` (el
log de auditoría) no se expone al rol `app_estudiante` — es información operativa de la
plataforma, no un dato de consulta directa para el estudiante.

**Limitación conocida:** el aislamiento por **docente** (que un docente solo vea los cursos que
dicta) no tiene una política RLS propia todavía, ni en materiales (#14) ni en evaluación/asistente
(#17) — hoy `app_docente` tiene `GRANT` de lectura amplio sin acotar por `docente_titular_id`. Se
deja documentado como mejora pendiente (ver `informe.md`, sección 14 y 15).
