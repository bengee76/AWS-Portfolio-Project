resource "aws_lambda_function" "daily_lambda" {
  function_name = "${var.project}-${var.environment}-dailyLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  filename      = "${path.module}/../../Lambda/daily.zip"
  timeout       = 30
  environment {
    variables = {
      DB_DNS      = aws_db_instance.my_db.address
      ENVIRONMENT = var.environment
    }
  }

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.private_subnets : subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  depends_on = [
    null_resource.run_zip,
    aws_db_instance.my_db
  ]
}

resource "aws_lambda_function" "seed_lambda" {
  function_name = "${var.project}-${var.environment}-seedLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "seed.handler"
  runtime       = "python3.9"
  filename      = "${path.module}/../../Lambda/seed.zip"
  timeout       = 30

  environment {
    variables = {
      DB_DNS      = aws_db_instance.my_db.address
      ENVIRONMENT = var.environment
    }
  }

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.private_subnets : subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [
    null_resource.run_zip,
    aws_db_instance.my_db
  ]
}

resource "null_resource" "run_zip" {
  provisioner "local-exec" {
    command = "sh ${path.module}/../../Scripts/zipFiles.sh"
  }
}

resource "null_resource" "run_seeder" {
  provisioner "local-exec" {
    command = <<-EOF
      aws lambda invoke --function-name ${aws_lambda_function.seed_lambda.function_name} --region ${var.region} ../../Lambda/response.json
    EOF
  }

  depends_on = [aws_lambda_function.seed_lambda]
}

resource "aws_iam_role" "lambda_role" {
  name       = "${var.project}-${var.environment}-lambdaRole"
  depends_on = [aws_subnet.private_subnets]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# resource "aws_iam_policy" "lambda_policy" {
#   name = "${var.project}-${var.environment}-lambdaPolicy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateNetworkInterface",
#           "ec2:DeleteNetworkInterface",
#           "ec2:DescribeNetworkInterfaces",
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "lambda_ENI_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_security_group" "lambda_sg" {
  name   = "${var.project}-${var.environment}-lambdaSg"
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_event_rule" "daily_rule" {
  name                = "${var.project}-${var.environment}-dailyRule"
  schedule_expression = var.environment == "production" ? "cron(0 0 * * ? *)" : "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "daily_target" {
  rule      = aws_cloudwatch_event_rule.daily_rule.name
  target_id = "${var.project}-${var.environment}-dailyTarget"
  arn       = aws_lambda_function.daily_lambda.arn
}

resource "aws_lambda_permission" "daily_permission" {
  statement_id  = "allowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_rule.arn
}

resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module}/../../Lambda
      rm -rf package/ daily/ seed/ seed.zip daily.zip models.py response.json
    EOF
  }

  depends_on = [
    aws_lambda_function.daily_lambda,
    aws_lambda_function.seed_lambda,
    null_resource.run_seeder
  ]
}