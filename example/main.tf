provider "aws" {
  region = "us-east-1"
}

module "gospastack" {
    source = "../modules/gospastack"

    application_name = "cloudfrontexample"

    price_class = "100"

    environment = "prod"

    domain = "gospastack-example.com"

}

