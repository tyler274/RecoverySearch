-- RecoverySearch: Row Level Security.
-- Public (anon) can read published facilities and all lookup/join data.
-- Only admins (profiles.is_admin) may write. The import script uses the
-- service role key, which bypasses RLS entirely.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_admin
  );
$$;

grant execute on function public.is_admin() to anon, authenticated;

alter table public.profiles            enable row level security;
alter table public.facilities          enable row level security;
alter table public.amenities           enable row level security;
alter table public.treatments          enable row level security;
alter table public.policy_types        enable row level security;
alter table public.facility_amenities  enable row level security;
alter table public.facility_treatments enable row level security;
alter table public.facility_policies   enable row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
drop policy if exists "profiles self or admin read" on public.profiles;
create policy "profiles self or admin read" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles self update" on public.profiles;
create policy "profiles self update" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- facilities: public reads published rows; admins read/write everything.
-- ---------------------------------------------------------------------------
drop policy if exists "facilities public read" on public.facilities;
create policy "facilities public read" on public.facilities
  for select using (status = 'published' or public.is_admin());

drop policy if exists "facilities admin write" on public.facilities;
create policy "facilities admin write" on public.facilities
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- Lookup tables: world-readable, admin-writable.
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['amenities', 'treatments', 'policy_types'] loop
    execute format('drop policy if exists "%s public read" on public.%I;', t, t);
    execute format('create policy "%s public read" on public.%I for select using (true);', t, t);
    execute format('drop policy if exists "%s admin write" on public.%I;', t, t);
    execute format('create policy "%s admin write" on public.%I for all using (public.is_admin()) with check (public.is_admin());', t, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Join tables: world-readable, admin-writable.
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['facility_amenities', 'facility_treatments', 'facility_policies'] loop
    execute format('drop policy if exists "%s public read" on public.%I;', t, t);
    execute format('create policy "%s public read" on public.%I for select using (true);', t, t);
    execute format('drop policy if exists "%s admin write" on public.%I;', t, t);
    execute format('create policy "%s admin write" on public.%I for all using (public.is_admin()) with check (public.is_admin());', t, t);
  end loop;
end $$;
