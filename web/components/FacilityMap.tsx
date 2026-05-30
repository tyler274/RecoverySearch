"use client";

import dynamic from "next/dynamic";
import type { FacilityMapProps } from "@/components/FacilityMapInner";

const FacilityMapInner = dynamic(
  () => import("@/components/FacilityMapInner"),
  {
    ssr: false,
    loading: () => (
      <div className="flex h-full w-full items-center justify-center rounded-xl bg-slate-100 text-sm text-slate-400">
        Loading map…
      </div>
    ),
  },
);

export default function FacilityMap(props: FacilityMapProps) {
  return <FacilityMapInner {...props} />;
}
