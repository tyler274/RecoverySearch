# azurerm reads the subscription from the ARM_SUBSCRIPTION_ID environment
# variable (or az login context). See infra/README.md.
provider "azurerm" {
  features {}
}

# Used only when secrets_backend = "vault". Reads VAULT_TOKEN from the
# environment when var.vault_token is empty.
provider "vault" {
  address = var.vault_address
  token   = var.vault_token != "" ? var.vault_token : null
}

# Used only when secrets_backend = "doppler".
provider "doppler" {
  doppler_token = var.doppler_token
}
