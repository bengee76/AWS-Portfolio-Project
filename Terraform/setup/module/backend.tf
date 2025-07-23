resource "aws_s3_bucket" "remote_state" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}