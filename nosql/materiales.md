# Modelo documental (JSONB): materiales de estudio

> Issue [#10](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/10).
> Implementación en [`db/estructura/materiales_01_materiales.sql`](../db/estructura/materiales_01_materiales.sql),
> datos en [`db/datos/materiales_seed.sql`](../db/datos/materiales_seed.sql) y consultas en
> [`db/consultas/materiales_consultas.sql`](../db/consultas/materiales_consultas.sql). Probado
> contra el Postgres del `docker-compose.yml`. El modelo vectorial de los fragmentos de estos
> materiales (para el RAG del asistente) es la issue #12.

## 1. Por qué documental y no puramente relacional

Un material de estudio tiene una parte común a todos (curso, autor, título, fecha, nivel de
acceso) y una parte que **cambia según el tipo**: un video tiene `duracion_min` y `url`, una
normativa una `vigencia_desde` y un ámbito, un apunte una lista de `temas`, una FAQ un array de
`preguntas`. Modelar todo eso con columnas fijas dejaría la mayoría en NULL en cada fila y
obligaría a un `ALTER TABLE` cada vez que aparece un tipo nuevo de material. Un campo `metadata`
**JSONB** absorbe esa variabilidad sin migraciones y permite indexar y consultar el contenido.

Se implementa **sobre PostgreSQL** (no una base documental separada como MongoDB), en línea con
la tecnología multi-modelo del equipo (justificación en la issue #16): una única base, con
transacciones ACID entre la parte relacional (curso, autor) y la documental (metadata), y
`pgvector` en el mismo motor para el modelo vectorial (#12).

## 2. Columnas promovidas vs. `metadata` JSONB

- **Columnas promovidas** (fuera del JSONB, porque se filtran o se referencian en casi toda
  consulta y participan de la integridad): `id`, `curso_id`, `autor_id`, `titulo`, `tipo`,
  `nivel_acceso`, `version`, `fecha_publicacion`. `curso_id` y `autor_id` son claves foráneas
  reales a `cursos` y `docentes` (#6).
- **`metadata` (JSONB)**: los atributos propios de cada tipo. Ejemplos del seed:

```json
// apunte
{ "formato": "pdf", "paginas": 12, "idioma": "es", "temas": ["normalizacion", "3FN"] }
// video
{ "formato": "mp4", "duracion_min": 18, "url": "...", "subtitulos": true, "temas": ["join"] }
// faq
{ "formato": "html", "preguntas": [ { "q": "Como entrego?", "a": "Desde Actividades..." } ] }
// normativa
{ "formato": "pdf", "vigencia_desde": "2026-01-01", "ambito": "docente", "confidencial": true }
```

## 3. Embebido vs. referencia

| Relación | Decisión | Motivo |
|---|---|---|
| Material atributos por tipo (temas, preguntas, duración) | **Embebido** en `metadata` | Varían por tipo, se leen junto con el material y no se consultan de forma aislada. |
| Material a Curso / Autor | **Referencia** (`curso_id`, `autor_id`) | Entidades con identidad e integridad propia del subdominio de gestión académica (#6). |
| Material a sus fragmentos vectorizados | **Referencia** (issue #12) | El fragmento y su embedding tienen su propia tabla para el RAG; el material es la fuente de la que se derivan. |

## 4. Índices

- `idx_materiales_curso` (B-tree sobre `curso_id`): filtro habitual "materiales de mi curso".
- `idx_materiales_metadata_gin` (GIN con `jsonb_path_ops` sobre `metadata`): soporta consultas de
  contención `@>` como "materiales que tratan el tema normalizacion" sin escanear y parsear el
  JSONB de cada fila.

> Nota sobre el plan: con el volumen del seed (pocas filas) el planificador elige un `Seq Scan` en
> lugar del índice GIN, que es la decisión correcta a esa escala. El índice empieza a usarse cuando
> el volumen de materiales por curso crece lo suficiente; el diseño ya lo deja creado para que la
> transición sea automática, sin cambiar la consulta (se retoma en la issue #16).

## 5. Consultas de ejemplo

Ver [`db/consultas/materiales_consultas.sql`](../db/consultas/materiales_consultas.sql):

1. Extraer campos escalares del JSONB (`->>`) filtrando lo no restringido.
2. Buscar por tema con contención (`@>`, aprovecha el índice GIN).
3. Aplanar el array de `preguntas` de una FAQ (`jsonb_array_elements`).
4. Listar materiales restringidos (control de acceso: no deben vectorizarse para el estudiante).
5. Componer cantidad de materiales por tipo y curso.

## 6. Frontera con el asistente (integración issue #5)

El asistente cita materiales como fuente por `documento_id` / `material_id` (ver
[`../nosql/asistente.md`](asistente.md) y el modelo vectorial #13). Esta tabla `materiales` es el
dueño de esos identificadores: en la integración (#5) el `material_id` de las tablas del asistente
pasa a ser una clave foránea real a `materiales.id`. El `nivel_acceso = restringido` (p. ej.
`mat-099`) es la marca que impide que un material llegue al estudiante a través del RAG (issue #14).
