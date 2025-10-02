# Reserve a static global IP address
resource "google_compute_global_address" "tag_monitoring_ip" {
  name         = local.resource_names.ip_address
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
  
  # Explicitly depend on API enablement
  depends_on = [google_project_service.compute_api]
}

# Create a health check
resource "google_compute_health_check" "tag_monitoring_health_check" {
  name                = local.resource_names.health_check
  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 1
  unhealthy_threshold = 2

  https_health_check {
    port         = 443
    request_path = "/health"
  }
  
  depends_on = [google_project_service.compute_api]
}

# Create a URL map with path matching for endpoint
resource "google_compute_url_map" "tag_monitoring_url_map" {
  name            = local.resource_names.url_map
  default_service = google_compute_backend_bucket.tag_monitoring_backend_bucket.id
  
  host_rule {
    hosts        = [var.domain]
    path_matcher = "endpoint-path"
  }
  
  path_matcher {
    name            = "endpoint-path"
    default_service = google_compute_backend_bucket.tag_monitoring_backend_bucket.id
    
    path_rule {
      paths   = [var.endpoint, "${var.endpoint}/*"]
      service = google_compute_backend_bucket.tag_monitoring_backend_bucket.id
    }
  }
  
  depends_on = [google_project_service.compute_api]
}

# Create a Google-managed SSL certificate
resource "google_compute_managed_ssl_certificate" "tag_monitoring_cert" {
  name        = local.resource_names.certificate
  description = "Google-managed certificate for tag monitoring"
  
  managed {
    domains = [var.domain]
  }
  
  depends_on = [google_project_service.compute_api]
}

# Create an HTTPS proxy
resource "google_compute_target_https_proxy" "tag_monitoring_https_proxy" {
  name             = local.resource_names.https_proxy
  url_map          = google_compute_url_map.tag_monitoring_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.tag_monitoring_cert.id]
  
  depends_on = [
    google_project_service.compute_api,
    google_compute_url_map.tag_monitoring_url_map,
    google_compute_managed_ssl_certificate.tag_monitoring_cert
  ]
}

# Create a global forwarding rule
resource "google_compute_global_forwarding_rule" "tag_monitoring_https_rule" {
  name                  = local.resource_names.forwarding_rule
  target                = google_compute_target_https_proxy.tag_monitoring_https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.tag_monitoring_ip.address
  network_tier          = "PREMIUM"
  
  depends_on = [
    google_project_service.compute_api,
    google_compute_target_https_proxy.tag_monitoring_https_proxy,
    google_compute_global_address.tag_monitoring_ip
  ]
}