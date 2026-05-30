output "public_ip" {
  description = "Static external IP of the instance."
  value       = google_compute_address.this.address
}

output "app_url" {
  description = "URL of the RecoverySearch web app."
  value       = local.site_url
}

output "supabase_api_url" {
  description = "URL of the Supabase API gateway (Kong)."
  value       = local.supabase_public_url
}

output "studio_url" {
  description = "Supabase Studio (Kong-proxied)."
  value       = local.supabase_public_url
}

output "ssh_command" {
  description = "SSH into the instance."
  value       = "ssh ${var.admin_username}@${google_compute_address.this.address}"
}
