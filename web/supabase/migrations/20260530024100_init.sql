-- RecoverySearch: core schema
-- Mental health recovery facilities, their policies, amenities and treatments.

create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------------
-- profiles: 1:1 with auth.users, carries the admin flag used by RLS.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  full_name text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Lookup tables for faceted search.
-- ---------------------------------------------------------------------------
create table if not exists public.amenities (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,
  name text not null,
  category text
);

create table if not exists public.treatments (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,
  name text not null,
  category text
);

-- policy_types describes a trackable policy (e.g. "phones_allowed").
-- value_type drives how the admin UI renders the value of a facility_policy.
create table if not exists public.policy_types (
  id uuid primary key default uuid_generate_v4(),
  key text unique not null,
  label text not null,
  description text,
  value_type text not null default 'enum'
    check (value_type in ('enum', 'boolean', 'text'))
);

-- ---------------------------------------------------------------------------
-- facilities: the central entity.
-- ---------------------------------------------------------------------------
create table if not exists public.facilities (
  id uuid primary key default uuid_generate_v4(),
  external_id text unique,
  slug text unique not null,
  name text not null,
  description text,
  address text,
  city text,
  region text,
  country text default 'USA',
  postal_code text,
  latitude double precision,
  longitude double precision,
  location geography(Point, 4326),
  phone text,
  email text,
  website text,
  capacity integer,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Join tables.
-- ---------------------------------------------------------------------------
create table if not exists public.facility_amenities (
  facility_id uuid not null references public.facilities on delete cascade,
  amenity_id uuid not null references public.amenities on delete cascade,
  primary key (facility_id, amenity_id)
);

create table if not exists public.facility_treatments (
  facility_id uuid not null references public.facilities on delete cascade,
  treatment_id uuid not null references public.treatments on delete cascade,
  primary key (facility_id, treatment_id)
);

create table if not exists public.facility_policies (
  id uuid primary key default uuid_generate_v4(),
  facility_id uuid not null references public.facilities on delete cascade,
  policy_type_id uuid not null references public.policy_types on delete cascade,
  -- canonical values: allowed | restricted | prohibited | conditional | yes | no
  value text not null,
  notes text,
  unique (facility_id, policy_type_id)
);

-- ---------------------------------------------------------------------------
-- Triggers: keep PostGIS location in sync with lat/long and bump updated_at.
-- ---------------------------------------------------------------------------
create or replace function public.facilities_sync_location()
returns trigger
language plpgsql
as $$
begin
  if new.latitude is not null and new.longitude is not null then
    new.location := st_setsrid(st_makepoint(new.longitude, new.latitude), 4326)::geography;
  else
    new.location := null;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_facilities_sync on public.facilities;
create trigger trg_facilities_sync
  before insert or update on public.facilities
  for each row execute function public.facilities_sync_location();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Indexes.
-- ---------------------------------------------------------------------------
create index if not exists facilities_location_gix
  on public.facilities using gist (location);
create index if not exists facilities_name_trgm
  on public.facilities using gin (name gin_trgm_ops);
create index if not exists facilities_city_idx
  on public.facilities (lower(city));
create index if not exists facilities_region_idx
  on public.facilities (lower(region));
create index if not exists facilities_status_idx
  on public.facilities (status);
create index if not exists facility_amenities_amenity_idx
  on public.facility_amenities (amenity_id);
create index if not exists facility_treatments_treatment_idx
  on public.facility_treatments (treatment_id);
create index if not exists facility_policies_type_idx
  on public.facility_policies (policy_type_id);

-- ---------------------------------------------------------------------------
-- Seed lookup data.
-- ---------------------------------------------------------------------------
insert into public.amenities (slug, name, category) values
  ('private-rooms', 'Private Rooms', 'accommodation'),
  ('semi-private-rooms', 'Semi-Private Rooms', 'accommodation'),
  ('gym', 'Fitness Center / Gym', 'wellness'),
  ('pool', 'Swimming Pool', 'wellness'),
  ('yoga', 'Yoga Studio', 'wellness'),
  ('meditation', 'Meditation Space', 'wellness'),
  ('outdoor-space', 'Outdoor / Garden Space', 'wellness'),
  ('chefs-meals', 'Chef-Prepared Meals', 'dining'),
  ('dietary-accommodations', 'Dietary Accommodations', 'dining'),
  ('art-studio', 'Art Studio', 'activities'),
  ('music-room', 'Music Room', 'activities'),
  ('pet-friendly', 'Pet Friendly', 'policy'),
  ('wheelchair-accessible', 'Wheelchair Accessible', 'accessibility'),
  ('transportation', 'Transportation Services', 'services'),
  ('laundry', 'Laundry Services', 'services')
on conflict (slug) do nothing;

insert into public.treatments (slug, name, category) values
  ('cbt', 'Cognitive Behavioral Therapy (CBT)', 'therapy'),
  ('dbt', 'Dialectical Behavior Therapy (DBT)', 'therapy'),
  ('emdr', 'EMDR', 'therapy'),
  ('group-therapy', 'Group Therapy', 'therapy'),
  ('individual-therapy', 'Individual Therapy', 'therapy'),
  ('family-therapy', 'Family Therapy', 'therapy'),
  ('medication-management', 'Medication Management', 'medical'),
  ('detox', 'Medical Detox', 'medical'),
  ('dual-diagnosis', 'Dual Diagnosis Treatment', 'medical'),
  ('trauma-informed', 'Trauma-Informed Care', 'specialty'),
  ('substance-use', 'Substance Use Treatment', 'specialty'),
  ('eating-disorder', 'Eating Disorder Treatment', 'specialty'),
  ('mood-disorders', 'Mood Disorder Treatment', 'specialty'),
  ('art-therapy', 'Art Therapy', 'holistic'),
  ('equine-therapy', 'Equine Therapy', 'holistic'),
  ('mindfulness', 'Mindfulness / Meditation', 'holistic')
on conflict (slug) do nothing;

insert into public.policy_types (key, label, description, value_type) values
  ('phones_allowed', 'Phones Allowed', 'Whether residents may keep / use personal mobile phones.', 'enum'),
  ('electronics_allowed', 'Electronic Devices Allowed', 'Whether laptops, tablets and other electronics are permitted.', 'enum'),
  ('visitors_allowed', 'Visitors Allowed', 'Whether visitors are permitted and under what conditions.', 'enum'),
  ('smoking_allowed', 'Smoking Allowed', 'On-site smoking policy.', 'enum'),
  ('pets_allowed', 'Pets Allowed', 'Whether residents may bring pets.', 'enum'),
  ('insurance_accepted', 'Insurance Accepted', 'Whether the facility accepts insurance.', 'boolean'),
  ('medication_assisted', 'Medication-Assisted Treatment', 'Whether MAT is offered.', 'boolean'),
  ('lgbtq_affirming', 'LGBTQ+ Affirming', 'Whether the facility is explicitly LGBTQ+ affirming.', 'boolean'),
  ('min_stay_days', 'Minimum Stay (days)', 'Minimum length of stay required.', 'text'),
  ('age_range', 'Age Range Served', 'Age range of residents the facility serves.', 'text')
on conflict (key) do nothing;
