# Create custom service account for Dataform
resource "google_service_account" "dataform" {
  project      = var.project_id
  account_id   = "${var.resource_prefix}-dataform-sa"
  display_name = "Dataform Custom Service Account"
  description  = "Custom service account for running Dataform workflows"
}

# Grant BigQuery Data Editor permission to the custom service account
resource "google_project_iam_member" "dataform_bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

# Grant BigQuery Job User permission to the custom service account
resource "google_project_iam_member" "dataform_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

# Create secret for GitHub token
resource "google_secret_manager_secret" "github_token" {
  project   = var.project_id
  secret_id = "${var.resource_prefix}-github-token"
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secret_manager_api]
}

# Store the GitHub token value
resource "google_secret_manager_secret_version" "github_token_version" {
  secret      = google_secret_manager_secret.github_token.id
  secret_data_wo = var.github_token
}

# Create Dataform repository
resource "google_dataform_repository" "main" {
  provider = google-beta
  project  = var.project_id
  region   = var.region
  name     = local.resource_names.dataform_repo

  service_account = google_service_account.dataform.email

  deletion_policy = "FORCE"
  
  # GitHub connection configuration
  git_remote_settings {
    url                                 = "https://github.com/${var.github_username}/${var.github_repository}.git"
    default_branch                      = var.github_default_branch
    authentication_token_secret_version = google_secret_manager_secret_version.github_token_version.id
  }
  
  depends_on = [
    google_project_service.dataform_api,
    google_secret_manager_secret_version.github_token_version,
    google_service_account.dataform
  ]
}

# Grant the Dataform service account access to the GitHub token secret
resource "google_secret_manager_secret_iam_member" "dataform_github_token_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.github_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  
  depends_on = [
    google_project_service.dataform_api,
    google_secret_manager_secret.github_token,
    google_dataform_repository.main
  ]
}

# Allow the default Dataform service agent to impersonate the custom service account
resource "google_service_account_iam_member" "dataform_agent_token_creator" {
  service_account_id = google_service_account.dataform.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  
  depends_on = [
    google_dataform_repository.main,
    google_service_account.dataform
  ]
}

resource "google_service_account_iam_member" "dataform_agent_user" {
  service_account_id = google_service_account.dataform.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  
  depends_on = [
    google_dataform_repository.main,
    google_service_account.dataform
  ]
}

# Release configuration for Dataform repository
resource "google_dataform_repository_release_config" "main" {
  provider = google-beta
  project  = var.project_id
  region   = var.region
  
  repository = google_dataform_repository.main.name
  name       = local.resource_names.dataform_release_config
  
  # Git configuration - tracks the main branch
  git_commitish = var.github_default_branch
  
  # Compilation configuration
  cron_schedule = var.dataform_release_cron
  time_zone     = var.dataform_timezone
  
  depends_on = [google_dataform_repository.main]
}

# Workflow configuration
resource "google_dataform_repository_workflow_config" "main" {
  provider = google-beta
  project  = var.project_id
  region   = var.region
  
  repository = google_dataform_repository.main.name
  name       = local.resource_names.dataform_workflow_config
  
  # Link to the release config
  release_config = google_dataform_repository_release_config.main.id
  
  # Schedule configuration
  cron_schedule = var.dataform_workflow_cron
  time_zone     = var.dataform_timezone
  
  depends_on = [google_dataform_repository_release_config.main]
}
