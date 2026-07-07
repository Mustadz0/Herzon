-- MIGRATION 027: Fix get_nearby_pages to include NULL-location pages
-- Pages created without GPS should still appear in the list

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
    CASE WHEN p.location IS NOT NULL THEN ST_Y(p.location::geometry)::double precision ELSE NULL END,
    CASE WHEN p.location IS NOT NULL THEN ST_X(p.location::geometry)::double precision ELSE NULL END,
    p.is_active,
    CASE WHEN p.location IS NOT NULL THEN
      ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision
    ELSE 999999.0 END,
    (SELECT count(*) FROM public.posts WHERE actor_id = p.id AND actor_type = 'page'),
    p.created_at, p.updated_at
  FROM public.pages p
  WHERE p.is_active = true
    AND (p_category IS NULL OR p.category = p_category)
    AND (
      p.location IS NULL
      OR ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    )
  ORDER BY
    CASE WHEN p.location IS NULL THEN 0 ELSE 1 END,
    distance_meters
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_nearby_pages IS 'Returns nearby business pages. Includes pages without location (sorted last).';
