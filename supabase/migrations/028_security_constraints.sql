-- MIGRATION 028: Security constraints for pages
-- Geographic bounds + slug validation

-- Algeria geographic bounds
ALTER TABLE public.pages
  ADD CONSTRAINT valid_algeria_coordinates
  CHECK (
    location IS NULL OR (
      ST_X(location::geometry) BETWEEN -2.91 AND 11.9 AND
      ST_Y(location::geometry) BETWEEN 19.5 AND 38.0
    )
  );

-- Slug format validation
ALTER TABLE public.pages
  DROP CONSTRAINT IF EXISTS valid_slug;

ALTER TABLE public.pages
  ADD CONSTRAINT valid_slug
  CHECK (
    slug ~ '^[a-z0-9-]{3,50}$'
    AND slug NOT LIKE '%--%'
    AND slug NOT LIKE '-%'
    AND slug NOT LIKE '%-'
  );
