import { getFacets } from "@/lib/queries";
import FacilityForm from "@/components/FacilityForm";
import { createFacility } from "@/app/admin/actions";

export const dynamic = "force-dynamic";

export default async function NewFacilityPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  const facets = await getFacets();

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold text-slate-900">
        New facility
      </h1>
      <FacilityForm
        action={createFacility}
        amenities={facets.amenities}
        treatments={facets.treatments}
        policyTypes={facets.policyTypes}
        selectedAmenityIds={[]}
        selectedTreatmentIds={[]}
        policyMap={{}}
        error={error}
      />
    </div>
  );
}
