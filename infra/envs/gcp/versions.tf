terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.20.0"
    }
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

  # Remote state (recommended). Initialize with:
  #   terraform init -backend-config=backend.hcl
  # backend "gcs" {}
}
