# Plataforma educativa con asistencia inteligente

Trabajo Práctico Integrador — Bases de Datos para Inteligencia Artificial, Carrera de
Especialización en Inteligencia Artificial (UBA FIUBA), 2026.

## Integrantes

- Maira Ferrari — subdominio de gestión académica y materiales de estudio
- Sebastián Pardo — subdominio de evaluación y asistente

## Caso de uso

**#9 — Plataforma educativa con asistencia inteligente.** Una institución educativa dicta
cursos y quiere sumar un asistente de IA que ayude a cada estudiante a partir de su propia
actividad académica: responder consultas sobre los contenidos, recomendar material de estudio
y detectar tempranamente situaciones de riesgo académico. El trabajo **no** construye el
asistente ni el modelo de lenguaje: diseña la capa de datos que lo hace posible (qué se
guarda, con qué modelo, cómo se relaciona y cómo se accede de forma segura). Detalle completo
en [`docs/analisis_caso_uso.md`](docs/analisis_caso_uso.md).

## Datos principales identificados

- **Gestión académica**: usuarios, estudiantes, docentes, cursos, períodos académicos,
  inscripciones.
- **Materiales de estudio**: materiales (apuntes, guías, videos, normativa) y sus fragmentos.
- **Evaluación**: actividades, evaluaciones, entregas, calificaciones, progreso académico.
- **Asistente**: conversaciones (mensajes y fuentes citadas), eventos de auditoría,
  recomendaciones de estudio, embeddings de fragmentos y de consultas frecuentes (FAQ).

Clasificación completa por tipo de dato (estructurado / semiestructurado / no estructurado,
operacional / analítico, sensible, auditoría) en
[`docs/relevamiento_datos.md`](docs/relevamiento_datos.md) e
[`docs/informe.md`](docs/informe.md) (sección 3).

## Tecnología

Solución **multi-modelo sobre un único PostgreSQL 16 + pgvector**:

- **Relacional**: núcleo académico y de evaluación (estudiantes, docentes, cursos,
  inscripciones, actividades, evaluaciones, entregas, calificaciones, progreso académico).
- **Documental (JSONB)**: contenido variable — metadatos de materiales, conversaciones y
  eventos del asistente.
- **Vectorial (pgvector, HNSW)**: embeddings de fragmentos de materiales (RAG) y de consultas
  frecuentes (caché de FAQ).
- **Seguridad**: roles de base de datos de menor privilegio + Row-Level Security por
  estudiante.

Justificación completa, componente por componente y contra alternativas descartadas (MongoDB,
motor de grafos, vector store dedicado), en
[`docs/seleccion_tecnologica.md`](docs/seleccion_tecnologica.md).

## Estructura del repositorio

```
docs/                informe consolidado (.md y .pdf), análisis, modelos conceptuales,
                      integración, arquitectura, selección tecnológica, seguridad
data/ejemplos/        datos de ejemplo (JSON) del subdominio evaluación/asistente
db/
  estructura/          DDL: tablas, PK, FK, CHECK, índices por subdominio
  datos/               seeds (datos de ejemplo en SQL) por subdominio
  consultas/           consultas SQL representativas por subdominio
  indices_vistas/      vistas e índices adicionales
  integracion/          FKs y RLS cross-subdominio (se corre al final)
nosql/                 modelo documental (JSONB): materiales y asistente
vectorial/              modelo vectorial (pgvector): materiales y asistente
anexos/                 material complementario
```

## Cómo correr / revisar la implementación

1. Levantar el entorno (Postgres + pgvector + pgAdmin):

   ```bash
   cp .env.example .env
   docker compose up -d
   ```

   pgAdmin queda en <http://localhost:8080> (o el puerto de `.env`). Dentro de Docker, el host
   de la base es `postgres`.

2. Aplicar el esquema completo, **en este orden** (cada carpeta corrida en orden alfabético de
   archivo):

   ```bash
   set -a; source .env; set +a
   for f in db/estructura/*.sql db/datos/*.sql db/indices_vistas/*.sql db/integracion/*.sql; do
     docker exec -i plataforma_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < "$f"
   done
   ```

3. Correr las consultas representativas:

   ```bash
   for f in db/consultas/*.sql; do
     docker exec -i plataforma_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$f"
   done
   ```

Orden de aplicación y verificación detallados en [`docs/integracion.md`](docs/integracion.md).

## Principales decisiones de diseño

- **Un solo PostgreSQL multi-modelo** en vez de separar motores por tipo de dato: cubre los
  tres patrones de acceso (transaccional, documental, similitud) sin la complejidad operativa
  ni el riesgo de inconsistencia de operar varios sistemas, al volumen esperado de una
  institución educativa (`docs/seleccion_tecnologica.md`).
- **Embebido vs. referencia**: mensajes y fuentes citadas se embeben en la conversación del
  asistente (JSONB); el material citado se referencia por id, nunca se duplica su contenido
  (`nosql/asistente.md`).
- **Modelo de embeddings normalizado**: se reconcilió una versión denormalizada (asistente) y
  una normalizada (materiales) adoptando la normalizada, para no duplicar el nivel de acceso
  del material fuera de `materiales` (`docs/integracion.md`, sección 3).
- **Seguridad por diseño**: Row-Level Security con `app.estudiante_id` (deny-by-default),
  extendida en la revisión cruzada a todas las tablas sensibles de evaluación y asistente
  (`docs/seguridad.md`).

Todas las decisiones, con su justificación, están desarrolladas en
[`docs/informe.md`](docs/informe.md) / [`docs/informe.pdf`](docs/informe.pdf).

## Consultas incluidas

26 consultas SQL representativas (mínimo pedido: 5), repartidas en `db/consultas/` por
subdominio y tecnología (relacional, JSONB, vectorial), cada una con una consulta que
justifica el uso de un índice o una vista. Listado completo en
[`docs/informe.md`](docs/informe.md), sección 10.

## Limitaciones y posibles mejoras

- No hay política RLS por **docente** (que un docente solo vea los cursos que dicta); hoy
  accede por permiso amplio sin acotar por `docente_titular_id`.
- El diagrama de arquitectura general que une ambos subdominios en una sola imagen no se
  consolidó (quedan dos diagramas Mermaid, uno por subdominio).
- Los embeddings usados en toda la implementación son **sintéticos** (vectores de 8
  dimensiones agrupados por tema a mano), suficientes para validar diseño y consultas pero no
  para medir calidad real de recuperación semántica.
- El recálculo periódico de `progreso_academico` está diseñado pero no implementado como job
  (queda fuera del alcance de la capa de datos).

Detalle ampliado en [`docs/informe.md`](docs/informe.md), sección 15.

## Organización del trabajo

Las tareas están en los **Issues** del repositorio (#1 a #18), repartidas entre los
integrantes por subdominio y con dependencias explícitas entre ellas. La participación de
ambos integrantes queda evidenciada en los commits del repositorio.
