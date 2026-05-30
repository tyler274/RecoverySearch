import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = {
  title: "RecoverySearch",
  description:
    "Search and compare mental health recovery facilities by location, policies, amenities, and treatments.",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <html lang="en">
      <body className="min-h-screen">
        <header className="border-b border-slate-200 bg-white">
          <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
            <Link href="/" className="flex items-center gap-2">
              <span className="text-lg font-semibold text-teal-700">
                RecoverySearch
              </span>
            </Link>
            <nav className="flex items-center gap-4 text-sm">
              <Link href="/" className="text-slate-600 hover:text-slate-900">
                Search
              </Link>
              {user ? (
                <Link
                  href="/admin"
                  className="rounded-md bg-teal-600 px-3 py-1.5 font-medium text-white hover:bg-teal-700"
                >
                  Admin
                </Link>
              ) : (
                <Link
                  href="/auth/login"
                  className="text-slate-600 hover:text-slate-900"
                >
                  Sign in
                </Link>
              )}
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-6xl px-4 py-6">{children}</main>
        <footer className="mx-auto max-w-6xl px-4 py-8 text-center text-xs text-slate-400">
          RecoverySearch — informational directory only. Always verify details
          directly with each facility.
        </footer>
      </body>
    </html>
  );
}
