output "public_ip" {
  value = module.gcp.public_ip
}

output "app_url" {
  value = module.gcp.app_url
}

output "supabase_api_url" {
  value = module.gcp.supabase_api_url
}

output "ssh_command" {
  value = module.gcp.ssh_command
}
