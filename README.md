# gospastack-core-aws
A highly opinionated Terraform Module for deploying Go SPA Stack on AWS

### Inspiration

When looking to create a new web application, we have quite a few options. Most of those options fall into one or more of the following categories:
* Difficult to deploy
* Excessive configuration required
* Doesn't scale well
* Hard to debug / maintain
* Excellent for prototyping and GTM, but not great for long-term operation

The goal of GoSPAStack is to create a singular terraform module that will deploy a scalable, operable, single page application (SPA) backed by a Go (GoLang) REST API. In order to do this with AWS, we will take advantage of the following technologies:
* AWS Cloudfront - https://aws.amazon.com/cloudfront/
* AWS Elastic Kubernetes Service - https://aws.amazon.com/eks/
* AWS Aurora Serverless - https://aws.amazon.com/rds/aurora/serverless/

Future additions:
* AWS Elasticache
* Including edge locations

### Running the example
```
cd example
terraform init
terraform plan
terraform apply
```
