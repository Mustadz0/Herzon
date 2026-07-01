CREATE TABLE IF NOT EXISTS public.marketplace_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text DEFAULT '',
  price numeric(10,2),
  currency text DEFAULT 'DZD',
  category text NOT NULL,
  images text[] DEFAULT '{}',
  location geography(Point, 4326) NOT NULL,
  status text DEFAULT 'active' CHECK (status IN ('active', 'sold', 'removed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS marketplace_items_user_id_idx ON public.marketplace_items (user_id);
CREATE INDEX IF NOT EXISTS marketplace_items_status_idx ON public.marketplace_items (status);
CREATE INDEX IF NOT EXISTS marketplace_items_category_idx ON public.marketplace_items (category);

ALTER TABLE public.marketplace_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active items"
  ON public.marketplace_items FOR SELECT
  USING (status = 'active' OR user_id = auth.uid());

CREATE POLICY "Users can insert their own items"
  ON public.marketplace_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own items"
  ON public.marketplace_items FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own items"
  ON public.marketplace_items FOR DELETE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.get_nearby_marketplace_items(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000,
  filter_category text default null,
  page integer default 1,
  page_size integer default 20
)
RETURNS TABLE(
  id uuid,
  user_id uuid,
  title text,
  description text,
  price numeric,
  currency text,
  item_category text,
  images text[],
  status text,
  created_at timestamptz,
  username text,
  display_name text,
  avatar_url text,
  distance double precision
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    mi.id,
    mi.user_id,
    mi.title,
    mi.description,
    mi.price,
    mi.currency,
    mi.category as item_category,
    mi.images,
    mi.status,
    mi.created_at,
    p.username,
    p.display_name,
    p.avatar_url,
    ST_DistanceSphere(
      mi.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance
  FROM marketplace_items mi
  JOIN profiles p ON p.id = mi.user_id
  WHERE mi.status = 'active'
    AND (filter_category IS NULL OR mi.category = filter_category)
    AND ST_DWithin(
      mi.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_meters
    )
  ORDER BY mi.created_at DESC
  LIMIT page_size
  OFFSET (page - 1) * page_size;
END;
$$;
