"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";

export default function Pagination({
  page,
  pageCount,
}: {
  page: number;
  pageCount: number;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  if (pageCount <= 1) return null;

  function goTo(target: number) {
    const sp = new URLSearchParams(searchParams.toString());
    if (target <= 1) sp.delete("page");
    else sp.set("page", String(target));
    router.push(`${pathname}?${sp.toString()}`);
  }

  return (
    <div className="mt-6 flex items-center justify-center gap-3">
      <button
        type="button"
        onClick={() => {
          goTo(page - 1);
        }}
        disabled={page <= 1}
        className="rounded-md border border-slate-300 px-3 py-1.5 text-sm disabled:cursor-not-allowed disabled:opacity-40"
      >
        Previous
      </button>
      <span className="text-sm text-slate-600">
        Page {page} of {pageCount}
      </span>
      <button
        type="button"
        onClick={() => {
          goTo(page + 1);
        }}
        disabled={page >= pageCount}
        className="rounded-md border border-slate-300 px-3 py-1.5 text-sm disabled:cursor-not-allowed disabled:opacity-40"
      >
        Next
      </button>
    </div>
  );
}
