import type { SearchResult } from "@/lib/types";
import FacilityCard from "@/components/FacilityCard";

export default function FacilityList({ results }: { results: SearchResult[] }) {
  if (results.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-slate-300 bg-white p-10 text-center">
        <p className="font-medium text-slate-700">No facilities found</p>
        <p className="mt-1 text-sm text-slate-500">
          Try widening your search radius or clearing some filters.
        </p>
      </div>
    );
  }

  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {results.map((facility) => (
        <FacilityCard key={facility.id} facility={facility} />
      ))}
    </div>
  );
}
