/**
 * Bulk import facilities from a CSV file into Supabase.
 *
 *   npm run import -- data/sample-facilities.csv
 *
 * - Geocodes rows missing lat/lng via Nominatim (rate-limited, cached).
 * - Maps amenity/treatment slugs and policy "key=value" pairs to FK rows.
 * - Upserts facilities by `slug` (idempotent) using the service-role key.
 *
 * CSV columns (header row required):
 *   external_id, name, slug, description, address, city, region, country,
 *   postal_code, latitude, longitude, phone, email, website, capacity, status,
 *   amenities, treatments, policies
 *
 *   amenities/treatments: pipe-separated slugs e.g. "gym|yoga|pool"
 *   policies: pipe-separated key=value e.g. "phones_allowed=restricted|insurance_accepted=yes"
 */
import { readFileSync, existsSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { parse } from "csv-parse/sync";
import { createClient } from "@supabase/supabase-js";
import { config } from "dotenv";
import type { Database } from "../lib/database.types";

config({ path: ".env.local" });

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error(
    "Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local",
  );
  process.exit(1);
}

const supabase = createClient<Database>(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});

const GEOCACHE_PATH = resolve("data/.geocache.json");
const geocache: Record<string, { lat: number; lng: number } | null> =
  existsSync(GEOCACHE_PATH)
    ? (JSON.parse(readFileSync(GEOCACHE_PATH, "utf8")) as Record<string, { lat: number; lng: number } | null>)
    : {};

const sleep = (ms: number) =>
  new Promise<void>((r) => {
    setTimeout(r, ms);
  });

function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function splitList(value: string): string[] {
  if (!value) return [];
  return value
    .split(/[|;]/)
    .map((s) => s.trim())
    .filter(Boolean);
}

// str() safely reads a string column from a CSV row (Record<string, string>).
// csv-parse always returns strings for all columns so the index access is safe.
function str(row: Record<string, string>, key: string): string {
  return row[key].trim();
}

async function geocode(query: string): Promise<{ lat: number; lng: number } | null> {
  if (query in geocache) return geocache[query];
  // Nominatim usage policy: max 1 request/second, descriptive User-Agent.
  await sleep(1100);
  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(query)}`;
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": "RecoverySearch/0.1 (import script)" },
    });
    const json = (await res.json()) as Array<{ lat: string; lon: string }>;
    const hit = json[0]
      ? { lat: Number(json[0].lat), lng: Number(json[0].lon) }
      : null;
    geocache[query] = hit;
    writeFileSync(GEOCACHE_PATH, JSON.stringify(geocache, null, 2));
    return hit;
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.warn(`  geocode failed for "${query}": ${message}`);
    return null;
  }
}

async function loadLookup(
  table: "amenities" | "treatments",
): Promise<Map<string, string>> {
  const { data, error } = await supabase.from(table).select("id, slug");
  if (error) throw error;
  return new Map(data.map((r) => [r.slug, r.id]));
}

async function main() {
  const file = process.argv[2] || "data/sample-facilities.csv";
  const path = resolve(file);
  if (!existsSync(path)) {
    console.error(`File not found: ${path}`);
    process.exit(1);
  }

  const rows = parse(readFileSync(path, "utf8"), {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  }) as Record<string, string>[];

  console.log(`Importing ${rows.length} rows from ${file}`);

  const amenityMap = await loadLookup("amenities");
  const treatmentMap = await loadLookup("treatments");
  const { data: policyTypes } = await supabase
    .from("policy_types")
    .select("id, key");
  const policyMap = new Map((policyTypes ?? []).map((p) => [p.key, p.id]));

  let ok = 0;
  let failed = 0;

  for (const row of rows) {
    const name = str(row, "name");
    if (!name) {
      console.warn("  skipping row with no name");
      continue;
    }
    const slug = str(row, "slug") || slugify(name);

    let lat = row["latitude"] ? Number(row["latitude"]) : null;
    let lng = row["longitude"] ? Number(row["longitude"]) : null;

    if ((lat == null || Number.isNaN(lat)) && row["address"]) {
      const query = [row["address"], row["city"], row["region"], row["postal_code"], row["country"]]
        .filter(Boolean)
        .join(", ");
      const geo = await geocode(query);
      if (geo) {
        lat = geo.lat;
        lng = geo.lng;
      }
    }

    const facilityRow: Database["public"]["Tables"]["facilities"]["Insert"] = {
      external_id: str(row, "external_id") || null,
      slug,
      name,
      description: str(row, "description") || null,
      address: str(row, "address") || null,
      city: str(row, "city") || null,
      region: str(row, "region") || null,
      country: str(row, "country") || "USA",
      postal_code: str(row, "postal_code") || null,
      latitude: lat,
      longitude: lng,
      phone: str(row, "phone") || null,
      email: str(row, "email") || null,
      website: str(row, "website") || null,
      capacity: row["capacity"] ? Number(row["capacity"]) : null,
      status: str(row, "status") || "published",
    };

    const { data: upserted, error } = await supabase
      .from("facilities")
      .upsert(facilityRow, { onConflict: "slug" })
      .select("id")
      .single();

    if (error !== null) {
      console.error(`  ✗ ${name}: ${error.message}`);
      failed++;
      continue;
    }

    const facilityId = upserted.id;

    const amenityIds = splitList(row["amenities"] ?? "")
      .map((s) => amenityMap.get(s))
      .filter((v): v is string => Boolean(v));
    const treatmentIds = splitList(row["treatments"] ?? "")
      .map((s) => treatmentMap.get(s))
      .filter((v): v is string => Boolean(v));

    await supabase.from("facility_amenities").delete().eq("facility_id", facilityId);
    if (amenityIds.length) {
      await supabase
        .from("facility_amenities")
        .insert(amenityIds.map((amenity_id) => ({ facility_id: facilityId, amenity_id })));
    }

    await supabase.from("facility_treatments").delete().eq("facility_id", facilityId);
    if (treatmentIds.length) {
      await supabase
        .from("facility_treatments")
        .insert(
          treatmentIds.map((treatment_id) => ({ facility_id: facilityId, treatment_id })),
        );
    }

    const policyRows = splitList(row["policies"] ?? "")
      .map((pair) => {
        const eqIdx = pair.indexOf("=");
        if (eqIdx < 0) return null;
        const key = pair.slice(0, eqIdx).trim();
        const value = pair.slice(eqIdx + 1).trim();
        const policy_type_id = policyMap.get(key);
        if (!policy_type_id || !value) return null;
        return { facility_id: facilityId, policy_type_id, value };
      })
      .filter((r): r is NonNullable<typeof r> => r !== null);

    await supabase.from("facility_policies").delete().eq("facility_id", facilityId);
    if (policyRows.length) {
      await supabase.from("facility_policies").insert(policyRows);
    }

    const coords =
      lat !== null ? ` (${lat.toFixed(4)}, ${lng !== null ? lng.toFixed(4) : "?"})` : " (no coords)";
    console.log(`  ✓ ${name}${coords}`);
    ok++;
  }

  console.log(`\nDone. ${ok} imported, ${failed} failed.`);
}

main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
