variable "name_prefix" {
  type    = string
  default = "recoverysearch"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = ""
}

variable "instance_size" {
  type    = string
  default = "t3.large"
}

variable "ssh_public_key" {
  description = "SSH public key contents for the default user."
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

variable "route53_zone_id" {
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
  description = "vault | doppler | cloud_native (AWS Secrets Manager)."
  type        = string
  default     = "vault"
}

variable "vault_address" {
  type    = string
  default = ""
}

variable "vault_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "vault_kv_mount" {
  type    = string
  default = "secret"
}

variable "vault_secret_path" {
  type    = string
  default = "recoverysearch"
}

variable "doppler_token" {
  type      = string
  default   = ""
  sensitive = true
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
