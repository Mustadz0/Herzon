-- MIGRATION 025: Fix page creation and nearby pages query
-- Adds latitude/longitude to RPC, creates create_page RPC

-- ============================================
-- FIX get_nearby_pages: return lat/lng
-- ============================================
DROP FUNCTION IF EXISTS public.get_nearby_pages(double precision, double precision, double precision, text, integer);

CREATE OR REPLACE FUNCTION public.get_nearby_pages(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 5000, p_category text DEFAULT NULL, p_limit int DEFAULT 20
)
RETURNS TABLE (
  id uuid, owner_id uuid, name text, slug text, category text, description text,
  avatar_url text, banner_url text, contact_email text, contact_phone text,
  website_url text, address text, latitude double precision, longitude double precision,
  is_active boolean, distance_meters double precision, post_count bigint,
  created_at timestamptz, updated_at timestamptz
)
LANGUAGE plpgsql STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.owner_id, p.name, p.slug, p.category, p.description,
    p.avatar_url, p.banner_url, p.contact_email, p.contact_phone,
    p.website_url, p.address,
    ST_Y(p.location::geometry)::double precision,
    ST_X(p.location::geometry)::double precision,
    p.is_active,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision,
    (SELECT count(*) FROM public.posts WHERE actor_id = p.id AND actor_type = 'page'),
    p.created_at, p.updated_at
  FROM public.pages p
  WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    AND p.is_active = true
    AND (p_category IS NULL OR p.category = p_category)
  ORDER BY distance_meters
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_nearby_pages IS 'Returns nearby business pages with lat/lng.';

-- ============================================
-- CREATE PAGE: RPC that sets geography from lat/lng
-- ============================================
CREATE OR REPLACE FUNCTION public.create_page(
  p_name text, p_slug text, p_category text,
  p_description text DEFAULT NULL, p_lat double precision DEFAULT NULL, p_lng double precision DEFAULT NULL,
  p_address text DEFAULT NULL, p_avatar_url text DEFAULT NULL, p_banner_url text DEFAULT NULL,
  p_contact_email text DEFAULT NULL, p_contact_phone text DEFAULT NULL, p_website_url text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  new_page jsonb;
  v_location geography;
BEGIN
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_location := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;
  END IF;

  INSERT INTO public.pages (
    owner_id, name, slug, category, description, location, address,
    avatar_url, banner_url, contact_email, contact_phone, website_url
  ) VALUES (
    auth.uid(), p_name, p_slug, p_category, p_description, v_location, p_address,
    p_avatar_url, p_banner_url, p_contact_email, p_contact_phone, p_website_url
  )
  RETURNING to_jsonb(pages.*) INTO new_page;

  RETURN new_page;
END;
$$;

COMMENT ON FUNCTION public.create_page IS 'Creates a page with geography from lat/lng.';
