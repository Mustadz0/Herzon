-- MIGRATION 011: Multi-accounts / Pages
-- Support for user-managed business/personal pages

-- ============================================
-- PAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS pages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  slug text NOT NULL UNIQUE, -- e.g., "chez-ahmed-kebabs"
  category text, -- 'restaurant', 'shop', 'service', etc.
  description text,
  avatar_url text,
  banner_url text,
  contact_email text,
  contact_phone text,
  website_url text,
  location geography(POINT, 4326),
  address text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE pages IS 'Business or personal pages owned by users.';

-- Enable RLS
ALTER TABLE pages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "All pages are viewable"
  ON pages FOR SELECT USING (true);

CREATE POLICY "Page owners can manage own pages"
  ON pages FOR ALL USING (auth.uid() = owner_id);

-- Indexes
CREATE INDEX IF NOT EXISTS pages_owner_idx ON pages(owner_id);
CREATE INDEX IF NOT EXISTS pages_slug_idx ON pages(slug);
CREATE INDEX IF NOT EXISTS pages_location_idx ON pages USING GIST(location);
CREATE INDEX IF NOT EXISTS pages_category_idx ON pages(category) WHERE is_active = true;

-- ============================================
-- POSTS: support page posting
-- ============================================
-- Add actor_type and actor_id to posts to track who/what posted
ALTER TABLE posts ADD COLUMN IF NOT EXISTS actor_type text DEFAULT 'user' CHECK (actor_type IN ('user', 'page'));
ALTER TABLE posts ADD COLUMN IF NOT EXISTS actor_id uuid; -- references profiles.id or pages.id

-- For simplicity, actor_id always stores profiles.id for users, pages.id for pages
-- but queries should handle both. Adding a helper view instead.

CREATE OR REPLACE VIEW post_actors AS
SELECT 
  p.id,
  p.user_id,
  p.actor_type,
  p.actor_id,
  COALESCE(pag.name, pr.display_name) AS display_name,
  COALESCE(pag.avatar_url, pr.avatar_url) AS avatar_url
FROM posts p
LEFT JOIN profiles pr ON p.user_id = pr.id
LEFT JOIN pages pag ON p.actor_id = pag.id AND p.actor_type = 'page'
WHERE p.actor_type = 'page' OR (p.actor_type = 'user' AND p.user_id = pr.id);

-- ============================================
-- PAGE MEMBERS (for co-managed pages)
-- ============================================
CREATE TABLE IF NOT EXISTS page_members (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  page_id uuid NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'editor' CHECK (role IN ('editor', 'admin')),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(page_id, user_id)
);

COMMENT ON TABLE page_members IS 'Users who can post/manage on behalf of a page.';

ALTER TABLE page_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Page owners and members can view members"
  ON page_members FOR SELECT USING (
    auth.uid() IN (SELECT owner_id FROM pages WHERE id = page_id)
    OR auth.uid() = user_id
  );

CREATE POLICY "Page owners can manage members"
  ON page_members FOR ALL USING (
    auth.uid() IN (SELECT owner_id FROM pages WHERE id = page_id)
  );

-- RPC: get nearby pages
CREATE OR REPLACE FUNCTION get_nearby_pages(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_meters double precision DEFAULT 5000,
  p_category text DEFAULT NULL,
  p_limit int DEFAULT 20
)
RETURNS TABLE (
  id uuid,
  owner_id uuid,
  name text,
  slug text,
  category text,
  description text,
  avatar_url text,
  banner_url text,
  contact_email text,
  contact_phone text,
  website_url text,
  address text,
  distance_meters double precision,
  post_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.owner_id,
    p.name,
    p.slug,
    p.category,
    p.description,
    p.avatar_url,
    p.banner_url,
    p.contact_email,
    p.contact_phone,
    p.website_url,
    p.address,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision AS distance_meters,
    (SELECT count(*) FROM posts WHERE posts.actor_id = p.id AND posts.actor_type = 'page') AS post_count
  FROM pages p
  WHERE ST_DWithin(
    p.location,
    ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
    p_radius_meters
  )
  AND p.is_active = true
  AND (p_category IS NULL OR p.category = p_category)
  ORDER BY distance_meters
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION get_nearby_pages IS 'Returns nearby business pages.';