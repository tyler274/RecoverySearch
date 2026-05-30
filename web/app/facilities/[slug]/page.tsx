import { notFound } from "next/navigation";
import Link from "next/link";
import FacilityMap from "@/components/FacilityMap";
import { getFacilityBySlug } from "@/lib/queries";

export const dynamic = "force-dynamic";

const POLICY_BADGE: Record<string, string> = {
  allowed: "bg-green-50 text-green-700",
  yes: "bg-green-50 text-green-700",
  conditional: "bg-amber-50 text-amber-700",
  restricted: "bg-amber-50 text-amber-700",
  prohibited: "bg-rose-50 text-rose-700",
  no: "bg-rose-50 text-rose-700",
};

export default async function FacilityPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const detail = await getFacilityBySlug(slug);
  if (!detail) notFound();

  const { facility, amenities, treatments, policies } = detail;
  const location = [facility.address, facility.city, facility.region, facility.postal_code]
    .filter(Boolean)
    .join(", ");

  return (
    <article className="space-y-6">
      <div>
        <Link href="/" className="text-sm text-teal-700 hover:underline">
          ← Back to search
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-slate-900">
          {facility.name}
        </h1>
        {location && <p className="mt-1 text-slate-500">{location}</p>}
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_20rem]">
        <div className="space-y-6">
          {facility.description && (
            <p className="text-slate-700">{facility.description}</p>
          )}

          <Section title="Policies">
            {policies.length === 0 ? (
              <Empty>No policies recorded yet.</Empty>
            ) : (
              <ul className="divide-y divide-slate-100">
                {policies.map(({ policy, value, notes }) => (
                  <li
                    key={policy.id}
                    className="flex items-start justify-between gap-3 py-2"
                  >
                    <div>
                      <p className="text-sm font-medium text-slate-800">
                        {policy.label}
                      </p>
                      {notes && (
                        <p className="text-xs text-slate-500">{notes}</p>
                      )}
                    </div>
                    <span
                      className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${
                        POLICY_BADGE[value.toLowerCase()] ??
                        "bg-slate-100 text-slate-600"
                      }`}
                    >
                      {value}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <Section title="Treatments offered">
            <TagList items={treatments.map((t) => t.name)} />
          </Section>

          <Section title="Amenities">
            <TagList items={amenities.map((a) => a.name)} />
          </Section>
        </div>

        <aside className="space-y-4">
          {facility.latitude != null && facility.longitude != null && (
            <div className="h-56 overflow-hidden rounded-xl border border-slate-200">
              <FacilityMap
                markers={[
                  {
                    id: facility.id,
                    slug: facility.slug,
                    name: facility.name,
                    lat: facility.latitude,
                    lng: facility.longitude,
                  },
                ]}
              />
            </div>
          )}
          <div className="space-y-2 rounded-xl border border-slate-200 bg-white p-4 text-sm">
            <h2 className="font-semibold text-slate-800">Contact</h2>
            {facility.phone && <InfoRow label="Phone" value={facility.phone} />}
            {facility.email && <InfoRow label="Email" value={facility.email} />}
            {facility.website && (
              <p>
                <span className="text-slate-500">Website: </span>
                <a
                  href={facility.website}
                  target="_blank"
                  rel="noreferrer"
                  className="text-teal-700 hover:underline"
                >
                  {facility.website}
                </a>
              </p>
            )}
            {facility.capacity != null && (
              <InfoRow label="Capacity" value={`${facility.capacity} beds`} />
            )}
            {!facility.phone &&
              !facility.email &&
              !facility.website &&
              facility.capacity == null && (
                <Empty>No contact details recorded.</Empty>
              )}
          </div>
        </aside>
      </div>
    </article>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-xl border border-slate-200 bg-white p-4">
      <h2 className="mb-2 font-semibold text-slate-800">{title}</h2>
      {children}
    </section>
  );
}

function TagList({ items }: { items: string[] }) {
  if (items.length === 0) return <Empty>None listed.</Empty>;
  return (
    <div className="flex flex-wrap gap-2">
      {items.map((item) => (
        <span
          key={item}
          className="rounded-full bg-teal-50 px-3 py-1 text-xs font-medium text-teal-700"
        >
          {item}
        </span>
      ))}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <p>
      <span className="text-slate-500">{label}: </span>
      <span className="text-slate-800">{value}</span>
    </p>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return <p className="text-sm text-slate-400">{children}</p>;
}
