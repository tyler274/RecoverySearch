output "secret_values" {
  description = "All generated secret values. Consumed by the cloud module when secrets_backend = 'cloud_native'; otherwise informational."
  value       = local.secret_values
  sensitive   = true
}

output "secrets_backend" {
  description = "The selected secrets backend."
  value       = var.secrets_backend
}

output "vault" {
  description = "Vault access details for the VM (null unless secrets_backend = 'vault')."
  value = local.use_vault ? {
    kv_mount     = var.vault_kv_mount
    secret_path  = var.vault_secret_path
    approle_path = vault_auth_backend.approle[0].path
    role_id      = data.vault_approle_auth_backend_role_id.vm[0].role_id
    secret_id    = vault_approle_auth_backend_role_secret_id.vm[0].secret_id
  } : null
  sensitive = true
}

output "doppler" {
  description = "Doppler access details for the VM (null unless secrets_backend = 'doppler')."
  value = local.use_doppler ? {
    project       = doppler_config.this[0].project
    config        = doppler_config.this[0].name
    service_token = doppler_service_token.vm[0].key
  } : null
  sensitive = true
}
