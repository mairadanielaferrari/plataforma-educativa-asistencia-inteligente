# Plataforma educativa con asistencia inteligente

Trabajo Práctico Integrador de Bases de Datos para Inteligencia Artificial (CEIA, 2026).

Diseño de la capa de datos para una plataforma educativa que ofrece asistencia
personalizada a estudiantes a partir de su actividad académica (caso de uso #9).

## Integrantes

- Maira Ferrari
- Sebastián Pardo

## Tecnología propuesta

Solución multi-modelo sobre PostgreSQL (a justificar en el informe):

- **Relacional**: núcleo académico (estudiantes, docentes, cursos, inscripciones, actividades, evaluaciones, entregas, calificaciones, roles).
- **Documental (JSONB)**: contenido semiestructurado (materiales de estudio, conversaciones y logs del asistente).
- **Vectorial (pgvector)**: embeddings para la búsqueda semántica del asistente (RAG).

## Estructura del repositorio

```
docs/                informe y diagramas (conceptual, lógico, físico, arquitectura)
data/ejemplos/       datos de ejemplo
db/
  estructura/        DDL (creación de tablas)
  datos/             seeds / datos de ejemplo
  consultas/         consultas SQL
  indices_vistas/    índices y vistas
nosql/               modelo documental (JSONB)
vectorial/           modelo vectorial (pgvector)
anexos/              material complementario
```

## Cómo correr

El entorno se levanta con Docker (Postgres + pgvector + pgAdmin):

```bash
cp .env.example .env
docker compose up -d
```

pgAdmin queda en <http://localhost:8080> (o el puerto de `.env`). Dentro de Docker, el host de la base es `postgres`.

## Organización del trabajo

Las tareas están en los **Issues** del repositorio, repartidas entre los integrantes.
