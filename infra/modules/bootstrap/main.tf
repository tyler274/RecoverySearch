locals {
  v = var.vault
  d = var.doppler
  c = var.cloud_native

  template_vars = {
    supabase_public_url      = var.supabase_public_url
    site_url                 = var.site_url
    additional_redirect_urls = var.additional_redirect_urls
    app_repo_url             = var.app_repo_url
    app_repo_ref             = var.app_repo_ref
    app_dir                  = var.app_dir
    data_device              = var.data_device
    web_http_port            = tostring(var.web_http_port)

    secrets_backend = var.secrets_backend

    vault_address      = try(local.v.address, "")
    vault_kv_mount     = try(local.v.kv_mount, "")
    vault_secret_path  = try(local.v.secret_path, "")
    vault_approle_path = try(local.v.approle_path, "")
    vault_role_id      = try(local.v.role_id, "")
    vault_secret_id    = try(local.v.secret_id, "")

    doppler_token = try(local.d.service_token, "")

    cn_provider    = try(local.c.provider, "")
    cn_region      = try(local.c.region, "")
    cn_secret_name = try(local.c.secret_name, "")
    cn_azure_vault = try(local.c.azure_key_vault_name, "")
    cn_gcp_project = try(local.c.gcp_project, "")
  }

  rendered = templatefile("${path.module}/templates/bootstrap.sh.tftpl", local.template_vars)
}
