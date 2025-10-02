variable "endpoint" {
  description = "The endpoint path to serve from the storage bucket (e.g., /collect)"
  type        = string
  default     = "/collect"
  
  validation {
    condition     = startswith(var.endpoint, "/")
    error_message = "The endpoint value must start with a forward slash (/)."
  }
}

variable "notification_users" {
  description = "The names and e-mail addresses used in the notification channel setup"
  type = list(object({
    name  = string
    email = string
  }))
}

variable "error_log_filter" {
  description = "The SQL statement to filter the logs for"
  type = string
}

variable "error_log_bucket_retention_period" {
  description = "The retention period of the log files"
  type = number
}

variable "project_id" {
  description = "The ID of the project in which to provision resources"
  type        = string
}

variable "region" {
  description = "The region in which to create regional resources"
  type        = string
}

variable "domain" {
  description = "The domain name to use for the load balancer"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix used for naming resources"
  type        = string
}

variable "log_retention_days" {
  description = "How long logs should be retained in the long bucket."
  type        = number
  default     = 30
}
# Dataform and GitHub configuration variables
variable "github_token" {
  description = "GitHub personal access token for Dataform repository connection"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username or organization name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name for Dataform"
  type        = string
}

variable "github_default_branch" {
  description = "Default branch for the GitHub repository"
  type        = string
  default     = "main"
}

# Additional variable for manual secret approach
variable "github_token_secret_name" {
  description = "Name of the manually created secret containing the GitHub token"
  type        = string
  default     = "github-token"
}

# Dataform release and workflow configuration variables
variable "dataform_release_cron" {
  description = "Cron schedule for Dataform release execution (e.g., '0 */4 * * *' for every 4 hours)"
  type        = string
  default     = "0 */1 * * *"  # Every hour by default
}

variable "dataform_workflow_cron" {
  description = "Cron schedule for Dataform workflow execution (e.g., '0 */4 * * *' for every 4 hours)"
  type        = string
  default     = "0 */1 * * *"  # Every hour by default
}

variable "dataform_timezone" {
  description = "Timezone for Dataform workflow scheduling"
  type        = string
  default     = "Europe/Amsterdam"
}
