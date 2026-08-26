# Modelo conceptual: evaluación y asistente (parte B del ER)

> Issue [#4](https://github.com/mairadanielaferrari/plataforma-educativa-asistencia-inteligente/issues/4).
> Cubre el subdominio de **evaluación** (actividades, entregas, calificaciones, progreso) y
> **asistente** (consultas, conversaciones, fuentes, recomendaciones, auditoría), a partir del
> relevamiento de [`relevamiento_datos.md`](relevamiento_datos.md). Las entidades marcadas como
> *externas* pertenecen al subdominio de gestión académica y materiales de estudio (issue #3,
> Maira) y se integran en la issue #5 — acá se modelan solo como referencias.

## 1. Diagrama entidad-relación (parte B)

```mermaid
erDiagram
    ESTUDIANTE {
        string id PK
    }
    DOCENTE {
        string id PK
    }
    CURSO {
        string id PK
    }
    MATERIAL {
        string id PK
    }

    ACTIVIDAD {
        string id PK
        string curso_id FK
        string docente_id FK
        string titulo
        string tipo
        date fecha_publicacion
        datetime fecha_limite
        string estado
        boolean permite_reentrega
    }
    EVALUACION {
        string id PK
        string actividad_id FK
        string titulo
        string tipo
        string modalidad
        date fecha
        decimal ponderacion
        string[] criterios_evaluacion
    }
    ENTREGA {
        string id PK
        string estudiante_id FK
        string actividad_id FK
        datetime fecha_entrega
        int intento
        string archivo_url
        string estado
        boolean fuera_de_termino
    }
    CALIFICACION {
        string id PK
        string entrega_id FK
        string docente_id FK
        decimal nota
        string escala
        string feedback
        datetime fecha_correccion
        boolean revisada
    }
    PROGRESO_ACADEMICO {
        string id PK
        string estudiante_id FK
        string curso_id FK
        string periodo
        int actividades_completadas
        int actividades_totales
        decimal promedio_notas
        decimal porcentaje_avance
        boolean en_riesgo
    }
    CONVERSACION_ASISTENTE {
        string id PK
        string estudiante_id FK
        string curso_id FK
        datetime fecha_inicio
        datetime fecha_fin
        string canal
        int calificacion_satisfaccion
        boolean derivada_a_docente
    }
    MENSAJE {
        string conversacion_id FK
        string rol
        string texto
        datetime timestamp
    }
    FUENTE_UTILIZADA {
        string mensaje_ref
        string documento_id FK
        string fragmento_id
        decimal similitud
    }
    CONSULTA_ASISTENTE {
        string id PK
        string estudiante_id FK
        string curso_id FK
        string conversacion_id FK
        string texto_consulta
        datetime fecha
        string canal
    }
    RECOMENDACION_ESTUDIO {
        string id PK
        string estudiante_id FK
        string curso_id FK
        string material_id FK
        string tipo
        string motivo
        string generada_por
        boolean vista_por_estudiante
    }
    EVENTO_AUDITORIA {
        string id PK
        string tipo_evento
        string entidad_afectada
        string entidad_id
        string usuario_id FK
        string rol
        datetime fecha
        json detalle
    }

    CURSO ||--o{ ACTIVIDAD : incluye
    DOCENTE ||--o{ ACTIVIDAD : publica
    ACTIVIDAD |o--o| EVALUACION : "es evaluada por"
    ACTIVIDAD ||--o{ ENTREGA : recibe
    ESTUDIANTE ||--o{ ENTREGA : realiza
    ENTREGA |o--o| CALIFICACION : tiene
    DOCENTE ||--o{ CALIFICACION : corrige
    ESTUDIANTE ||--o{ PROGRESO_ACADEMICO : acumula
    CURSO ||--o{ PROGRESO_ACADEMICO : mide
    ESTUDIANTE ||--o{ CONVERSACION_ASISTENTE : inicia
    CURSO ||--o{ CONVERSACION_ASISTENTE : contextualiza
    CONVERSACION_ASISTENTE ||--o{ MENSAJE : contiene
    MENSAJE ||--o{ FUENTE_UTILIZADA : cita
    FUENTE_UTILIZADA }o--|| MATERIAL : referencia
    ESTUDIANTE ||--o{ CONSULTA_ASISTENTE : realiza
    CONSULTA_ASISTENTE }o--|| CONVERSACION_ASISTENTE : "pertenece a"
    ESTUDIANTE ||--o{ RECOMENDACION_ESTUDIO : recibe
    RECOMENDACION_ESTUDIO }o--o| MATERIAL : sugiere
    ESTUDIANTE ||--o{ EVENTO_AUDITORIA : origina
    DOCENTE ||--o{ EVENTO_AUDITORIA : origina
```

## 2. Entidades y atributos relevantes

| Entidad | Atributos principales |
|---|---|
| `Actividad` | id, curso_id, docente_id, titulo, tipo (practico/parcial/foro/cuestionario/proyecto), fecha_publicacion, fecha_limite, estado, permite_reentrega |
| `Evaluacion` | id, actividad_id, titulo, tipo, modalidad, fecha, ponderacion, criterios_evaluacion |
| `Entrega` | id, estudiante_id, actividad_id, fecha_entrega, intento, archivo_url, estado, fuera_de_termino, comentario_estudiante |
| `Calificacion` | id, entrega_id, docente_id, nota, escala, feedback, fecha_correccion, revisada |
| `ProgresoAcademico` | id, estudiante_id, curso_id, periodo, actividades_completadas/totales, promedio_notas, porcentaje_avance, en_riesgo |
| `ConversacionAsistente` | id, estudiante_id, curso_id, fecha_inicio/fin, canal, calificacion_satisfaccion, derivada_a_docente |
| `Mensaje` (débil, embebido en Conversación) | rol (estudiante/asistente), texto, timestamp |
| `FuenteUtilizada` (débil, embebida en Mensaje) | documento_id, fragmento_id, similitud |
| `ConsultaAsistente` *(fuera de alcance / diferida)* | id, estudiante_id, curso_id, conversacion_id, texto_consulta, fecha, canal |
| `RecomendacionEstudio` *(fuera de alcance / diferida)* | id, estudiante_id, curso_id, material_id, tipo, motivo, generada_por, vista_por_estudiante |
| `EventoAuditoria` → tabla `eventos_auditoria` | id, tipo_evento, entidad_afectada, entidad_id, usuario_id, rol, fecha, detalle |

> **Alcance de implementación.** `EventoAuditoria` se implementa en
> [`db/estructura/evaluacion_09_eventos_auditoria.sql`](../db/estructura/evaluacion_09_eventos_auditoria.sql)
> como tabla `eventos_auditoria` (distinta de `eventos_asistente`, que es el log operativo del
> asistente). En cambio `ConsultaAsistente` y `RecomendacionEstudio` quedan **fuera de alcance /
> diferidas**: se modelan a nivel conceptual pero no se crean como tablas en esta entrega (no hay
> consultas que las requieran todavía; ver sección 5 para `ConsultaAsistente`).

## 3. Relaciones y cardinalidades

- **Curso 1:N Actividad** — un curso publica muchas actividades.
- **Docente 1:N Actividad** — un docente publica muchas actividades; una actividad tiene un único docente responsable.
- **Actividad 1:0..1 Evaluación** — no toda actividad es evaluable; una evaluación pertenece a una única actividad.
- **Actividad 1:N Entrega**, **Estudiante 1:N Entrega** — un estudiante puede tener varias entregas (reintentos) por actividad.
- **Entrega 1:0..1 Calificación** — una entrega tiene a lo sumo una calificación vigente.
- **Docente 1:N Calificación** — un docente corrige muchas entregas.
- **Estudiante 1:N ProgresoAcademico**, **Curso 1:N ProgresoAcademico** — un registro de progreso por estudiante, curso y período.
- **Estudiante 1:N ConversacionAsistente**, **Curso 0..1:N ConversacionAsistente** (opcional).
- **ConversacionAsistente 1:N Mensaje** — relación de composición (entidad débil, sin existencia propia).
- **Mensaje 1:N FuenteUtilizada**, **FuenteUtilizada N:1 Material** — solo los mensajes del asistente tienen fuentes.
- **ConsultaAsistente N:1 ConversacionAsistente** — cada consulta individual pertenece a una conversación.
- **Estudiante 1:N RecomendacionEstudio**, **RecomendacionEstudio N:0..1 Material**.
- **EventoAuditoria N:1 Usuario** (Estudiante o Docente, referencia polimórfica) y referencia genérica no tipada (`entidad_afectada` + `entidad_id`) a cualquier otra entidad del subdominio.

## 4. Restricciones del dominio

- La `nota` de una `Calificacion` debe estar dentro del rango de su `escala` (p. ej. 0–10).
- Una `Entrega` fuera de término (`fuera_de_termino = true`) solo es válida si `Actividad.permite_reentrega = true` o existe justificación docente.
- Un docente no puede calificar entregas de actividades que no le pertenecen.
- Toda modificación de `Calificacion` debe generar un `EventoAuditoria` (fila en `eventos_auditoria` con `tipo_evento = cambio_calificacion`), en la misma transacción.
- El asistente solo puede citar como `FuenteUtilizada` materiales a los que el estudiante consultante tiene acceso (riesgo relevado en `relevamiento_datos.md`, resuelto en la arquitectura de seguridad #14/#15).
- Cuando el asistente no puede resolver una consulta con la información disponible, debe marcar `ConversacionAsistente.derivada_a_docente = true` en lugar de generar una respuesta sin fuente.

## 5. Decisión de diseño: `ConsultaAsistente` vs. `ConversacionAsistente`

Se modelan como dos entidades relacionadas y no una sola, de forma deliberada:

- `ConversacionAsistente` es el registro semiestructurado completo (mensajes y fuentes
  embebidos) pensado para el modelo documental JSONB (issue #11) y para reconstruir el
  historial de una interacción.
- `ConsultaAsistente` es una proyección relacional liviana de cada consulta individual,
  pensada para las consultas SQL analíticas del subdominio (issue #9: por ejemplo, "consultas
  por curso" o "temas más consultados") sin tener que parsear JSONB en cada query. Queda
  **fuera de alcance / diferida** en esta entrega: no se crea como tabla porque ninguna consulta
  actual la requiere (las agregaciones se resuelven sobre `conversaciones_asistente` con JSONB).

Esta duplicación controlada se justificará con más detalle (ventajas/costos de mantenerla
sincronizada) en las decisiones de normalización/desnormalización de la issue #16.

## 6. Pendiente de integración (issue #5)

- Definición completa de `Estudiante`, `Docente`, `Curso`, `Material` (atributos, PK) — a
  cargo del modelo conceptual de gestión académica (issue #3).
- Unificación de este diagrama con la parte A en un único ER (`docs/modelo_conceptual.png` o
  `.md` equivalente).
