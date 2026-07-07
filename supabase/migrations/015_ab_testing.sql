-- MIGRATION 015: A/B Testing + Feature Flags
-- Adds experiment tracking and user assignment

-- ============================================
-- EXPERIMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS experiments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL UNIQUE,
  description text,
  variants jsonb NOT NULL DEFAULT '[]', -- array of {name, value, weight}
  is_active boolean DEFAULT true,
  start_date timestamptz DEFAULT now(),
  end_date timestamptz,
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE experiments IS 'A/B test experiments with variants and weights.';

ALTER TABLE experiments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All experiments are viewable"
  ON experiments FOR SELECT USING (true);

-- Seed some default experiments
INSERT INTO experiments (name, description, variants) 
VALUES ('home_screen_layout', 'Test different home screen layouts', '[{"name": "default", "value": "tabs", "weight": 0.5}, {"name": "sidebar", "value": "drawer", "weight": 0.5}]')
ON CONFLICT (name) DO NOTHING;

INSERT INTO experiments (name, description, variants) 
VALUES ('reaction_style', 'Test different reaction button styles', '[{"name": "chips", "value": "chips", "weight": 0.5}, {"name": "icon_buttons", "value": "icons", "weight": 0.5}]')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- EXPERIMENT ASSIGNMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS experiment_assignments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  experiment_id uuid NOT NULL REFERENCES experiments(id) ON DELETE CASCADE,
  variant_name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, experiment_id)
);

COMMENT ON TABLE experiment_assignments IS 'User assignments to A/B test variants.';

ALTER TABLE experiment_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own assignments"
  ON experiment_assignments FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS experiment_assignments_user_idx ON experiment_assignments(user_id);
CREATE INDEX IF NOT EXISTS experiment_assignments_experiment_idx ON experiment_assignments(experiment_id);

-- ============================================
-- FEATURE CONFIG
-- ============================================
CREATE TABLE IF NOT EXISTS feature_config (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL DEFAULT '{}',
  description text,
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE feature_config IS 'Remote feature flags and config values.';

ALTER TABLE feature_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All feature config is viewable"
  ON feature_config FOR SELECT USING (true);

-- Seed default feature flags
INSERT INTO feature_config (key, value, description) 
VALUES 
  ('show_ridesharing', '{"enabled": false, "regions": ["all"]}', 'Enable ride sharing tab'),
  ('show_polls', '{"enabled": true, "regions": ["all"]}', 'Enable polls in posts'),
  ('show_pages', '{"enabled": false, "regions": ["all"]}', 'Enable multi-account pages'),
  ('show_gamification', '{"enabled": true, "regions": ["all"]}', 'Enable XP + leaderboard'),
  ('max_post_length', '{"value": 500}', 'Maximum post character length'),
  ('nearby_radius', '{"value": 2000}', 'Nearby post radius in meters')
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- RPC: ASSIGN USER TO EXPERIMENT
-- ============================================
CREATE OR REPLACE FUNCTION assign_user_to_experiment(
  p_experiment_id uuid
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  variants jsonb;
  selected_variant text;
  total_weight float;
  rand float;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Check if already assigned
  SELECT variant_name INTO selected_variant
  FROM experiment_assignments
  WHERE user_id = current_user_id AND experiment_id = p_experiment_id;

  IF selected_variant IS NOT NULL THEN
    RETURN selected_variant;
  END IF;

  -- Pick a variant based on weights
  SELECT variants INTO variants FROM experiments WHERE id = p_experiment_id;
  IF variants IS NULL OR jsonb_array_length(variants) = 0 THEN
    RAISE EXCEPTION 'Experiment not found or has no variants';
  END IF;

  SELECT SUM((v->>'weight')::float) INTO total_weight 
  FROM jsonb_array_elements(variants) AS v;

  SELECT random() INTO rand;

  -- Simple weighted selection
  WITH variant_rows AS (
    SELECT v->>'name' AS vname, (v->>'weight')::float / total_weight AS weight,
           SUM((v->>'weight')::float / total_weight) OVER (ORDER BY idx) AS cumulative
    FROM jsonb_array_elements(variants) WITH ORDINALITY AS e(v, idx)
  )
  SELECT vname INTO selected_variant
  FROM variant_rows
  WHERE cumulative >= rand
  ORDER BY cumulative
  LIMIT 1;

  -- Insert assignment
  INSERT INTO experiment_assignments (user_id, experiment_id, variant_name)
  VALUES (current_user_id, p_experiment_id, selected_variant);

  RETURN selected_variant;
END;
$$;

-- ============================================
-- RPC: GET USER FEATURE FLAGS
-- ============================================
CREATE OR REPLACE FUNCTION get_user_feature_flags()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT jsonb_object_agg(key, value) FROM feature_config;
$$;

-- ============================================
-- RPC: GET USER EXPERIMENTS
-- ============================================
CREATE OR REPLACE FUNCTION get_user_experiments()
RETURNS TABLE (experiment_name text, variant_name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT 
    e.name AS experiment_name,
    ea.variant_name
  FROM experiment_assignments ea
  JOIN experiments e ON ea.experiment_id = e.id
  WHERE ea.user_id = auth.uid();
$$;
