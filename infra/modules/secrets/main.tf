# ---------------------------------------------------------------------------
# Secret generation (cloud- and backend-agnostic)
#
# All sensitive material for the self-hosted Supabase stack is generated here
# so there is a single source of truth regardless of which backend (Vault,
# Doppler, or a cloud-native store) ultimately stores it.
#
# Note: ANON_KEY and SERVICE_ROLE_KEY are HS256 JWTs derived from JWT_SECRET.
# They are NOT generated here -- the VM mints them deterministically at boot
# from JWT_SECRET (see modules/bootstrap), so they never need to be stored.
# ---------------------------------------------------------------------------

resource "random_password" "postgres" {
  length  = 32
  special = false # keep it URL-safe; it is embedded in postgres:// URLs
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

resource "random_password" "secret_key_base" {
  length  = 64
  special = false
}

resource "random_password" "vault_enc_key" {
  length  = 32 # Supavisor requires exactly 32 chars
  special = false
}

resource "random_password" "pg_meta_crypto_key" {
  length  = 32
  special = false
}

resource "random_password" "dashboard" {
  length  = 24
  special = false
}

resource "random_password" "logflare_public" {
  length  = 32
  special = false
}

resource "random_password" "logflare_private" {
  length  = 32
  special = false
}

resource "random_password" "s3_access_key_id" {
  length  = 20
  special = false
}

resource "random_password" "s3_access_key_secret" {
  length  = 40
  special = false
}

resource "random_string" "pooler_tenant_id" {
  length  = 12
  special = false
  upper   = false
}

locals {
  # The full set of generated values stored in the chosen backend. The VM
  # fetches these, then mints ANON_KEY/SERVICE_ROLE_KEY from JWT_SECRET.
  secret_values = {
    POSTGRES_PASSWORD             = random_password.postgres.result
    JWT_SECRET                    = random_password.jwt_secret.result
    SECRET_KEY_BASE               = random_password.secret_key_base.result
    VAULT_ENC_KEY                 = random_password.vault_enc_key.result
    PG_META_CRYPTO_KEY            = random_password.pg_meta_crypto_key.result
    DASHBOARD_USERNAME            = var.dashboard_username
    DASHBOARD_PASSWORD            = random_password.dashboard.result
    LOGFLARE_PUBLIC_ACCESS_TOKEN  = random_password.logflare_public.result
    LOGFLARE_PRIVATE_ACCESS_TOKEN = random_password.logflare_private.result
    S3_PROTOCOL_ACCESS_KEY_ID     = random_password.s3_access_key_id.result
    S3_PROTOCOL_ACCESS_KEY_SECRET = random_password.s3_access_key_secret.result
    POOLER_TENANT_ID              = random_string.pooler_tenant_id.result
  }

  use_vault   = var.secrets_backend == "vault"
  use_doppler = var.secrets_backend == "doppler"
}

# ---------------------------------------------------------------------------
# Vault backend (KV v2 + read policy + AppRole)
#
# AppRole is used (rather than a cloud IAM auth backend) because it is fully
# portable across Azure/AWS/GCP and avoids a circular dependency on the VM
# identity: the role_id/secret_id are produced before the VM and injected via
# cloud-init. See infra/README.md for wiring cloud IAM auth instead.
# ---------------------------------------------------------------------------

resource "vault_kv_secret_v2" "stack" {
  count = local.use_vault ? 1 : 0

  mount     = var.vault_kv_mount
  name      = var.vault_secret_path
  data_json = jsonencode(local.secret_values)
}

resource "vault_policy" "read" {
  count = local.use_vault ? 1 : 0

  name   = "${var.name_prefix}-read"
  policy = <<-EOT
    path "${var.vault_kv_mount}/data/${var.vault_secret_path}" {
      capabilities = ["read"]
    }
    path "${var.vault_kv_mount}/metadata/${var.vault_secret_path}" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_auth_backend" "approle" {
  count = local.use_vault ? 1 : 0

  type = "approle"
  path = "${var.name_prefix}-approle"
}

resource "vault_approle_auth_backend_role" "vm" {
  count = local.use_vault ? 1 : 0

  backend        = vault_auth_backend.approle[0].path
  role_name      = "${var.name_prefix}-vm"
  token_policies = [vault_policy.read[0].name]
  token_ttl      = 1200
  token_max_ttl  = 3600
}

resource "vault_approle_auth_backend_role_secret_id" "vm" {
  count = local.use_vault ? 1 : 0

  backend   = vault_auth_backend.approle[0].path
  role_name = vault_approle_auth_backend_role.vm[0].role_name
}

data "vault_approle_auth_backend_role_id" "vm" {
  count = local.use_vault ? 1 : 0

  backend   = vault_auth_backend.approle[0].path
  role_name = vault_approle_auth_backend_role.vm[0].role_name
}

# Guardrail: cloud_iam auth is a documented extension, not wired in this module.
resource "terraform_data" "vault_auth_guard" {
  count = local.use_vault && var.vault_auth_method != "approle" ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.vault_auth_method == "approle"
      error_message = "Only vault_auth_method='approle' is wired in modules/secrets. See infra/README.md to enable cloud IAM auth (Azure/AWS/GCP)."
    }
  }
}

# ---------------------------------------------------------------------------
# Doppler backend (project + config + secrets + read-only service token)
# ---------------------------------------------------------------------------

resource "doppler_project" "this" {
  count = local.use_doppler ? 1 : 0

  name        = var.doppler_project
  description = "RecoverySearch self-hosted Supabase stack secrets (managed by Terraform)."
}

resource "doppler_config" "this" {
  count = local.use_doppler ? 1 : 0

  project     = doppler_project.this[0].name
  environment = var.doppler_environment_slug
  name        = var.doppler_config
}

resource "doppler_secret" "stack" {
  for_each = local.use_doppler ? local.secret_values : {}

  project = doppler_config.this[0].project
  config  = doppler_config.this[0].name
  name    = each.key
  value   = each.value
}

resource "doppler_service_token" "vm" {
  count = local.use_doppler ? 1 : 0

  project = doppler_config.this[0].project
  config  = doppler_config.this[0].name
  name    = "${var.name_prefix}-vm"
  access  = "read"
}
