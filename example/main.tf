provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

module "gospastack" {
    source = "../modules/gospastack"
    application_name = "cloudfrontexample"
    price_class = "PriceClass_100"
    environment = "prod"
    domain = "gospastack-example.com"
    file_path = "./app/"
}
