-- ============================================================
-- Migration 047: explorer_zones (renamed from 20260711_039)
-- ============================================================
-- REASON: The original file '20260711_039_explorer_zones.sql'
-- used a mixed timestamp+number format which breaks Supabase CLI
-- ordering. Content is identical; file is now correctly named.
-- ============================================================

-- zone_snapshots table for explorer zones feature
create table if not exists public.zone_snapshots (
  id              uuid             primary key default gen_random_uuid(),
  zone_key        text             not null unique,
  zone_name       text             not null,
  center_lat      double precision not null,
  center_lng      double precision not null,
  heat_score      integer          not null default 0,
  active_users    integer          not null default 0,
  recent_posts    integer          not null default 0,
  recent_vibes    integer          not null default 0,
  recent_checkins integer          not null default 0,
  dominant_activity text,
  updated_at      timestamptz      not null default now()
);

create index if not exists idx_zone_snapshots_heat
  on public.zone_snapshots(heat_score desc);

create index if not exists idx_zone_snapshots_updated
  on public.zone_snapshots(updated_at desc);

alter table public.zone_snapshots enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where policyname = 'zone_snapshots_select_authenticated'
    and tablename = 'zone_snapshots'
  ) then
    create policy "zone_snapshots_select_authenticated"
      on public.zone_snapshots for select to authenticated using (true);
  end if;
end $$;

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
language sql security definer set search_path = public as $$
  select
    z.id, z.zone_key, z.zone_name,
    z.center_lat, z.center_lng,
    z.heat_score, z.active_users,
    z.recent_posts, z.recent_vibes, z.recent_checkins,
    z.dominant_activity, z.updated_at
  from public.zone_snapshots z
  where ST_DWithin(
    ST_SetSRID(ST_MakePoint(z.center_lng, z.center_lat), 4326)::geography,
    ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
    p_radius_meters
  )
  order by z.heat_score desc, z.updated_at desc;
$$;

create or replace function public.refresh_zone_heat()
returns void language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  for r in select id, center_lat, center_lng from public.zone_snapshots loop
    update public.zone_snapshots
    set
      recent_posts = (
        select count(*) from public.posts p
        where p.created_at >= now() - interval '30 minutes'
          and ST_DWithin(
            p.location,
            ST_SetSRID(ST_MakePoint(r.center_lng, r.center_lat), 4326)::geography,
            250
          )
      ),
      recent_checkins = (
        select count(*) from public.checkins c
        where c.last_checkin_at >= now() - interval '60 minutes'
          and (
            6371000 * acos(
              greatest(-1.0, least(1.0,
                cos(radians(r.center_lat)) * cos(radians(c.place_lat))
                * cos(radians(c.place_lng) - radians(r.center_lng))
                + sin(radians(r.center_lat)) * sin(radians(c.place_lat))
              ))
            )
          ) <= 250
      ),
      active_users = (
        select count(distinct pr.id) from public.profiles pr
        where pr.last_active_at >= now() - interval '10 minutes'
          and (
            6371000 * acos(
              greatest(-1.0, least(1.0,
                cos(radians(r.center_lat)) * cos(radians(0))
                * cos(radians(0) - radians(r.center_lng))
                + sin(radians(r.center_lat)) * sin(radians(0))
              ))
            )
          ) <= 250
      ),
      updated_at = now()
    where id = r.id;

    update public.zone_snapshots
    set
      heat_score = (recent_posts * 4) + (recent_checkins * 3) + (active_users * 2),
      dominant_activity = case
        when recent_posts >= recent_checkins and recent_posts >= active_users then 'posts'
        when recent_checkins >= recent_posts and recent_checkins >= active_users then 'checkins'
        else 'active_users'
      end
    where id = r.id;
  end loop;
end;
$$;

RAISE NOTICE '047: explorer_zones migration applied successfully (renamed from 20260711_039)';
