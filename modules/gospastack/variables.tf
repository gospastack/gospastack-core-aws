variable "application_name" {
  description = "The name of the application - will be used as a marker in all resources"
  type        = string
}

variable "price_class" {
    description = "Should be one of All, 100, 200"
    type = string
}

variable "environment" {
    type = string
    description = "Name of the deployment environment"
}

variable "domain" {
    type = string
    description = "Domain name to host the application"
}

variable "file_path" {
    type = string
    description = "Local path to html file for SPA"
}
