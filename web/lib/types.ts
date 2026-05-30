import type { Database } from "@/lib/database.types";

export type Tables<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Row"];

export type Facility = Tables<"facilities">;
export type Amenity = Tables<"amenities">;
export type Treatment = Tables<"treatments">;
export type PolicyType = Tables<"policy_types">;
export type FacilityPolicy = Tables<"facility_policies">;

export type FacilityStatus = "draft" | "published" | "archived";
export type PolicyValueType = "enum" | "boolean" | "text";

export type SearchResult =
  Database["public"]["Functions"]["search_facilities"]["Returns"][number];

export type SearchArgs =
  Database["public"]["Functions"]["search_facilities"]["Args"];

// Canonical enum policy values used across the UI and import pipeline.
export const POLICY_ENUM_VALUES = [
  "allowed",
  "restricted",
  "conditional",
  "prohibited",
] as const;
export type PolicyEnumValue = (typeof POLICY_ENUM_VALUES)[number];

export const FACILITY_STATUSES: FacilityStatus[] = [
  "draft",
  "published",
  "archived",
];
