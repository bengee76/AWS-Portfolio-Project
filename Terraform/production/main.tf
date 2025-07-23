terraform {
  backend "s3" {
    bucket         = "cookie-production-remote-state"
    key            = "cookie-production/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "cookie-production-tf-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "infra" {
  source             = "../module"
  project            = var.project
  environment        = var.environment
  region             = var.region
  availability_zones = var.availability_zones
  password           = var.password
  desired            = var.desired
  max                = var.max
  min                = var.min
}

output "dns_name" {
  value = module.infra.dns_name
}