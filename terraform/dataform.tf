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
  
  # GitHub connection configuration
  git_remote_settings {
    url                                 = "https://github.com/${var.github_username}/${var.github_repository}.git"
    default_branch                      = var.github_default_branch
    authentication_token_secret_version = google_secret_manager_secret_version.github_token_version.id
  }
  
  depends_on = [
    google_project_service.dataform_api,
    google_secret_manager_secret_version.github_token_version
  ]
}

# Grant the Dataform service agent access to the GitHub token secret
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
