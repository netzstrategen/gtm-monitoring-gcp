# Enable required APIs explicitly before creating resources
resource "google_project_service" "compute_api" {
  project                    = var.project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "storage_api" {
  project                    = var.project_id
  service                    = "storage.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "logging_api" {
  project                    = var.project_id
  service                    = "logging.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "bigquery_api" {
  project                    = var.project_id
  service                    = "bigquery.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "monitoring_api" {
  project                    = var.project_id
  service                    = "monitoring.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "dataform_api" {
  project                    = var.project_id
  service                    = "dataform.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "secret_manager_api" {
  project                    = var.project_id
  service                    = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}