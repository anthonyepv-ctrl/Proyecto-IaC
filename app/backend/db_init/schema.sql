CREATE TABLE IF NOT EXISTS sedes (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL UNIQUE,
  distrito TEXT NOT NULL,
  capacidad INTEGER NOT NULL CHECK (capacidad > 0)
);

CREATE TABLE IF NOT EXISTS reservas (
  id BIGSERIAL PRIMARY KEY,
  sede_id INTEGER NOT NULL REFERENCES sedes(id),
  placa TEXT NOT NULL,
  inicio TIMESTAMPTZ NOT NULL,
  fin TIMESTAMPTZ NOT NULL,
  estado TEXT NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa','cancelada')),
  creada_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (fin > inicio)
);

CREATE INDEX IF NOT EXISTS idx_reservas_sede_tiempo ON reservas (sede_id, inicio, fin);