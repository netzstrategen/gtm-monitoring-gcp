# 3. Create a GCS bucket for serving content
resource "google_storage_bucket" "storage_bucket" {
  name          = local.resource_names.storage_bucket
  location      = var.region 
  force_destroy = true
  
  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "POST", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  depends_on = [google_project_service.storage_api]
}

# Upload minimal response page for endpoint
resource "google_storage_bucket_object" "empty_response" {
  name         = trimprefix(var.endpoint, "/")
  bucket       = google_storage_bucket.storage_bucket.name
  
  # Empty response
  content      = " "
  content_type = "image/gif"
   # Prevent caching to ensure all tag executions are logged
  cache_control = "no-cache, no-store, must-revalidate"
}

# Set the bucket to be publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.storage_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Create a backend bucket
resource "google_compute_backend_bucket" "tag_monitoring_backend_bucket" {
  name        = local.resource_names.backend_bucket
  bucket_name = google_storage_bucket.storage_bucket.name
  enable_cdn  = false
  
  depends_on = [
    google_project_service.compute_api,
    google_storage_bucket.storage_bucket
  ]
}