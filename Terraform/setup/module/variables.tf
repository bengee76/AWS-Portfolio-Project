variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "bucket name for remote state"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "users" {
  type        = list(string)
  description = "List of db user - must be same order as passwords"
}

variable "passwords" {
  description = "List of db passwords - must be same order as users"
  type        = list(string)
  sensitive   = true
}