-- Integración de subdominios (issue #5)
-- Agrega las claves foráneas cross-subdominio que los modelos de evaluación y asistente (#4, #7,
-- #13) dejaron marcadas como "FK pendiente" hacia las tablas de gestión académica (#6) y
-- materiales (#10). Como los seeds de cada subdominio se cargan por separado y en distinto orden,
-- este script debe correr AL FINAL, después de toda la estructura y todos los datos: agrega las
-- constraints validando el conjunto ya completo.
-- Idempotente: cada constraint se agrega solo si no existe.

DO $$
BEGIN
    -- actividades -> cursos, docentes
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_actividades_curso') THEN
        ALTER TABLE actividades ADD CONSTRAINT fk_actividades_curso
            FOREIGN KEY (curso_id) REFERENCES cursos (id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_actividades_docente') THEN
        ALTER TABLE actividades ADD CONSTRAINT fk_actividades_docente
            FOREIGN KEY (docente_id) REFERENCES docentes (id);
    END IF;

    -- entregas -> estudiantes
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_entregas_estudiante') THEN
        ALTER TABLE entregas ADD CONSTRAINT fk_entregas_estudiante
            FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id);
    END IF;

    -- calificaciones -> docentes
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_calificaciones_docente') THEN
        ALTER TABLE calificaciones ADD CONSTRAINT fk_calificaciones_docente
            FOREIGN KEY (docente_id) REFERENCES docentes (id);
    END IF;

    -- progreso_academico -> estudiantes, cursos
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_progreso_estudiante') THEN
        ALTER TABLE progreso_academico ADD CONSTRAINT fk_progreso_estudiante
            FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_progreso_curso') THEN
        ALTER TABLE progreso_academico ADD CONSTRAINT fk_progreso_curso
            FOREIGN KEY (curso_id) REFERENCES cursos (id);
    END IF;

    -- conversaciones_asistente -> estudiantes, cursos (curso opcional)
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_conversaciones_estudiante') THEN
        ALTER TABLE conversaciones_asistente ADD CONSTRAINT fk_conversaciones_estudiante
            FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_conversaciones_curso') THEN
        ALTER TABLE conversaciones_asistente ADD CONSTRAINT fk_conversaciones_curso
            FOREIGN KEY (curso_id) REFERENCES cursos (id);
    END IF;

    -- eventos_asistente -> estudiantes (opcional)
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_eventos_estudiante') THEN
        ALTER TABLE eventos_asistente ADD CONSTRAINT fk_eventos_estudiante
            FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id);
    END IF;

    -- consultas_frecuentes_embeddings -> cursos (opcional; NULL = pregunta general)
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_consultas_frecuentes_curso') THEN
        ALTER TABLE consultas_frecuentes_embeddings ADD CONSTRAINT fk_consultas_frecuentes_curso
            FOREIGN KEY (curso_id) REFERENCES cursos (id);
    END IF;
END $$;
