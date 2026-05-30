terraform {
  required_version = ">= 1.5.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0.0"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = ">= 1.21.0"
    }
  }
}
