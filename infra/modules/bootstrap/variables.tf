variable "supabase_public_url" {
  description = "Externally reachable base URL of the Supabase API gateway (Kong), e.g. http://203.0.113.10:8000 or https://api.example.com."
  type        = string
}

variable "site_url" {
  description = "Externally reachable base URL of the Next.js app, used as the auth SITE_URL, e.g. http://203.0.113.10:3000."
  type        = string
}

variable "additional_redirect_urls" {
  description = "Comma-separated extra auth redirect URLs."
  type        = string
  default     = ""
}

variable "app_repo_url" {
  description = "Git URL of this repository; cloned onto the persistent disk at boot."
  type        = string
}

variable "app_repo_ref" {
  description = "Git ref (branch/tag/sha) to check out."
  type        = string
  default     = "main"
}

variable "app_dir" {
  description = "Directory on the VM where the repo is cloned and Compose runs (lives on the persistent data disk)."
  type        = string
  default     = "/opt/recoverysearch"
}

variable "data_device" {
  description = "Block device path of the attached persistent disk to host app_dir (e.g. /dev/sdc, /dev/nvme1n1). Empty string uses the root disk (no separate mount)."
  type        = string
  default     = ""
}

variable "web_http_port" {
  description = "Host port the Next.js app is published on."
  type        = number
  default     = 3000
}

variable "secrets_backend" {
  description = "How the VM fetches secrets at boot: vault | doppler | cloud_native."
  type        = string

  validation {
    condition     = contains(["vault", "doppler", "cloud_native"], var.secrets_backend)
    error_message = "secrets_backend must be one of: vault, doppler, cloud_native."
  }
}

variable "vault" {
  description = "Vault access details (set only when secrets_backend = 'vault')."
  type = object({
    address      = string
    kv_mount     = string
    secret_path  = string
    approle_path = string
    role_id      = string
    secret_id    = string
  })
  default   = null
  sensitive = true
}

variable "doppler" {
  description = "Doppler access details (set only when secrets_backend = 'doppler')."
  type = object({
    service_token = string
  })
  default   = null
  sensitive = true
}

variable "cloud_native" {
  description = "Cloud-native store access details (set only when secrets_backend = 'cloud_native')."
  type = object({
    provider             = string # azure | aws | gcp
    region               = optional(string, "")
    secret_name          = string
    azure_key_vault_name = optional(string, "")
    gcp_project          = optional(string, "")
  })
  default = null
}
