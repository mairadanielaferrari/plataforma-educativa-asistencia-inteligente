-- Subdominio: evaluación y asistente (issue #7)
-- Registro de auditoría de acciones sensibles de la plataforma (cambios de calificación, accesos,
-- acciones administrativas). Es la implementación de la entidad EVENTO_AUDITORIA del modelo
-- conceptual (docs/modelo_conceptual_evaluacion_asistente.md) y NO debe confundirse con
-- eventos_asistente (evaluacion_08), que es el log operativo del asistente de IA.
--
-- La regla de dominio "toda modificación de una calificación genera un evento cambio_calificacion"
-- (misma transacción, todo o nada) se materializa en esta tabla.
--
-- El esquema de "detalle" varía según tipo_evento (p. ej. cambio_calificacion guarda nota_anterior
-- /nota_nueva), por eso se modela como JSONB en vez de columnas fijas. entidad_afectada + entidad_id
-- son una referencia genérica no tipada a la fila auditada (calificaciones, materiales, etc.).
--
-- FK pendiente de integración (issue #5): usuario_id -> usuarios.id (cross-subdominio, se agrega en
-- db/integracion/integracion_01_fks.sql).

CREATE TABLE IF NOT EXISTS eventos_auditoria (
    id                VARCHAR(20) PRIMARY KEY,
    tipo_evento       VARCHAR(40) NOT NULL,
    usuario_id        VARCHAR(20),            -- FK pendiente -> usuarios.id
    rol               VARCHAR(30),
    entidad_afectada  VARCHAR(60),
    entidad_id        VARCHAR(40),
    fecha             TIMESTAMPTZ NOT NULL DEFAULT now(),
    detalle           JSONB NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT chk_eventos_auditoria_detalle_object CHECK (jsonb_typeof(detalle) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_eventos_auditoria_tipo ON eventos_auditoria (tipo_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_auditoria_usuario ON eventos_auditoria (usuario_id);
CREATE INDEX IF NOT EXISTS idx_eventos_auditoria_entidad ON eventos_auditoria (entidad_afectada, entidad_id);
CREATE INDEX IF NOT EXISTS idx_eventos_auditoria_detalle_gin ON eventos_auditoria USING GIN (detalle jsonb_path_ops);
