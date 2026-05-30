import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getFacets } from "@/lib/queries";
import FacilityForm from "@/components/FacilityForm";
import { updateFacility } from "@/app/admin/actions";

export const dynamic = "force-dynamic";

export default async function EditFacilityPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ saved?: string; error?: string }>;
}) {
  const { id } = await params;
  const { saved, error } = await searchParams;

  const supabase = await createClient();
  const facets = await getFacets();

  const { data: facility } = await supabase
    .from("facilities")
    .select("*")
    .eq("id", id)
    .maybeSingle();

  if (!facility) notFound();

  const [{ data: amRows }, { data: trRows }, { data: polRows }] =
    await Promise.all([
      supabase
        .from("facility_amenities")
        .select("amenity_id")
        .eq("facility_id", id),
      supabase
        .from("facility_treatments")
        .select("treatment_id")
        .eq("facility_id", id),
      supabase
        .from("facility_policies")
        .select("policy_type_id, value, notes")
        .eq("facility_id", id),
    ]);

  const policyMap: Record<string, { value: string; notes: string | null }> = {};
  for (const row of polRows ?? []) {
    policyMap[row.policy_type_id] = { value: row.value, notes: row.notes };
  }

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold text-slate-900">
        Edit: {facility.name}
      </h1>
      <FacilityForm
        action={updateFacility}
        facility={facility}
        amenities={facets.amenities}
        treatments={facets.treatments}
        policyTypes={facets.policyTypes}
        selectedAmenityIds={(amRows ?? []).map((r) => r.amenity_id)}
        selectedTreatmentIds={(trRows ?? []).map((r) => r.treatment_id)}
        policyMap={policyMap}
        saved={Boolean(saved)}
        error={error}
      />
    </div>
  );
}
