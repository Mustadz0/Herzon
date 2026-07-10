-- ============================================================
-- Migration 039 — Seed zones (données géographiques initiales)
-- Zones de test couvrant les grandes villes
-- ============================================================

INSERT INTO zones (name, description, location, radius_meters, is_active)
VALUES
  -- Algérie
  ('Alger Centre',      'Zone principale d''Alger',           ST_SetSRID(ST_MakePoint(3.0588, 36.7372), 4326), 2000, true),
  ('Bab El Oued',       'Quartier populaire d''Alger',        ST_SetSRID(ST_MakePoint(3.0500, 36.7800), 4326), 1500, true),
  ('Hydra',             'Zone résidentielle Hydra',           ST_SetSRID(ST_MakePoint(3.0300, 36.7450), 4326), 1200, true),
  ('Oran Centre',       'Zone principale d''Oran',            ST_SetSRID(ST_MakePoint(-0.6417, 35.6969), 4326), 2000, true),
  ('Constantine',       'Zone principale de Constantine',     ST_SetSRID(ST_MakePoint(6.6147, 36.3650), 4326), 2000, true),
  ('Annaba',            'Zone principale d''Annaba',          ST_SetSRID(ST_MakePoint(7.7667, 36.9000), 4326), 1800, true),
  ('Tlemcen',           'Zone principale de Tlemcen',         ST_SetSRID(ST_MakePoint(-1.3147, 34.8800), 4326), 1500, true),
  ('Sétif',             'Zone principale de Sétif',           ST_SetSRID(ST_MakePoint(5.4109, 36.1898), 4326), 1500, true),
  ('Blida',             'Zone principale de Blida',           ST_SetSRID(ST_MakePoint(2.8288, 36.4700), 4326), 1500, true),
  ('Béjaïa',            'Zone principale de Béjaïa',          ST_SetSRID(ST_MakePoint(5.0836, 36.7508), 4326), 1500, true),

  -- France
  ('Paris 1er',         'Zone centre de Paris',               ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326), 1500, true),
  ('Paris 18e',         'Montmartre',                         ST_SetSRID(ST_MakePoint(2.3409, 48.8867), 4326), 1200, true),
  ('Lyon Centre',       'Zone principale de Lyon',            ST_SetSRID(ST_MakePoint(4.8357, 45.7640), 4326), 1800, true),
  ('Marseille Centre',  'Zone principale de Marseille',       ST_SetSRID(ST_MakePoint(5.3698, 43.2965), 4326), 1800, true),
  ('Toulouse Centre',   'Zone principale de Toulouse',        ST_SetSRID(ST_MakePoint(1.4442, 43.6047), 4326), 1500, true),
  ('Nice Centre',       'Zone principale de Nice',            ST_SetSRID(ST_MakePoint(7.2620, 43.7102), 4326), 1500, true),

  -- Maroc
  ('Casablanca Centre', 'Zone principale de Casablanca',      ST_SetSRID(ST_MakePoint(-7.5898, 33.5731), 4326), 2000, true),
  ('Rabat Centre',      'Zone principale de Rabat',           ST_SetSRID(ST_MakePoint(-6.8498, 33.9716), 4326), 1800, true),
  ('Marrakech Medina',  'Zone médina de Marrakech',           ST_SetSRID(ST_MakePoint(-7.9811, 31.6295), 4326), 1500, true),

  -- Tunisie
  ('Tunis Centre',      'Zone principale de Tunis',           ST_SetSRID(ST_MakePoint(10.1815, 36.8065), 4326), 2000, true),
  ('Sfax Centre',       'Zone principale de Sfax',            ST_SetSRID(ST_MakePoint(10.7603, 34.7400), 4326), 1500, true)

ON CONFLICT DO NOTHING;
