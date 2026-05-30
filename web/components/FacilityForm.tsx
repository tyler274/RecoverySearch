import type { Amenity, PolicyType, Treatment } from "@/lib/types";
import { POLICY_ENUM_VALUES } from "@/lib/types";
import { deleteFacility } from "@/app/admin/actions";

export interface FacilityFormValues {
  id?: string;
  name?: string;
  slug?: string;
  description?: string | null;
  address?: string | null;
  city?: string | null;
  region?: string | null;
  country?: string | null;
  postal_code?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  phone?: string | null;
  email?: string | null;
  website?: string | null;
  capacity?: number | null;
  status?: string | null;
}

interface Props {
  action: (formData: FormData) => Promise<void>;
  facility?: FacilityFormValues;
  amenities: Amenity[];
  treatments: Treatment[];
  policyTypes: PolicyType[];
  selectedAmenityIds: string[];
  selectedTreatmentIds: string[];
  policyMap: Record<string, { value: string; notes: string | null }>;
  saved?: boolean;
  error?: string;
}

function Field({
  label,
  name,
  defaultValue,
  type = "text",
  required,
  placeholder,
}: {
  label: string;
  name: string;
  defaultValue?: string | number | null;
  type?: string;
  required?: boolean;
  placeholder?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
        {label}
      </span>
      <input
        type={type}
        name={name}
        required={required}
        placeholder={placeholder}
        defaultValue={defaultValue ?? undefined}
        step={type === "number" ? "any" : undefined}
        className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
      />
    </label>
  );
}

export default function FacilityForm({
  action,
  facility,
  amenities,
  treatments,
  policyTypes,
  selectedAmenityIds,
  selectedTreatmentIds,
  policyMap,
  saved,
  error,
}: Props) {
  const f = facility ?? {};
  const isEdit = Boolean(f.id);

  return (
    <div className="space-y-4">
      {saved && (
        <div className="rounded-md bg-green-50 px-3 py-2 text-sm text-green-700">
          Saved.
        </div>
      )}
      {error && (
        <div className="rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700">
          {error}
        </div>
      )}

      <form action={action} className="space-y-6">
        {isEdit && <input type="hidden" name="id" value={f.id} />}

        <fieldset className="grid gap-4 rounded-xl border border-slate-200 bg-white p-4 sm:grid-cols-2">
          <Field label="Name" name="name" defaultValue={f.name} required />
          <Field
            label="Slug"
            name="slug"
            defaultValue={f.slug}
            placeholder="auto-generated from name if blank"
          />
          <label className="block sm:col-span-2">
            <span className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
              Description
            </span>
            <textarea
              name="description"
              rows={3}
              defaultValue={f.description ?? undefined}
              className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
            />
          </label>
          <label className="block">
            <span className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
              Status
            </span>
            <select
              name="status"
              defaultValue={f.status ?? "draft"}
              className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
            >
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </label>
          <Field
            label="Capacity (beds)"
            name="capacity"
            type="number"
            defaultValue={f.capacity}
          />
        </fieldset>

        <fieldset className="grid gap-4 rounded-xl border border-slate-200 bg-white p-4 sm:grid-cols-2">
          <Field label="Address" name="address" defaultValue={f.address} />
          <Field label="City" name="city" defaultValue={f.city} />
          <Field label="State / Region" name="region" defaultValue={f.region} />
          <Field label="Country" name="country" defaultValue={f.country ?? "USA"} />
          <Field label="Postal code" name="postal_code" defaultValue={f.postal_code} />
          <div />
          <Field
            label="Latitude"
            name="latitude"
            type="number"
            defaultValue={f.latitude}
            placeholder="e.g. 34.0522"
          />
          <Field
            label="Longitude"
            name="longitude"
            type="number"
            defaultValue={f.longitude}
            placeholder="e.g. -118.2437"
          />
        </fieldset>

        <fieldset className="grid gap-4 rounded-xl border border-slate-200 bg-white p-4 sm:grid-cols-3">
          <Field label="Phone" name="phone" defaultValue={f.phone} />
          <Field label="Email" name="email" defaultValue={f.email} />
          <Field label="Website" name="website" defaultValue={f.website} />
        </fieldset>

        <CheckboxGroup
          title="Treatments offered"
          name="treatments"
          options={treatments.map((t) => ({ id: t.id, label: t.name }))}
          selected={selectedTreatmentIds}
        />

        <CheckboxGroup
          title="Amenities"
          name="amenities"
          options={amenities.map((a) => ({ id: a.id, label: a.name }))}
          selected={selectedAmenityIds}
        />

        <fieldset className="space-y-3 rounded-xl border border-slate-200 bg-white p-4">
          <legend className="text-sm font-semibold text-slate-800">
            Policies
          </legend>
          {policyTypes.map((pt) => {
            const current = policyMap[pt.id];
            return (
              <div
                key={pt.id}
                className="grid items-center gap-2 sm:grid-cols-[1fr_10rem_1fr]"
              >
                <span className="text-sm text-slate-700">{pt.label}</span>
                <select
                  name={`policy__${pt.id}`}
                  defaultValue={current?.value ?? ""}
                  className="rounded-md border border-slate-300 px-2 py-1.5 text-sm"
                >
                  <option value="">— not set —</option>
                  {pt.value_type === "boolean" ? (
                    <>
                      <option value="yes">Yes</option>
                      <option value="no">No</option>
                    </>
                  ) : pt.value_type === "text" ? (
                    <option value="see-notes">See notes</option>
                  ) : (
                    POLICY_ENUM_VALUES.map((v) => (
                      <option key={v} value={v}>
                        {v}
                      </option>
                    ))
                  )}
                </select>
                <input
                  type="text"
                  name={`note__${pt.id}`}
                  defaultValue={current?.notes ?? undefined}
                  placeholder="Notes (optional)"
                  className="rounded-md border border-slate-300 px-2 py-1.5 text-sm"
                />
              </div>
            );
          })}
        </fieldset>

        <div className="flex items-center gap-3">
          <button
            type="submit"
            className="rounded-md bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
          >
            {isEdit ? "Save changes" : "Create facility"}
          </button>
        </div>
      </form>

      {isEdit && (
        <form action={deleteFacility} className="border-t border-slate-200 pt-4">
          <input type="hidden" name="id" value={f.id} />
          <button
            type="submit"
            className="text-sm text-rose-600 hover:underline"
          >
            Delete facility
          </button>
        </form>
      )}
    </div>
  );
}

function CheckboxGroup({
  title,
  name,
  options,
  selected,
}: {
  title: string;
  name: string;
  options: { id: string; label: string }[];
  selected: string[];
}) {
  return (
    <fieldset className="rounded-xl border border-slate-200 bg-white p-4">
      <legend className="text-sm font-semibold text-slate-800">{title}</legend>
      <div className="mt-2 grid gap-1.5 sm:grid-cols-2 lg:grid-cols-3">
        {options.map((opt) => (
          <label
            key={opt.id}
            className="flex items-center gap-2 text-sm text-slate-700"
          >
            <input
              type="checkbox"
              name={name}
              value={opt.id}
              defaultChecked={selected.includes(opt.id)}
              className="h-4 w-4 rounded border-slate-300 text-teal-600"
            />
            {opt.label}
          </label>
        ))}
      </div>
    </fieldset>
  );
}
