resource "aws_ssm_parameter" "db_password" {
  count       = length(var.users)
  name        = "/${var.project}-${var.environment}/${var.users[count.index]}Password"
  type        = "SecureString"
  value       = var.passwords[count.index]
  overwrite   = true
  description = "${var.users[count.index]} db password"
}