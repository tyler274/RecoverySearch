import { createClient } from "@/lib/supabase/server";
import type { Amenity, PolicyType, SearchResult, Treatment } from "@/lib/types";
import {
  PAGE_SIZE,
  type SearchState,
  type SortOption,
} from "@/lib/search-params";

export interface Facets {
  amenities: Amenity[];
  treatments: Treatment[];
  policyTypes: PolicyType[];
}

export async function getFacets(): Promise<Facets> {
  const supabase = await createClient();
  const [amenities, treatments, policyTypes] = await Promise.all([
    supabase.from("amenities").select("*").order("name"),
    supabase.from("treatments").select("*").order("name"),
    supabase.from("policy_types").select("*").order("label"),
  ]);
  return {
    amenities: amenities.data ?? [],
    treatments: treatments.data ?? [],
    policyTypes: policyTypes.data ?? [],
  };
}

export interface SearchResponse {
  results: SearchResult[];
  total: number;
  page: number;
  pageCount: number;
}

// Resolves facet slugs to ids, then calls the search_facilities RPC.
export async function runSearch(
  state: SearchState,
  facets: Facets,
): Promise<SearchResponse> {
  const supabase = await createClient();

  const amenityIds = facets.amenities
    .filter((a) => state.amenities.includes(a.slug))
    .map((a) => a.id);
  const treatmentIds = facets.treatments
    .filter((t) => state.treatments.includes(t.slug))
    .map((t) => t.id);

  const hasGeo = state.lat != null && state.lng != null;
  const sort: SortOption =
    state.sort === "relevance" && hasGeo ? "distance" : state.sort;

  const { data, error } = await supabase.rpc("search_facilities", {
    search_text: state.q || undefined,
    filter_city: state.city || undefined,
    filter_region: state.region || undefined,
    amenity_ids: amenityIds.length ? amenityIds : undefined,
    treatment_ids: treatmentIds.length ? treatmentIds : undefined,
    policy_keys: state.policies.length ? state.policies : undefined,
    center_lat: hasGeo ? state.lat! : undefined,
    center_lng: hasGeo ? state.lng! : undefined,
    radius_m: hasGeo ? state.radiusKm * 1000 : undefined,
    sort,
    page_limit: PAGE_SIZE,
    page_offset: (state.page - 1) * PAGE_SIZE,
  });

  if (error) {
    throw new Error(`Search failed: ${error.message}`);
  }

  const results = (data ?? []) as SearchResult[];
  const total = results[0]?.total_count ?? 0;
  return {
    results,
    total,
    page: state.page,
    pageCount: Math.max(1, Math.ceil(total / PAGE_SIZE)),
  };
}

export interface FacilityDetail {
  facility: {
    id: string;
    slug: string;
    name: string;
    description: string | null;
    address: string | null;
    city: string | null;
    region: string | null;
    country: string | null;
    postal_code: string | null;
    latitude: number | null;
    longitude: number | null;
    phone: string | null;
    email: string | null;
    website: string | null;
    capacity: number | null;
  };
  amenities: Amenity[];
  treatments: Treatment[];
  policies: { policy: PolicyType; value: string; notes: string | null }[];
}

export async function getFacilityBySlug(
  slug: string,
): Promise<FacilityDetail | null> {
  const supabase = await createClient();

  const { data: facility } = await supabase
    .from("facilities")
    .select(
      "id, slug, name, description, address, city, region, country, postal_code, latitude, longitude, phone, email, website, capacity",
    )
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (!facility) return null;

  const [amenities, treatments, policies] = await Promise.all([
    supabase
      .from("facility_amenities")
      .select("amenities(*)")
      .eq("facility_id", facility.id),
    supabase
      .from("facility_treatments")
      .select("treatments(*)")
      .eq("facility_id", facility.id),
    supabase
      .from("facility_policies")
      .select("value, notes, policy_types(*)")
      .eq("facility_id", facility.id),
  ]);

  return {
    facility,
    amenities: (amenities.data ?? [])
      .map((row) => row.amenities as Amenity)
      .filter(Boolean),
    treatments: (treatments.data ?? [])
      .map((row) => row.treatments as Treatment)
      .filter(Boolean),
    policies: (policies.data ?? [])
      .map((row) => ({
        policy: row.policy_types as PolicyType,
        value: row.value,
        notes: row.notes,
      }))
      .filter((p) => p.policy),
  };
}
