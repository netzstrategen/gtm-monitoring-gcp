resource "random_id" "bucket_suffix" {
  byte_length = 4  # Creates an 8-character hex string
}

data "google_project" "current" {}

locals {
  resource_names = {
    ip_address               = "${var.resource_prefix}-gtm-monitor-static-ip"
    health_check             = "${var.resource_prefix}-gtm-monitor-health-check"
    url_map                  = "${var.resource_prefix}-gtm-monitor-url-map"
    backend_bucket           = "${var.resource_prefix}-gtm-monitor-backend-bucket"
    certificate              = "${var.resource_prefix}-gtm-tag-monitor-cert"
    https_proxy              = "${var.resource_prefix}-gtm-tag-monitor-https-proxy"
    forwarding_rule          = "${var.resource_prefix}-gtm-tag-monitor-https-rule"
    logging_bucket           = "${var.resource_prefix}-gtm-tag-monitor-logging-bucket"
    logging_sink             = "${var.resource_prefix}-gtm-tag-monitor-logging-sink"
    storage_bucket           = "${var.resource_prefix}-gtm-tag-monitor-storage-${random_id.bucket_suffix.hex}"
    terraform_backend_bucket = "${var.resource_prefix}-gtm-tag-monitor-terraform-backend-${random_id.bucket_suffix.hex}"
    error_bucket             = "${var.resource_prefix}-gtm-tag-monitor-error-bucket"
    error_sink               = "${var.resource_prefix}-gtm-tag-monitor-error-sink"
    dataform_repo            = "${var.resource_prefix}-gtm-tag-monitor-dataform"
    dataform_release_config  = "${var.resource_prefix}-gtm-tag-monitor-rc"
    dataform_workflow_config = "${var.resource_prefix}-gtm-tag-monitor-wc"
  }
}