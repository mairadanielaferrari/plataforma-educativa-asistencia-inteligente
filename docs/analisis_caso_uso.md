# Análisis del caso de uso

> Issue [#1](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/1).
> Caso de uso **#9: plataforma educativa con asistencia inteligente**. Este documento fija el
> alcance, los actores y las necesidades de información que guían el diseño de la capa de datos.
> El relevamiento y la clasificación de los datos operacionales están en
> [`relevamiento_datos.md`](relevamiento_datos.md) (issue #2, Sebastián); la traducción a
> entidades se hace en los modelos conceptuales (issues #3 y #4).

## 1. Contexto y objetivo

Una institución educativa ofrece cursos en línea y quiere sumar un **asistente inteligente**
que ayude a cada estudiante a partir de su propia actividad académica: responder consultas
sobre los contenidos, recomendar material de estudio y detectar tempranamente situaciones de
riesgo (bajo avance, notas en caída).

El objetivo del trabajo no es construir el asistente ni el modelo de machine learning, sino
**diseñar la capa de datos** que hace posible todo lo anterior: qué se guarda, con qué modelo
(relacional, documental o vectorial), cómo se relaciona y cómo se accede de forma segura. El
asistente y la aplicación son consumidores de esa capa.

## 2. Actores

| Actor | Rol respecto de los datos |
|---|---|
| **Estudiante** | Se inscribe en cursos, consume materiales, entrega actividades, recibe calificaciones y consulta al asistente. Solo debe ver sus propios datos. |
| **Docente** | Publica actividades y materiales, corrige entregas, califica y sigue el progreso de su curso. |
| **Tutor** | Acompaña a un grupo de estudiantes asignados; lee progreso y alertas, no califica. |
| **Coordinador** | Supervisa cursos y consume reportes agregados. |
| **Administrador** | Gestiona usuarios, cursos y configuración de la plataforma. |
| **Asistente (sistema)** | Actor no humano: recupera materiales por similitud, arma respuestas citando fuentes y registra la interacción. Opera siempre en nombre de un estudiante y con sus permisos. |

## 3. Procesos principales

1. **Gestión académica:** alta de estudiantes, docentes y cursos; inscripción de estudiantes a
   cursos dentro de un período académico. (Subdominio de Maira, issues #3 y #6.)
2. **Publicación y consumo de materiales de estudio:** el docente carga materiales (apuntes,
   guías, videos, normativa); el estudiante los consulta. Los materiales alimentan al asistente
   como fuente de conocimiento. (Issues #3, #10 y #12.)
3. **Evaluación:** el docente publica actividades, el estudiante entrega, el docente califica y
   se recalcula el progreso. (Subdominio de Sebastián, issues #4, #7 y #9.)
4. **Asistencia inteligente (RAG):** el estudiante consulta en lenguaje natural; el asistente
   recupera los fragmentos de material más relevantes de **su** curso, responde citando fuentes
   y, si no puede resolver, deriva al docente. (Issues #4, #11 y #13.)
5. **Seguridad y auditoría:** aislamiento de datos por estudiante y curso, control de acceso por
   rol y registro de acciones sensibles (cambios de nota, uso del asistente). (Issues #14 y #15.)

## 4. Necesidades de información

- **Identidad y matrícula:** quién es cada usuario, qué rol tiene y en qué cursos participa, en
  qué período. Es el núcleo que referencian casi todos los demás datos.
- **Materiales de estudio:** contenido heterogéneo (distinto formato y metadatos según el tipo),
  versionado y con nivel de acceso, apto para lectura humana y para recuperación semántica.
- **Actividad de evaluación:** entregas, calificaciones y progreso, con trazabilidad de cambios.
- **Interacción con el asistente:** consultas, conversaciones y las fuentes citadas en cada
  respuesta, para poder auditar de dónde salió cada afirmación.

## 5. Alcance de la capa de datos

**Incluye:** el modelado en los tres niveles (conceptual, lógico, físico) de los subdominios de
gestión académica, materiales de estudio, evaluación y asistente; los esquemas relacional,
documental (JSONB) y vectorial (pgvector) sobre un único PostgreSQL; seeds y consultas
representativas; y las políticas de acceso y aislamiento.

**No incluye:** la aplicación web/móvil, el servicio de generación de embeddings y el modelo de
lenguaje del asistente (se asumen como componentes externos que invocan a esta capa), ni la
infraestructura de despliegue productiva.

## 6. Supuestos y restricciones

- Volumen de una institución educativa (miles de estudiantes, no millones de eventos): no
  justifica un Data Lake ni un motor distribuido; alcanza un PostgreSQL multi-modelo (se
  justifica en la issue #16).
- Un estudiante nunca debe acceder a datos de otro; el asistente hereda los permisos del
  estudiante que lo invoca.
- Toda acción sensible (cambio de calificación, acceso a datos personales) debe quedar auditada.
- Los identificadores de ejemplo siguen un patrón legible y estable (`est-*`, `doc-*`, `cur-*`,
  `mat-*`, `act-*`) para poder validar relaciones entre subdominios en la integración (issue #5).

## 7. Criterios de diseño

- **Elegir el modelo por la forma del dato**, no por defecto: relacional para lo estructurado y
  transaccional, documental para lo semiestructurado y variable, vectorial para la búsqueda por
  similitud.
- **Integridad y trazabilidad** por sobre el rendimiento máximo, dado el impacto académico de
  los datos.
- **Aislamiento por diseño:** el control de acceso es parte del modelo de datos, no una capa
  agregada después.

Continúa en el [modelo conceptual de gestión académica y materiales de estudio](modelo_conceptual_gestion_materiales.md)
(issue #3).
