"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const facilitySchema = z.object({
  name: z.string().min(1, "Name is required"),
  slug: z
    .string()
    .min(1)
    .regex(
      /^[a-z0-9-]+$/,
      "Slug may only contain lowercase letters, numbers and dashes",
    ),
  description: z.string().optional().nullable(),
  address: z.string().optional().nullable(),
  city: z.string().optional().nullable(),
  region: z.string().optional().nullable(),
  country: z.string().optional().nullable(),
  postal_code: z.string().optional().nullable(),
  latitude: z.number().min(-90).max(90).optional().nullable(),
  longitude: z.number().min(-180).max(180).optional().nullable(),
  phone: z.string().optional().nullable(),
  email: z.string().optional().nullable(),
  website: z.string().optional().nullable(),
  capacity: z.number().int().positive().optional().nullable(),
  status: z.enum(["draft", "published", "archived"]),
});

function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// FormData.get() returns string | File | null. We only ever want the string
// value from text inputs; a File entry here would be a caller mistake.
function formStr(form: FormData, key: string): string {
  const v = form.get(key);
  return typeof v === "string" ? v.trim() : "";
}

function optStr(form: FormData, key: string): string | null {
  const v = formStr(form, key);
  return v === "" ? null : v;
}

function optNum(form: FormData, key: string): number | null {
  const v = formStr(form, key);
  if (v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function parseFacility(form: FormData) {
  const name = formStr(form, "name");
  const slugRaw = formStr(form, "slug");
  const status = formStr(form, "status") || "draft";
  return facilitySchema.parse({
    name,
    slug: slugRaw || slugify(name),
    description: optStr(form, "description"),
    address: optStr(form, "address"),
    city: optStr(form, "city"),
    region: optStr(form, "region"),
    country: optStr(form, "country"),
    postal_code: optStr(form, "postal_code"),
    latitude: optNum(form, "latitude"),
    longitude: optNum(form, "longitude"),
    phone: optStr(form, "phone"),
    email: optStr(form, "email"),
    website: optStr(form, "website"),
    capacity: optNum(form, "capacity"),
    status: status as "draft" | "published" | "archived",
  });
}

async function syncRelations(facilityId: string, form: FormData) {
  const supabase = await createClient();

  const amenityIds = form.getAll("amenities").map(String).filter(Boolean);
  const treatmentIds = form.getAll("treatments").map(String).filter(Boolean);

  // Replace amenity + treatment links.
  await supabase
    .from("facility_amenities")
    .delete()
    .eq("facility_id", facilityId);
  if (amenityIds.length) {
    await supabase.from("facility_amenities").insert(
      amenityIds.map((amenity_id) => ({
        facility_id: facilityId,
        amenity_id,
      })),
    );
  }

  await supabase
    .from("facility_treatments")
    .delete()
    .eq("facility_id", facilityId);
  if (treatmentIds.length) {
    await supabase.from("facility_treatments").insert(
      treatmentIds.map((treatment_id) => ({
        facility_id: facilityId,
        treatment_id,
      })),
    );
  }

  // Policies: fields are policy__<policyTypeId> (value) + note__<policyTypeId>.
  const { data: policyTypes } = await supabase
    .from("policy_types")
    .select("id");
  await supabase
    .from("facility_policies")
    .delete()
    .eq("facility_id", facilityId);
  const rows = (policyTypes ?? [])
    .map((pt) => {
      const value = formStr(form, `policy__${pt.id}`);
      if (!value) return null;
      const notes = formStr(form, `note__${pt.id}`) || null;
      return { facility_id: facilityId, policy_type_id: pt.id, value, notes };
    })
    .filter((r): r is NonNullable<typeof r> => r !== null);
  if (rows.length) {
    await supabase.from("facility_policies").insert(rows);
  }
}

export async function createFacility(form: FormData) {
  const supabase = await createClient();
  const values = parseFacility(form);

  const { data, error } = await supabase
    .from("facilities")
    .insert(values)
    .select("id")
    .single();

  if (error) {
    redirect(
      `/admin/facilities/new?error=${encodeURIComponent(error.message)}`,
    );
  }

  await syncRelations(data.id, form);
  revalidatePath("/admin");
  redirect(`/admin/facilities/${data.id}?saved=1`);
}

export async function updateFacility(form: FormData) {
  const id = formStr(form, "id");
  if (!id) redirect("/admin");

  const supabase = await createClient();
  const values = parseFacility(form);

  const { error } = await supabase
    .from("facilities")
    .update(values)
    .eq("id", id);
  if (error) {
    redirect(
      `/admin/facilities/${id}?error=${encodeURIComponent(error.message)}`,
    );
  }

  await syncRelations(id, form);
  revalidatePath("/admin");
  revalidatePath(`/admin/facilities/${id}`);
  redirect(`/admin/facilities/${id}?saved=1`);
}

export async function deleteFacility(form: FormData) {
  const id = formStr(form, "id");
  if (!id) redirect("/admin");

  const supabase = await createClient();
  await supabase.from("facilities").delete().eq("id", id);
  revalidatePath("/admin");
  redirect("/admin");
}
