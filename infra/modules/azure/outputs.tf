output "public_ip" {
  description = "Public IP of the VM."
  value       = azurerm_public_ip.this.ip_address
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
  description = "SSH into the VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}"
}
