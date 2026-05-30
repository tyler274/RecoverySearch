import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "@/app/auth/actions";

export const dynamic = "force-dynamic";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/auth/login?redirectTo=/admin");

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile?.is_admin) {
    return (
      <div className="mx-auto max-w-md rounded-xl border border-amber-200 bg-amber-50 p-6 text-center">
        <h1 className="text-lg font-semibold text-amber-900">
          Admin access required
        </h1>
        <p className="mt-2 text-sm text-amber-800">
          You are signed in as {user.email}, but this account is not an admin.
          Set <code>is_admin = true</code> on your row in the{" "}
          <code>profiles</code> table.
        </p>
        <form action={signOut} className="mt-4">
          <button className="text-sm font-medium text-teal-700 hover:underline">
            Sign out
          </button>
        </form>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-6 flex items-center justify-between border-b border-slate-200 pb-3">
        <nav className="flex gap-4 text-sm">
          <Link href="/admin" className="font-medium text-slate-800">
            Facilities
          </Link>
          <Link
            href="/admin/facilities/new"
            className="text-teal-700 hover:underline"
          >
            + New facility
          </Link>
        </nav>
        <form action={signOut}>
          <button className="text-sm text-slate-500 hover:text-slate-800">
            Sign out ({user.email})
          </button>
        </form>
      </div>
      {children}
    </div>
  );
}
