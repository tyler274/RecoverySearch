variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "recoverysearch"
}

variable "region" {
  description = "Azure location (e.g. eastus, westeurope)."
  type        = string
}

variable "instance_size" {
  description = "Azure VM size. The full Supabase stack + app needs >= 8 GB RAM."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "ssh_public_key" {
  description = "SSH public key for the admin user."
  type        = string
}

variable "admin_username" {
  description = "Linux admin username."
  type        = string
  default     = "azureuser"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to reach SSH (22). Restrict this in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "web_allowed_cidr" {
  description = "CIDR allowed to reach the app/API/Studio ports."
  type        = string
  default     = "0.0.0.0/0"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB."
  type        = number
  default     = 30
}

variable "data_disk_size_gb" {
  description = "Persistent data disk size in GB (hosts the app dir + Postgres data)."
  type        = number
  default     = 64
}

variable "app_repo_url" {
  description = "Git URL of this repository, cloned on the VM."
  type        = string
}

variable "app_repo_ref" {
  description = "Git ref to deploy."
  type        = string
  default     = "main"
}

variable "web_http_port" {
  description = "Host port the Next.js app listens on."
  type        = number
  default     = 3000
}

variable "additional_redirect_urls" {
  description = "Comma-separated extra auth redirect URLs."
  type        = string
  default     = ""
}

variable "dns_zone_name" {
  description = "Existing Azure DNS zone name to create an A record in (optional)."
  type        = string
  default     = ""
}

variable "dns_zone_resource_group" {
  description = "Resource group of the existing DNS zone (required if dns_zone_name is set)."
  type        = string
  default     = ""
}

variable "dns_record_name" {
  description = "A record name within the zone (e.g. 'app')."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ----- Secrets wiring -----

variable "secrets_backend" {
  description = "vault | doppler | cloud_native."
  type        = string
}

variable "secret_values" {
  description = "Generated secret values; used only when secrets_backend = 'cloud_native' to populate Key Vault."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "external_secrets_access" {
  description = "Bootstrap secrets_access object for vault/doppler backends (null for cloud_native)."
  type = object({
    backend = string
    vault = optional(object({
      address      = string
      kv_mount     = string
      secret_path  = string
      approle_path = string
      role_id      = string
      secret_id    = string
    }))
    doppler = optional(object({
      service_token = string
    }))
    cloud_native = optional(object({
      provider             = string
      region               = optional(string, "")
      secret_name          = string
      azure_key_vault_name = optional(string, "")
      gcp_project          = optional(string, "")
    }))
  })
  default   = null
  sensitive = true
}
