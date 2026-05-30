"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

function formStr(form: FormData, key: string): string {
  const v = form.get(key);
  return typeof v === "string" ? v.trim() : "";
}

export async function login(formData: FormData) {
  const email = formStr(formData, "email");
  const password = formStr(formData, "password");
  const redirectTo = formStr(formData, "redirectTo") || "/admin";

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    redirect(`/auth/login?error=${encodeURIComponent(error.message)}`);
  }
  redirect(redirectTo);
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/");
}
