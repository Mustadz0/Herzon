-- Search users by username or display name
CREATE OR REPLACE FUNCTION public.search_users(
  query text,
  page integer default 1,
  page_size integer default 20
)
RETURNS TABLE(
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  bio text
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.username, p.display_name, p.avatar_url, p.bio
  FROM profiles p
  WHERE 
    p.display_name ILIKE '%' || query || '%'
    OR p.username ILIKE '%' || query || '%'
  ORDER BY 
    CASE 
      WHEN p.display_name ILIKE query || '%' THEN 0
      WHEN p.display_name ILIKE '%' || query || '%' THEN 1
      WHEN p.username ILIKE query || '%' THEN 2
      ELSE 3
    END,
    p.display_name ASC
  LIMIT page_size
  OFFSET (page - 1) * page_size;
END;
$$;
