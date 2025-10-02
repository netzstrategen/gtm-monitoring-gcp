output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = google_compute_global_address.tag_monitoring_ip.address
}

output "endpoint" {
  description = "The URL endpoint of the load balancer"
  value       = "https://${var.domain}${var.endpoint}"
}

output "dns_configuration_reminder" {
  description = "Reminder to set up DNS"
  value       = "IMPORTANT: Don't forget to create an A record for ${var.domain} pointing to ${google_compute_global_address.tag_monitoring_ip.address} in your DNS settings. Certificate provisioning will fail until this is done."
}