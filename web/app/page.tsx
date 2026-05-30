import { Suspense } from "react";
import SearchFilters from "@/components/SearchFilters";
import FacilityList from "@/components/FacilityList";
import FacilityMap from "@/components/FacilityMap";
import Pagination from "@/components/Pagination";
import { getFacets, runSearch } from "@/lib/queries";
import { parseSearchState } from "@/lib/search-params";
import type { MapMarker } from "@/components/FacilityMapInner";

export const dynamic = "force-dynamic";

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const params = await searchParams;
  const state = parseSearchState(params);

  const facets = await getFacets();
  const { results, total, page, pageCount } = await runSearch(state, facets);

  const markers: MapMarker[] = results.map((r) => ({
    id: r.id,
    slug: r.slug,
    name: r.name,
    lat: r.latitude,
    lng: r.longitude,
  }));

  const center =
    state.lat != null && state.lng != null
      ? { lat: state.lat, lng: state.lng }
      : null;

  return (
    <div className="grid gap-6 lg:grid-cols-[20rem_1fr]">
      <aside className="lg:sticky lg:top-4 lg:self-start">
        <SearchFilters
          state={state}
          amenities={facets.amenities}
          treatments={facets.treatments}
          policyTypes={facets.policyTypes}
        />
      </aside>

      <section>
        <div className="mb-3 flex items-center justify-between">
          <h1 className="text-xl font-semibold text-slate-900">
            Recovery facilities
          </h1>
          <p className="text-sm text-slate-500">
            {total} {total === 1 ? "result" : "results"}
          </p>
        </div>

        <div className="mb-4 h-72 overflow-hidden rounded-xl border border-slate-200">
          <FacilityMap
            markers={markers}
            center={center}
            radiusKm={state.radiusKm}
          />
        </div>

        <Suspense>
          <FacilityList results={results} />
          <Pagination page={page} pageCount={pageCount} />
        </Suspense>
      </section>
    </div>
  );
}
