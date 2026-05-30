-- RecoverySearch: combined faceted + geographic search.
-- Returns published facilities matching all supplied filters, with an optional
-- distance (metres) from a center point and an over-the-window total_count for
-- accurate pagination.

create or replace function public.search_facilities(
  search_text   text default null,
  filter_city   text default null,
  filter_region text default null,
  amenity_ids   uuid[] default null,
  treatment_ids uuid[] default null,
  policy_keys   text[] default null,   -- policy keys that must be allowed/yes
  center_lat    double precision default null,
  center_lng    double precision default null,
  radius_m      double precision default null,
  sort          text default 'relevance', -- relevance | distance | name
  page_limit    integer default 20,
  page_offset   integer default 0
)
returns table (
  id          uuid,
  slug        text,
  name        text,
  description text,
  address     text,
  city        text,
  region      text,
  country     text,
  postal_code text,
  latitude    double precision,
  longitude   double precision,
  phone       text,
  email       text,
  website     text,
  capacity    integer,
  distance_m  double precision,
  total_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with center as (
    select case
      when center_lat is not null and center_lng is not null
        then st_setsrid(st_makepoint(center_lng, center_lat), 4326)::geography
      else null
    end as g
  ),
  filtered as (
    select
      f.*,
      case
        when (select g from center) is not null
          then st_distance(f.location, (select g from center))
        else null
      end as distance_m
    from public.facilities f
    where f.status = 'published'
      and (
        search_text is null or search_text = ''
        or f.name ilike '%' || search_text || '%'
        or f.description ilike '%' || search_text || '%'
        or f.city ilike '%' || search_text || '%'
      )
      and (filter_city is null or filter_city = '' or lower(f.city) = lower(filter_city))
      and (filter_region is null or filter_region = '' or lower(f.region) = lower(filter_region))
      and (
        amenity_ids is null or cardinality(amenity_ids) = 0
        or (
          select count(distinct fa.amenity_id)
          from public.facility_amenities fa
          where fa.facility_id = f.id and fa.amenity_id = any(amenity_ids)
        ) = cardinality(amenity_ids)
      )
      and (
        treatment_ids is null or cardinality(treatment_ids) = 0
        or (
          select count(distinct ft.treatment_id)
          from public.facility_treatments ft
          where ft.facility_id = f.id and ft.treatment_id = any(treatment_ids)
        ) = cardinality(treatment_ids)
      )
      and (
        policy_keys is null or cardinality(policy_keys) = 0
        or (
          select count(distinct pt.key)
          from public.facility_policies fp
          join public.policy_types pt on pt.id = fp.policy_type_id
          where fp.facility_id = f.id
            and pt.key = any(policy_keys)
            and fp.value in ('allowed', 'yes')
        ) = cardinality(policy_keys)
      )
      and (
        radius_m is null or (select g from center) is null
        or st_dwithin(f.location, (select g from center), radius_m)
      )
  )
  select
    id, slug, name, description, address, city, region, country, postal_code,
    latitude, longitude, phone, email, website, capacity, distance_m,
    count(*) over () as total_count
  from filtered
  order by
    case when sort = 'distance' then distance_m end asc nulls last,
    case when sort = 'name' then name end asc,
    name asc
  limit greatest(coalesce(page_limit, 20), 1)
  offset greatest(coalesce(page_offset, 0), 0);
$$;

grant execute on function public.search_facilities(
  text, text, text, uuid[], uuid[], text[], double precision, double precision,
  double precision, text, integer, integer
) to anon, authenticated;
