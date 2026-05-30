"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Amenity, PolicyType, Treatment } from "@/lib/types";
import {
  buildSearchQuery,
  type SearchState,
  type SortOption,
} from "@/lib/search-params";

interface Props {
  state: SearchState;
  amenities: Amenity[];
  treatments: Treatment[];
  policyTypes: PolicyType[];
}

function toggle(list: string[], value: string): string[] {
  return list.includes(value)
    ? list.filter((v) => v !== value)
    : [...list, value];
}

export default function SearchFilters({
  state,
  amenities,
  treatments,
  policyTypes,
}: Props) {
  const router = useRouter();
  const [draft, setDraft] = useState<SearchState>(state);
  const [locating, setLocating] = useState(false);

  function apply(next: SearchState) {
    const reset = { ...next, page: 1 };
    setDraft(reset);
    router.push(`/?${buildSearchQuery(reset)}`);
  }

  function useMyLocation() {
    // navigator.geolocation is absent in some older/restricted browsers despite
    // the DOM types marking it as always present.
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (!navigator.geolocation) return;
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLocating(false);
        apply({
          ...draft,
          lat: Number(pos.coords.latitude.toFixed(5)),
          lng: Number(pos.coords.longitude.toFixed(5)),
          near: "My location",
          sort: draft.sort === "relevance" ? "distance" : draft.sort,
        });
      },
      () => { setLocating(false); },
      { enableHighAccuracy: false, timeout: 8000 },
    );
  }

  const hasGeo = draft.lat != null && draft.lng != null;

  return (
    <form
      className="space-y-5 rounded-xl border border-slate-200 bg-white p-4"
      onSubmit={(e) => {
        e.preventDefault();
        apply(draft);
      }}
    >
      <div>
        <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
          Keyword
        </label>
        <input
          type="text"
          value={draft.q}
          onChange={(e) => { setDraft({ ...draft, q: e.target.value }); }}
          placeholder="Name or description"
          className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
        />
      </div>

      <div className="grid grid-cols-2 gap-2">
        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
            City
          </label>
          <input
            type="text"
            value={draft.city}
            onChange={(e) => { setDraft({ ...draft, city: e.target.value }); }}
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
            State / Region
          </label>
          <input
            type="text"
            value={draft.region}
            onChange={(e) => { setDraft({ ...draft, region: e.target.value }); }}
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      <div className="rounded-lg bg-slate-50 p-3">
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">
            Near me
          </span>
          {hasGeo ? (
            <button
              type="button"
              className="text-xs text-rose-600 hover:underline"
              onClick={() => { apply({ ...draft, lat: null, lng: null, near: "" }); }}
            >
              Clear
            </button>
          ) : (
            <button
              type="button"
              onClick={useMyLocation}
              disabled={locating}
              className="text-xs font-medium text-teal-700 hover:underline disabled:opacity-50"
            >
              {locating ? "Locating…" : "Use my location"}
            </button>
          )}
        </div>
        {hasGeo && (
          <div className="mt-2">
            <div className="flex items-center justify-between text-xs text-slate-600">
              <span>{draft.near || "Selected point"}</span>
              <span>{draft.radiusKm} km</span>
            </div>
            <input
              type="range"
              min={1}
              max={200}
              value={draft.radiusKm}
              onChange={(e) => { setDraft({ ...draft, radiusKm: Number(e.target.value) }); }}
              className="mt-1 w-full"
            />
          </div>
        )}
      </div>

      <FacetGroup
        title="Treatments"
        options={treatments.map((t) => ({ value: t.slug, label: t.name }))}
        selected={draft.treatments}
        onToggle={(v) => { setDraft({ ...draft, treatments: toggle(draft.treatments, v) }); }}
      />

      <FacetGroup
        title="Amenities"
        options={amenities.map((a) => ({ value: a.slug, label: a.name }))}
        selected={draft.amenities}
        onToggle={(v) => { setDraft({ ...draft, amenities: toggle(draft.amenities, v) }); }}
      />

      <FacetGroup
        title="Policies (allowed)"
        options={policyTypes
          .filter((p) => p.value_type !== "text")
          .map((p) => ({ value: p.key, label: p.label }))}
        selected={draft.policies}
        onToggle={(v) => { setDraft({ ...draft, policies: toggle(draft.policies, v) }); }}
      />

      <div>
        <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
          Sort by
        </label>
        <select
          value={draft.sort}
          onChange={(e) => { setDraft({ ...draft, sort: e.target.value as SortOption }); }}
          className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="relevance">Relevance</option>
          <option value="distance" disabled={!hasGeo}>
            Distance {hasGeo ? "" : "(set location)"}
          </option>
          <option value="name">Name (A–Z)</option>
        </select>
      </div>

      <div className="flex gap-2">
        <button
          type="submit"
          className="flex-1 rounded-md bg-teal-600 px-3 py-2 text-sm font-medium text-white hover:bg-teal-700"
        >
          Apply filters
        </button>
        <button
          type="button"
          onClick={() => { apply({} as SearchState); }}
          className="rounded-md border border-slate-300 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50"
        >
          Clear
        </button>
      </div>
    </form>
  );
}

function FacetGroup({
  title,
  options,
  selected,
  onToggle,
}: {
  title: string;
  options: { value: string; label: string }[];
  selected: string[];
  onToggle: (value: string) => void;
}) {
  if (options.length === 0) return null;
  return (
    <fieldset>
      <legend className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">
        {title}
      </legend>
      <div className="max-h-44 space-y-1 overflow-y-auto pr-1">
        {options.map((opt) => (
          <label
            key={opt.value}
            className="flex cursor-pointer items-center gap-2 text-sm text-slate-700"
          >
            <input
              type="checkbox"
              checked={selected.includes(opt.value)}
              onChange={() => { onToggle(opt.value); }}
              className="h-4 w-4 rounded border-slate-300 text-teal-600"
            />
            {opt.label}
          </label>
        ))}
      </div>
    </fieldset>
  );
}
