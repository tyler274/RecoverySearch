export const PAGE_SIZE = 12;

export type SortOption = "relevance" | "distance" | "name";

export interface SearchState {
  q: string;
  city: string;
  region: string;
  amenities: string[]; // amenity slugs
  treatments: string[]; // treatment slugs
  policies: string[]; // policy_type keys (must be allowed/yes)
  lat: number | null;
  lng: number | null;
  near: string; // human label for the geo center
  radiusKm: number;
  sort: SortOption;
  page: number;
}

type RawParams = Record<string, string | string[] | undefined>;

function str(value: string | string[] | undefined): string {
  if (Array.isArray(value)) return value[0] ?? "";
  return value ?? "";
}

function list(value: string | string[] | undefined): string[] {
  const raw = str(value);
  if (!raw) return [];
  return raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function num(value: string | string[] | undefined): number | null {
  const raw = str(value);
  if (!raw) return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

export function parseSearchState(params: RawParams): SearchState {
  const sortRaw = str(params.sort);
  const sort: SortOption =
    sortRaw === "distance" || sortRaw === "name" ? sortRaw : "relevance";

  const page = Math.max(1, num(params.page) ?? 1);
  const radiusKm = Math.min(500, Math.max(1, num(params.radius) ?? 50));

  return {
    q: str(params.q),
    city: str(params.city),
    region: str(params.region),
    amenities: list(params.amenities),
    treatments: list(params.treatments),
    policies: list(params.policies),
    lat: num(params.lat),
    lng: num(params.lng),
    near: str(params.near),
    radiusKm,
    sort,
    page,
  };
}

// Serialize state back into a URLSearchParams string (omitting empty values).
export function buildSearchQuery(state: Partial<SearchState>): string {
  const sp = new URLSearchParams();
  if (state.q) sp.set("q", state.q);
  if (state.city) sp.set("city", state.city);
  if (state.region) sp.set("region", state.region);
  if (state.amenities?.length) sp.set("amenities", state.amenities.join(","));
  if (state.treatments?.length)
    sp.set("treatments", state.treatments.join(","));
  if (state.policies?.length) sp.set("policies", state.policies.join(","));
  if (state.lat != null && state.lng != null) {
    sp.set("lat", String(state.lat));
    sp.set("lng", String(state.lng));
    if (state.near) sp.set("near", state.near);
    if (state.radiusKm) sp.set("radius", String(state.radiusKm));
  }
  if (state.sort && state.sort !== "relevance") sp.set("sort", state.sort);
  if (state.page && state.page > 1) sp.set("page", String(state.page));
  return sp.toString();
}
