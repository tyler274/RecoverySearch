module "secrets" {
  source = "../../modules/secrets"

  name_prefix              = var.name_prefix
  secrets_backend          = var.secrets_backend
  cloud                    = "azure"
  vault_kv_mount           = var.vault_kv_mount
  vault_secret_path        = var.vault_secret_path
  doppler_project          = var.doppler_project
  doppler_config           = var.doppler_config
  doppler_environment_slug = var.doppler_environment_slug
}

locals {
  external_secrets_access = var.secrets_backend == "cloud_native" ? null : {
    backend = var.secrets_backend
    vault = var.secrets_backend == "vault" ? {
      address      = var.vault_address
      kv_mount     = try(module.secrets.vault.kv_mount, "")
      secret_path  = try(module.secrets.vault.secret_path, "")
      approle_path = try(module.secrets.vault.approle_path, "")
      role_id      = try(module.secrets.vault.role_id, "")
      secret_id    = try(module.secrets.vault.secret_id, "")
    } : null
    doppler = var.secrets_backend == "doppler" ? {
      service_token = try(module.secrets.doppler.service_token, "")
    } : null
  }
}

module "azure" {
  source = "../../modules/azure"

  name_prefix              = var.name_prefix
  region                   = var.region
  instance_size            = var.instance_size
  ssh_public_key           = var.ssh_public_key
  ssh_allowed_cidr         = var.ssh_allowed_cidr
  web_allowed_cidr         = var.web_allowed_cidr
  data_disk_size_gb        = var.data_disk_size_gb
  app_repo_url             = var.app_repo_url
  app_repo_ref             = var.app_repo_ref
  web_http_port            = var.web_http_port
  additional_redirect_urls = var.additional_redirect_urls
  dns_zone_name            = var.dns_zone_name
  dns_zone_resource_group  = var.dns_zone_resource_group
  dns_record_name          = var.dns_record_name
  tags                     = var.tags

  secrets_backend         = var.secrets_backend
  secret_values           = module.secrets.secret_values
  external_secrets_access = local.external_secrets_access
}
