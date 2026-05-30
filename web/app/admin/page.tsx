import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

const STATUS_BADGE: Record<string, string> = {
  published: "bg-green-50 text-green-700",
  draft: "bg-slate-100 text-slate-600",
  archived: "bg-rose-50 text-rose-700",
};

export default async function AdminFacilitiesPage() {
  const supabase = await createClient();
  const { data: facilities } = await supabase
    .from("facilities")
    .select("id, name, city, region, status, updated_at")
    .order("updated_at", { ascending: false });

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold text-slate-900">Facilities</h1>
      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
            <tr>
              <th className="px-4 py-2">Name</th>
              <th className="px-4 py-2">Location</th>
              <th className="px-4 py-2">Status</th>
              <th className="px-4 py-2" />
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {(facilities ?? []).map((f) => (
              <tr key={f.id} className="hover:bg-slate-50">
                <td className="px-4 py-2 font-medium text-slate-800">
                  {f.name}
                </td>
                <td className="px-4 py-2 text-slate-500">
                  {[f.city, f.region].filter(Boolean).join(", ") || "—"}
                </td>
                <td className="px-4 py-2">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-medium capitalize ${
                      STATUS_BADGE[f.status] ?? "bg-slate-100 text-slate-600"
                    }`}
                  >
                    {f.status}
                  </span>
                </td>
                <td className="px-4 py-2 text-right">
                  <Link
                    href={`/admin/facilities/${f.id}`}
                    className="text-teal-700 hover:underline"
                  >
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
            {(!facilities || facilities.length === 0) && (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-8 text-center text-slate-400"
                >
                  No facilities yet.{" "}
                  <Link
                    href="/admin/facilities/new"
                    className="text-teal-700 hover:underline"
                  >
                    Create one
                  </Link>{" "}
                  or run the import script.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
