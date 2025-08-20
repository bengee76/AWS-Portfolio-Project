resource "aws_db_instance" "my_db" {
  allocated_storage      = 10
  name                   = "${var.project}_${var.environment}_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  port                   = 3306
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  username               = "root"
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot    = true
}

resource "aws_security_group" "db_sg" {
  name   = "${var.project}-${var.environment}-db-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.back_instance_sg.id, aws_security_group.lambda_sg.id]
  }

  tags = {
    Name = "${var.project}-${var.environment} DB Security Group"
  }
}