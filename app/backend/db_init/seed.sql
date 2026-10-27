INSERT INTO sedes (nombre, distrito, capacidad) VALUES
  ('TuCochera Trujillo', 'Trujillo', 60),
  ('TuCochera Lima', 'Miraflores', 60),
  ('TuCochera Arequipa', 'Cercado', 60),
  ('TuCochera Piura', 'Piura', 60),
  ('TuCochera Chiclayo', 'Chiclayo', 60),
  ('TuCochera Tumbes', 'Tumbes', 60),
  ('TuCochera Huancayo', 'Huancayo', 60),
  ('TuCochera Iquitos', 'Iquitos', 60),
  ('TuCochera Tacna', 'Tacna', 60),
  ('TuCochera Cajamarca', 'Cajamarca', 60),
  ('TuCochera Ica', 'Ica', 60),
  ('TuCochera Chimbote', 'Chimbote', 60)
ON CONFLICT (nombre) DO NOTHING;