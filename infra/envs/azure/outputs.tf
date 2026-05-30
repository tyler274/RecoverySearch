output "public_ip" {
  value = module.azure.public_ip
}

output "app_url" {
  value = module.azure.app_url
}

output "supabase_api_url" {
  value = module.azure.supabase_api_url
}

output "ssh_command" {
  value = module.azure.ssh_command
}
