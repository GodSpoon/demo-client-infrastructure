terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Google Cloud Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  # Default labels for all resources
  default_labels = {
    client      = var.client_name
    environment = var.environment
    managed_by  = "msp-opentofu"
    project     = "demo-infrastructure"
    created_by  = "scalr"
  }

  # User project override for billing (useful when using service accounts)
  user_project_override = true

  # Billing project for quota and billing (same as project in most cases)
  billing_project = var.gcp_project_id
}
