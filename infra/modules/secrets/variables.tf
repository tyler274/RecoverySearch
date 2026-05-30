variable "name_prefix" {
  description = "Prefix for named resources (Vault policy/role, Doppler config, KV path segment)."
  type        = string
}

variable "secrets_backend" {
  description = "Where secret material lives and how the VM reads it at boot. One of 'vault', 'doppler', or 'cloud_native' (the per-cloud module writes to Key Vault / Secrets Manager / Secret Manager)."
  type        = string
  default     = "vault"

  validation {
    condition     = contains(["vault", "doppler", "cloud_native"], var.secrets_backend)
    error_message = "secrets_backend must be one of: vault, doppler, cloud_native."
  }
}

variable "cloud" {
  description = "Target cloud, used for optional Vault cloud-auth wiring and cloud_native routing: 'azure', 'aws', or 'gcp'."
  type        = string

  validation {
    condition     = contains(["azure", "aws", "gcp"], var.cloud)
    error_message = "cloud must be one of: azure, aws, gcp."
  }
}

variable "dashboard_username" {
  description = "Username for the Supabase Studio dashboard (stored alongside the secrets for a single source of truth)."
  type        = string
  default     = "supabase"
}

# ---------------------------------------------------------------------------
# Vault backend
# ---------------------------------------------------------------------------

variable "vault_kv_mount" {
  description = "Mount path of the Vault KV v2 secrets engine."
  type        = string
  default     = "secret"
}

variable "vault_secret_path" {
  description = "Path within the KV mount where the stack secrets are written."
  type        = string
  default     = "recoverysearch"
}

variable "vault_auth_method" {
  description = "Vault auth method the VM uses at boot. 'approle' is portable across all clouds; 'cloud_iam' uses the cloud-native Vault auth backend (Azure/AWS/GCP)."
  type        = string
  default     = "approle"

  validation {
    condition     = contains(["approle", "cloud_iam"], var.vault_auth_method)
    error_message = "vault_auth_method must be 'approle' or 'cloud_iam'."
  }
}

# ---------------------------------------------------------------------------
# Doppler backend
# ---------------------------------------------------------------------------

variable "doppler_project" {
  description = "Doppler project name to create/use for this deployment."
  type        = string
  default     = "recoverysearch"
}

variable "doppler_config" {
  description = "Doppler config (environment branch) name to store the stack secrets in."
  type        = string
  default     = "prd"
}

variable "doppler_environment_slug" {
  description = "Doppler environment slug the config belongs to."
  type        = string
  default     = "prd"
}
