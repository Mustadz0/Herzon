-- MIGRATION 013: Ride Sharing
-- Adds ride sharing / carpooling support

-- ============================================
-- RIDE SHARES
-- ============================================
CREATE TABLE IF NOT EXISTS ride_shares (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  origin_lat double precision NOT NULL,
  origin_lng double precision NOT NULL,
  origin_name text,
  destination_lat double precision,
  destination_lng double precision,
  destination_name text,
  departure_time timestamptz NOT NULL,
  seats_available int NOT NULL DEFAULT 1 CHECK (seats_available >= 0 AND seats_available <= 10),
  price_per_seat double precision DEFAULT 0, -- DA, 0 = free
  description text,
  status text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled', 'expired')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE ride_shares IS 'Ride sharing / carpooling offers.';

ALTER TABLE ride_shares ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All ride shares are viewable"
  ON ride_shares FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create ride shares"
  ON ride_shares FOR INSERT WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Riders can update own ride shares"
  ON ride_shares FOR UPDATE USING (auth.uid() = driver_id);

CREATE POLICY "Riders can delete own ride shares"
  ON ride_shares FOR DELETE USING (auth.uid() = driver_id);

CREATE INDEX IF NOT EXISTS ride_shares_driver_idx ON ride_shares(driver_id);
CREATE INDEX IF NOT EXISTS ride_shares_status_idx ON ride_shares(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS ride_shares_departure_idx ON ride_shares(departure_time);

-- ============================================
-- RIDE PASSENGERS (seat booking)
-- ============================================
CREATE TABLE IF NOT EXISTS ride_passengers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  ride_id uuid NOT NULL REFERENCES ride_shares(id) ON DELETE CASCADE,
  passenger_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seats_booked int NOT NULL DEFAULT 1 CHECK (seats_booked >= 1),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE ride_passengers IS 'Passenger bookings on ride shares offers.';

ALTER TABLE ride_passengers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bookings"
  ON ride_passengers FOR SELECT USING (auth.uid() = passenger_id OR auth.uid() = (SELECT driver_id FROM ride_shares WHERE id = ride_id));

CREATE POLICY "Users can book a ride"
  ON ride_passengers FOR INSERT WITH CHECK (auth.uid() = passenger_id);

CREATE POLICY "Users can cancel own booking"
  ON ride_passengers FOR DELETE USING (auth.uid() = passenger_id);

CREATE INDEX IF NOT EXISTS ride_passengers_ride_idx ON ride_passengers(ride_id);
CREATE INDEX IF NOT EXISTS ride_passengers_passenger_idx ON ride_passengers(passenger_id);

-- ============================================
-- RPC: FIND NEARBY RIDES
-- ============================================
CREATE OR REPLACE FUNCTION get_nearby_rides(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_meters double precision DEFAULT 10000, -- 10km for rides
  p_limit int DEFAULT 20
)
RETURNS TABLE (
  id uuid,
  driver_id uuid,
  origin_name text,
  destination_name text,
  departure_time timestamptz,
  seats_available int,
  price_per_seat double precision,
  description text,
  status text,
  distance_meters double precision,
  driver_username text,
  driver_display_name text,
  driver_avatar_url text,
  seats_booked bigint,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rs.id,
    rs.driver_id,
    rs.origin_name,
    rs.destination_name,
    rs.departure_time,
    rs.seats_available,
    rs.price_per_seat,
    rs.description,
    rs.status,
    ST_Distance(
      ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(
        COALESCE(rs.origin_lng), 
        COALESCE(rs.origin_lat)
      ), 4326)::geography
    )::double precision AS distance_meters,
    pr.username AS driver_username,
    pr.display_name AS driver_display_name,
    pr.avatar_url AS driver_avatar_url,
    COALESCE((SELECT count(*) FROM ride_passengers WHERE ride_id = rs.id AND status IN ('pending', 'confirmed')), 0)::bigint AS seats_booked,
    rs.created_at
  FROM ride_shares rs
  JOIN profiles pr ON rs.driver_id = pr.id
  WHERE rs.status = 'active'
  AND rs.departure_time > now()
  AND ST_DWithin(
    ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
    ST_SetSRID(ST_MakePoint(COALESCE(rs.origin_lng), COALESCE(rs.origin_lat)), 4326)::geography,
    p_radius_meters
  )
  AND rs.driver_id NOT IN (SELECT get_blocked_user_ids(auth.uid()))
  AND rs.driver_id <> COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  ORDER BY rs.departure_time ASC, distance_meters
  LIMIT p_limit;
END;
$$;

-- ============================================
-- RPC: BOOK A RIDE
-- ============================================
CREATE OR REPLACE FUNCTION book_ride(
  p_ride_id uuid,
  p_seats int DEFAULT 1
) RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $$
  WITH ride_check AS (
    SELECT seats_available, driver_id
    FROM ride_shares
    WHERE id = p_ride_id AND status = 'active'
  ),
  existing_booking AS (
    SELECT seats_booked FROM ride_passengers
    WHERE ride_id = p_ride_id AND passenger_id = auth.uid()
  ),
  insert_result AS (
    INSERT INTO ride_passengers (ride_id, passenger_id, seats_booked, status)
    VALUES (p_ride_id, auth.uid(), p_seats, 'pending')
    ON CONFLICT (ride_id, passenger_id) DO NOTHING
    RETURNING *
  )
  SELECT jsonb_build_object(
    'success', true,
    'booking_id', (SELECT id FROM insert_result),
    'status', 'pending'
  )
  WHERE EXISTS (SELECT 1 FROM ride_check WHERE seats_available >= p_seats);
$$;

COMMENT ON FUNCTION book_ride IS 'Book a seat on a ride share. Authenticated users only.';