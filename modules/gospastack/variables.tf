variable "application_name" {
  description = "The name of the application - will be used as a marker in all resources"
  type        = string
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

variable "cloudfront-authentication-user-agent" {
    default = "YouShou7DChAng3Thi$"
    type = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "tags for all the resources, if any"
}

variable "price_class" {
  default     = "PriceClass_100" // Only US,Canada,Europe
  description = "CloudFront distribution price class"
}

# All values for the TTL are important when uploading static content that changes
# https://stackoverflow.com/questions/67845341/cloudfront-s3-etag-possible-for-cloudfront-to-send-updated-s3-object-before-t
variable "cloudfront_min_ttl" {
  default     = 0
  description = "The minimum TTL for the cloudfront cache"
}

variable "cloudfront_default_ttl" {
  default     = 86400
  description = "The default TTL for the cloudfront cache"
}

variable "cloudfront_max_ttl" {
  default     = 31536000
  description = "The maximum TTL for the cloudfront cache"
}

variable "cloudfront_geo_restriction_restriction_type" {
  default     = "none"
  description = "The method that you want to use to restrict distribution of your content by country: none, whitelist, or blacklist."
  validation {
    error_message = "Can only specify either none, whitelist, blacklist"
    condition     = can(regex("^(none|whitelist|blacklist)$", var.cloudfront_geo_restriction_restriction_type))
  }
}

variable "cloudfront_geo_restriction_locations" {
  default     = []
  description = "The ISO 3166-1-alpha-2 codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist)."
  validation {
    error_message = "must be a valid ISO 3166-1-alpha-2 code"
    condition     = length([for x in  var.cloudfront_geo_restriction_locations : x if length(x) != 2]) == 0
  }
}