import Link from "next/link";
import type { SearchResult } from "@/lib/types";

function formatDistance(meters: number | null): string | null {
  if (meters == null) return null;
  const km = meters / 1000;
  if (km < 1) return `${Math.round(meters)} m away`;
  return `${km.toFixed(km < 10 ? 1 : 0)} km away`;
}

export default function FacilityCard({ facility }: { facility: SearchResult }) {
  const location = [facility.city, facility.region].filter(Boolean).join(", ");
  const distance = formatDistance(facility.distance_m);

  return (
    <Link
      href={`/facilities/${facility.slug}`}
      className="block rounded-xl border border-slate-200 bg-white p-4 transition hover:border-teal-400 hover:shadow-sm"
    >
      <div className="flex items-start justify-between gap-3">
        <h3 className="font-semibold text-slate-900">{facility.name}</h3>
        {distance && (
          <span className="shrink-0 rounded-full bg-teal-50 px-2 py-0.5 text-xs font-medium text-teal-700">
            {distance}
          </span>
        )}
      </div>
      {location && <p className="mt-1 text-sm text-slate-500">{location}</p>}
      {facility.description && (
        <p className="mt-2 line-clamp-2 text-sm text-slate-600">
          {facility.description}
        </p>
      )}
      <div className="mt-3 flex flex-wrap gap-2 text-xs text-slate-500">
        {facility.capacity > 0 && (
          <span className="rounded bg-slate-100 px-2 py-0.5">
            {facility.capacity} beds
          </span>
        )}
        {facility.phone && (
          <span className="rounded bg-slate-100 px-2 py-0.5">
            {facility.phone}
          </span>
        )}
      </div>
    </Link>
  );
}
