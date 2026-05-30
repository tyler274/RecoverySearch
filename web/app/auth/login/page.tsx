import { login } from "@/app/auth/actions";

export const dynamic = "force-dynamic";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; redirectTo?: string }>;
}) {
  const { error, redirectTo } = await searchParams;

  return (
    <div className="mx-auto max-w-sm">
      <h1 className="mb-1 text-xl font-semibold text-slate-900">Sign in</h1>
      <p className="mb-6 text-sm text-slate-500">
        Admin access for managing facilities.
      </p>

      {error && (
        <div className="mb-4 rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-700">
          {error}
        </div>
      )}

      <form action={login} className="space-y-4">
        <input type="hidden" name="redirectTo" value={redirectTo ?? "/admin"} />
        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">
            Email
          </label>
          <input
            type="email"
            name="email"
            required
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">
            Password
          </label>
          <input
            type="password"
            name="password"
            required
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          />
        </div>
        <button
          type="submit"
          className="w-full rounded-md bg-teal-600 px-3 py-2 text-sm font-medium text-white hover:bg-teal-700"
        >
          Sign in
        </button>
      </form>
    </div>
  );
}
