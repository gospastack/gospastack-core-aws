terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Get info for aws account
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "aws_cloudfront"
}

locals {
  default_certs = var.environment != "prod" ? ["default"] : []
  acm_certs     = var.environment != "prod" ? [] : ["acm"]
  do_in_prod = var.environment != "prod" ? 0 : 1
  bucket_name = "${var.application_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.domain}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn,
      ]
    }
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.environment != "prod" ? local.bucket_name : var.domain
  tags   = var.tags
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json

}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

#resource "aws_s3_bucket_acl" "s3_bucket" {
#  bucket = aws_s3_bucket.s3_bucket.id
#  acl    = "private"
#}

resource "aws_s3_bucket_versioning" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "object" {
  bucket       = aws_s3_bucket.s3_bucket.bucket
  key          = "index.html"
  source       = "${var.file_path}/index.html"
  content_type = "text/html"
  etag         = filemd5("${var.file_path}/index.html")
}

resource "aws_s3_object" "errorobject" {
  bucket       = aws_s3_bucket.s3_bucket.bucket
  key          = "error.html"
  source       = "${var.file_path}/error.html"
  content_type = "text/html"
  etag         = filemd5("${var.file_path}/error.html")
}

# Only do this in production
data "aws_route53_zone" "domain_name" {
  count        = local.do_in_prod
  name         = var.domain
  private_zone = false
}


### ROUTE53 ###

resource "aws_route53_record" "route53_record" {
  count      = local.do_in_prod
  depends_on = [
    aws_cloudfront_distribution.s3_distribution
  ]

  zone_id = data.aws_route53_zone.domain_name[0].zone_id
  name    = var.domain
  type    = "A"

  alias {
    name    = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = "Z2FDTNDATAQYW2"

    //HardCoded value for CloudFront
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [
    aws_s3_bucket.s3_bucket
  ]

  origin {
    domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_id   = "s3-cloudfront"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases = [var.domain]

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id = "s3-cloudfront"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    # https://stackoverflow.com/questions/67845341/cloudfront-s3-etag-possible-for-cloudfront-to-send-updated-s3-object-before-t
    min_ttl     = var.cloudfront_min_ttl
    default_ttl = var.cloudfront_default_ttl
    max_ttl     = var.cloudfront_max_ttl
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geo_restriction_restriction_type
      locations = []
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.default_certs
    content {
      cloudfront_default_certificate = true
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.acm_certs
    content {
      acm_certificate_arn      = aws_acm_certificate.ssl_certificate[0].arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1"
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
  }

  wait_for_deployment = false
  tags                = var.tags
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-${var.domain}.s3.amazonaws.com"
}

resource "aws_route53_zone" "main" {
  name = "${var.domain}"
}

# SSL Certificate
resource "aws_acm_certificate" "ssl_certificate" {
  count                     = local.do_in_prod
  provider                  = aws.aws_cloudfront
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "EMAIL"
  #validation_method         = "DNS"

  tags = {Environment = var.environment}

  lifecycle {
    create_before_destroy = true
  }
}

# Uncomment the validation_record_fqdns line if you do DNS validation instead of Email.
resource "aws_acm_certificate_validation" "cert_validation" {
  provider        = aws.aws_cloudfront
  certificate_arn = aws_acm_certificate.ssl_certificate[0].arn
  #validation_record_fqdns = [for record in aws_route53_record.root_domain : record.fqdn]
}