terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file("/Users/maroufali/keys/gtm-monitoring-gcp-6e33c5d5ea38.json")
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  credentials = file("/Users/maroufali/keys/gtm-monitoring-gcp-6e33c5d5ea38.json")
}