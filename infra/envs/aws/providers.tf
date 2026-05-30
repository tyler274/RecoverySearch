provider "aws" {
  region = var.region
}

# Used only when secrets_backend = "vault".
provider "vault" {
  address = var.vault_address
  token   = var.vault_token != "" ? var.vault_token : null
}

# Used only when secrets_backend = "doppler".
provider "doppler" {
  doppler_token = var.doppler_token
}
