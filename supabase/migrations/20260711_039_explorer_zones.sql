-- ============================================================
-- 039_explorer_zones.sql
-- Explorer Zones: hot zone snapshots + nearby zones RPC
-- Follows the same pattern as getnearby* RPCs in the project
-- ============================================================

-- Table: stores pre-computed zone activity snapshots
create table if not exists public.zone_snapshots (
  id            uuid          primary key default gen_random_uuid(),
  zone_key      text          not null unique,
  zone_name     text          not null,
  center_lat    double precision not null,
  center_lng    double precision not null,
  heat_score    integer       not null default 0,
  active_users  integer       not null default 0,
  recent_posts  integer       not null default 0,
  recent_vibes  integer       not null default 0,
  recent_checkins integer     not null default 0,
  dominant_activity text,
  updated_at    timestamptz   not null default now()
);

create index if not exists idx_zone_snapshots_heat
  on public.zone_snapshots(heat_score desc);

create index if not exists idx_zone_snapshots_updated
  on public.zone_snapshots(updated_at desc);

alter table public.zone_snapshots enable row level security;

create policy "zone_snapshots_select_authenticated"
  on public.zone_snapshots
  for select
  to authenticated
  using (true);

-- ============================================================
-- RPC: get_nearby_zones
-- Returns zones within radius sorted by heat_score desc
-- Uses Haversine formula (same pattern as other nearby RPCs)
-- ============================================================
create or replace function public.get_nearby_zones(
  p_user_lat      double precision,
  p_user_lng      double precision,
  p_radius_meters integer default 500
)
returns table (
  id                uuid,
  zone_key          text,
  zone_name         text,
  center_lat        double precision,
  center_lng        double precision,
  heat_score        integer,
  active_users      integer,
  recent_posts      integer,
  recent_vibes      integer,
  recent_checkins   integer,
  dominant_activity text,
  updated_at        timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    z.id,
    z.zone_key,
    z.zone_name,
    z.center_lat,
    z.center_lng,
    z.heat_score,
    z.active_users,
    z.recent_posts,
    z.recent_vibes,
    z.recent_checkins,
    z.dominant_activity,
    z.updated_at
  from public.zone_snapshots z
  where (
    6371000 * acos(
      greatest(-1.0, least(1.0,
        cos(radians(p_user_lat))
        * cos(radians(z.center_lat))
        * cos(radians(z.center_lng) - radians(p_user_lng))
        + sin(radians(p_user_lat))
        * sin(radians(z.center_lat))
      ))
    )
  ) <= p_radius_meters
  order by z.heat_score desc, z.updated_at desc;
$$;

-- ============================================================
-- RPC: refresh_zone_heat
-- Recomputes heat_score for all zones from live data
-- Formula: posts*4 + vibes*5 + checkins*3 + active_users*2
-- Call this from a pg_cron job every 5 minutes
-- ============================================================
create or replace function public.refresh_zone_heat()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  for r in select id, center_lat, center_lng from public.zone_snapshots loop

    update public.zone_snapshots
    set
      recent_posts = (
        select count(*)
        from public.posts p
        where p.created_at >= now() - interval '30 minutes'
          and (
            6371000 * acos(
              greatest(-1.0, least(1.0,
                cos(radians(r.center_lat)) * cos(radians(p.latitude))
                * cos(radians(p.longitude) - radians(r.center_lng))
                + sin(radians(r.center_lat)) * sin(radians(p.latitude))
              ))
            )
          ) <= 250
      ),
      recent_vibes = (
        select count(*)
        from public.vibes v
        where v.created_at >= now() - interval '60 minutes'
          and (
            6371000 * acos(
              greatest(-1.0, least(1.0,
                cos(radians(r.center_lat)) * cos(radians(v.latitude))
                * cos(radians(v.longitude) - radians(r.center_lng))
                + sin(radians(r.center_lat)) * sin(radians(v.latitude))
              ))
            )
          ) <= 250
      ),
      recent_checkins = (
        select count(*)
        from public.checkins c
        where c.created_at >= now() - interval '60 minutes'
          and (
            6371000 * acos(
              greatest(-1.0, least(1.0,
                cos(radians(r.center_lat)) * cos(radians(c.latitude))
                * cos(radians(c.longitude) - radians(r.center_lng))
                + sin(radians(r.center_lat)) * sin(radians(c.latitude))
              ))
            )
          ) <= 250
      ),
      active_users = (
        select count(distinct pr.id)
        from public.profiles pr
        where pr.last_active_at >= now() - interval '10 minutes'
          and pr.is_active = true
          and (
            6371000 * acos(
              greatest(-1.0, least(1.0,
                cos(radians(r.center_lat)) * cos(radians(pr.latitude))
                * cos(radians(pr.longitude) - radians(r.center_lng))
                + sin(radians(r.center_lat)) * sin(radians(pr.latitude))
              ))
            )
          ) <= 250
      ),
      updated_at = now()
    where id = r.id;

    -- recompute heat_score
    update public.zone_snapshots
    set heat_score = (recent_posts * 4) + (recent_vibes * 5) + (recent_checkins * 3) + (active_users * 2)
    where id = r.id;

  end loop;
end;
$$;
