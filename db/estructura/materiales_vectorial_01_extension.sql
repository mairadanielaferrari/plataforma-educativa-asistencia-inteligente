-- Subdominio: materiales de estudio, modelo vectorial (issue #12).
-- Extensión pgvector. Es idempotente y compartida con el modelo vectorial del asistente (#13),
-- por eso IF NOT EXISTS: cualquiera de los dos scripts puede crearla.

CREATE EXTENSION IF NOT EXISTS vector;
