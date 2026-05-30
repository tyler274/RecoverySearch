variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "recoverysearch"
}

variable "region" {
  description = "AWS region (configured on the provider; recorded for outputs/secrets)."
  type        = string
}

variable "availability_zone" {
  description = "AZ for the subnet, instance, and EBS volume. Empty selects the first available AZ."
  type        = string
  default     = ""
}

variable "instance_size" {
  description = "EC2 instance type. The full stack + app needs >= 8 GB RAM."
  type        = string
  default     = "t3.large"
}

variable "ssh_public_key" {
  description = "SSH public key for the default user."
  type        = string
}

variable "admin_username" {
  description = "Default Ubuntu login user."
  type        = string
  default     = "ubuntu"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to reach SSH (22)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "web_allowed_cidr" {
  description = "CIDR allowed to reach the app/API/Studio ports."
  type        = string
  default     = "0.0.0.0/0"
}

variable "os_disk_size_gb" {
  description = "Root volume size in GB."
  type        = number
  default     = 30
}

variable "data_disk_size_gb" {
  description = "Persistent EBS data volume size in GB."
  type        = number
  default     = 64
}

variable "app_repo_url" {
  description = "Git URL of this repository."
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

variable "route53_zone_id" {
  description = "Existing Route53 hosted zone ID for an A record (optional)."
  type        = string
  default     = ""
}

variable "dns_record_name" {
  description = "FQDN for the A record (e.g. app.example.com). Required if route53_zone_id is set."
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
  description = "Generated secret values; used only when secrets_backend = 'cloud_native' to populate Secrets Manager."
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
