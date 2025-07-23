variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"

}

variable "availability_zones" {
  description = "List of azs to use for ptivate and public the subnets"
  type        = list(string)
}

variable "password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "desired" {
  description = "Desired capacity for the autoscaling groups"
  type        = number
}

variable "max" {
  description = "Maximum capacity for the autoscaling groups"
  type        = number
}

variable "min" {
  description = "Minimum capacity for the autoscaling groups"
  type        = number
}