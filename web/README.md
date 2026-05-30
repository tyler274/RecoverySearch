# RecoverySearch Web App

A Next.js (App Router, TypeScript) application for searching and indexing mental
health recovery facilities by location, policies, amenities, and treatments. It
runs on top of the self-hosted Supabase stack in the repository root.

- **Search**: keyword + city/region + facet filters (treatments, amenities,
  policies) + map view with geographic radius search (PostGIS).
- **Admin**: Supabase Auth login and an admin-gated CRUD UI for facilities and
  their policies/amenities/treatments.
- **Import**: a CSV bulk-import script that geocodes addresses (Nominatim) and
  upserts via the service-role key.

## Architecture

| Concern | Choice |
| --- | --- |
| Framework | Next.js 15 App Router, TypeScript, Tailwind CSS v4 |
| Data + auth | Supabase (`@supabase/supabase-js`, `@supabase/ssr`), RLS-secured |
| Migrations / types | Supabase CLI (`supabase/migrations`, `gen types`) |
| Search | Postgres `search_facilities` RPC over PostGIS |
| Map | `react-leaflet` + OpenStreetMap tiles (no API key) |
| Tooling | Nix flake + direnv (Node 22, Supabase CLI, psql) |

We use **Supabase's native tooling rather than a separate ORM** (e.g. Prisma):
PostGIS spatial types/RPCs and RLS are first-class in Supabase but awkward in
Prisma. The generated `lib/database.types.ts` keeps the frontend and backend in
sync from the live schema.

## Prerequisites

- The self-hosted Supabase stack running from the repo root (`docker compose up -d`).
- [Nix](https://nixos.org) with flakes enabled and [direnv](https://direnv.net).

## Setup

```bash
cd web

# 1. Activate the dev environment (Node 22, Supabase CLI, psql).
direnv allow        # or: nix develop

# 2. Configure environment variables.
cp .env.example .env.local
# Fill NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY and
# SUPABASE_DB_URL using the values in the root .env (ANON_KEY, SERVICE_ROLE_KEY,
# POSTGRES_PASSWORD, POOLER_TENANT_ID).

# 3. Install dependencies.
npm install
```

`SUPABASE_DB_URL` reaches the database through the pooler published on host port
`5433`:

```
postgresql://postgres.<POOLER_TENANT_ID>:<POSTGRES_PASSWORD>@localhost:5433/postgres?sslmode=disable
```

## Database migrations (Supabase CLI)

Migrations live in [`supabase/migrations`](supabase/migrations):

- `..._init.sql` — extensions (PostGIS, pg_trgm), tables, indexes, triggers, seed lookups
- `..._search_fn.sql` — the `search_facilities` RPC
- `..._rls.sql` — Row Level Security policies

```bash
# Apply pending migrations to the running database.
npm run db:push

# Create a new migration.
npm run migration:new add_something

# Show schema drift between the DB and your migrations.
npm run db:diff

# Regenerate TypeScript types from the live schema.
npm run gen:types
```

## Running the app

```bash
npm run dev          # http://localhost:3000
npm run build        # production build
npm run typecheck    # tsc --noEmit
```

## Importing facilities

CSV columns: `external_id, name, slug, description, address, city, region,
country, postal_code, latitude, longitude, phone, email, website, capacity,
status, amenities, treatments, policies`.

- `amenities` / `treatments`: pipe-separated **slugs** (e.g. `gym|yoga|pool`).
- `policies`: pipe-separated `key=value` (e.g.
  `phones_allowed=restricted|insurance_accepted=yes`).
- Rows without `latitude`/`longitude` are geocoded from the address via
  Nominatim (rate-limited to 1 req/sec, cached in `data/.geocache.json`).
- Upserts are idempotent on `slug`.

```bash
npm run import -- data/sample-facilities.csv
```

Valid amenity/treatment slugs and policy keys are seeded by the init migration
(see the `amenities`, `treatments`, and `policy_types` tables).

## Creating an admin user

1. Create a user (Supabase Studio → Authentication → Add user, or sign up).
2. Promote them to admin:

```sql
update public.profiles set is_admin = true where email = 'you@example.com';
```

A `profiles` row is created automatically on signup. Sign in at `/auth/login`
and manage facilities at `/admin`.

## Project layout

```
web/
  app/                     # App Router routes
    page.tsx               # public search (filters + map + list)
    facilities/[slug]/     # facility detail
    auth/                  # login + auth server actions
    admin/                 # admin-gated CRUD (layout guards is_admin)
  components/              # SearchFilters, FacilityMap, FacilityForm, ...
  lib/
    supabase/              # browser/server/admin clients + session middleware
    queries.ts             # data access (facets, search RPC, detail)
    search-params.ts       # URL <-> search state
    database.types.ts      # generated Supabase types
    types.ts               # domain type aliases
  scripts/import.ts        # CSV bulk importer
  supabase/                # config.toml + migrations
  flake.nix / .envrc       # nix + direnv dev environment
```
