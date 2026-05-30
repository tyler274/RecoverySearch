output "public_ip" {
  value = module.aws.public_ip
}

output "app_url" {
  value = module.aws.app_url
}

output "supabase_api_url" {
  value = module.aws.supabase_api_url
}

output "ssh_command" {
  value = module.aws.ssh_command
}
