variable "name_prefix" {
  type    = string
  default = "recoverysearch"
}

variable "region" {
  description = "Azure location."
  type        = string
  default     = "eastus"
}

variable "instance_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "ssh_public_key" {
  description = "SSH public key contents for the admin user."
  type        = string
}

variable "ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "web_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "data_disk_size_gb" {
  type    = number
  default = 64
}

variable "app_repo_url" {
  description = "Git URL of this repository (cloned on the VM)."
  type        = string
}

variable "app_repo_ref" {
  type    = string
  default = "main"
}

variable "web_http_port" {
  type    = number
  default = 3000
}

variable "additional_redirect_urls" {
  type    = string
  default = ""
}

variable "dns_zone_name" {
  type    = string
  default = ""
}

variable "dns_zone_resource_group" {
  type    = string
  default = ""
}

variable "dns_record_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ----- Secrets backend selection -----

variable "secrets_backend" {
  description = "vault | doppler | cloud_native (Azure Key Vault)."
  type        = string
  default     = "vault"
}

# Vault
variable "vault_address" {
  description = "Vault address the VM uses to fetch secrets (and the provider uses to write them)."
  type        = string
  default     = ""
}

variable "vault_token" {
  description = "Vault token for Terraform to write secrets. Empty falls back to VAULT_TOKEN env."
  type        = string
  default     = ""
  sensitive   = true
}

variable "vault_kv_mount" {
  type    = string
  default = "secret"
}

variable "vault_secret_path" {
  type    = string
  default = "recoverysearch"
}

# Doppler
variable "doppler_token" {
  description = "Doppler personal/service-account token for Terraform to manage secrets."
  type        = string
  default     = ""
  sensitive   = true
}

variable "doppler_project" {
  type    = string
  default = "recoverysearch"
}

variable "doppler_config" {
  type    = string
  default = "prd"
}

variable "doppler_environment_slug" {
  type    = string
  default = "prd"
}
