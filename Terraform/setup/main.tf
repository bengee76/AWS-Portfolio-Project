terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "eu-central-1"
}

module "staging_setup" {
  source      = "./module"
  environment = "staging"
  project     = "cookie"
  bucket_name = "cookie-staging-remote-state"
  table_name  = "cookie-staging-tf-locks"
  users       = ["admin", "user"]
  passwords   = ["", ""]
}

module "production_setup" {
  source      = "./module"
  environment = "production"
  project     = "cookie"
  bucket_name = "cookie-production-remote-state"
  table_name  = "cookie-production-tf-locks"
  users       = ["admin", "user"]
  passwords   = ["", ""]
}