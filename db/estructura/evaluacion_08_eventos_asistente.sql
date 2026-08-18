-- Subdominio: asistente (issue #11)
-- Logs/eventos del asistente. El esquema de "detalle" varía según tipo_evento (no todos los
-- eventos tienen los mismos campos), por eso se modela como JSONB en vez de columnas fijas.
-- conversacion_id referencia a conversaciones_asistente cuando el evento ocurre dentro de una
-- conversación (no todos los eventos la tienen, p. ej. errores de indexación de un documento).

CREATE TABLE IF NOT EXISTS eventos_asistente (
    id               VARCHAR(20) PRIMARY KEY,
    tipo_evento      VARCHAR(40) NOT NULL,
    estudiante_id    VARCHAR(20),            -- FK pendiente -> estudiantes.id
    conversacion_id  VARCHAR(20)
        REFERENCES conversaciones_asistente (id) ON DELETE SET NULL,
    fecha            TIMESTAMPTZ NOT NULL DEFAULT now(),
    detalle          JSONB NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT chk_eventos_detalle_object CHECK (jsonb_typeof(detalle) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_eventos_asistente_tipo ON eventos_asistente (tipo_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_asistente_conversacion ON eventos_asistente (conversacion_id);
CREATE INDEX IF NOT EXISTS idx_eventos_asistente_detalle_gin ON eventos_asistente USING GIN (detalle jsonb_path_ops);
