resource "aws_iam_role" "LambdaRole" {
  name = "dailyLambdaRole"

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

resource "aws_iam_policy" "ENI" {
  name = "ENIPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })  
}

resource "aws_iam_role_policy_attachment" "lambdaENIPolicyAttachment" {
  role       = aws_iam_role.LambdaRole.name
  policy_arn = aws_iam_policy.ENI.arn
  
}

resource "aws_iam_role_policy_attachment" "lambdaSsmPolicyAttachment" {
  role       = aws_iam_role.LambdaRole.name
  policy_arn = aws_iam_policy.ssmPolicy.arn
}

resource "aws_security_group" "lambdaSg" {
  name        = "lambdaSg"
  vpc_id = aws_vpc.myVpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "runZip" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      cp App/backend/Models/models.py Lambda/models.py
      cd Lambda
      rm -rf package daily seed seed.zip daily.zip
      pip install --target ./package sqlalchemy==2.0.41 PyMySQL==1.1.1
      mkdir seed daily
      
      cp -r package/* daily/
      cp models.py daily/
      cp index.py daily/
      cp -r package/* seed/
      cp models.py seed/
      cp seed.py seed/

      cd seed && zip -r ../seed.zip .
      cd ../daily && zip -r ../daily.zip .
    EOF
  }  
}

resource "aws_lambda_function" "dailyLambda" {
  function_name = "dailyLambda"
  role          = aws_iam_role.LambdaRole.arn
  handler       = "index.handler"
  runtime       = "python3.13"
  filename = "${path.module}/Lambda/daily.zip"
  timeout = 30
  depends_on = [ null_resource.runZip, aws_db_instance.coockieDb ]
  environment {
    variables = {
      DB_DNS = aws_db_instance.coockieDb.address
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
    security_group_ids = [aws_security_group.lambdaSg.id]
  }
}

resource "aws_lambda_function" "seedLambda" {
  function_name = "seedLambda"
  role          = aws_iam_role.LambdaRole.arn
  handler       = "seed.handler"
  runtime       = "python3.13"
  filename = "${path.module}/Lambda/seed.zip"
  timeout = 30
  depends_on = [ null_resource.runZip, aws_db_instance.coockieDb ]

  environment {
    variables = {
      DB_DNS = aws_db_instance.coockieDb.address
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
    security_group_ids = [aws_security_group.lambdaSg.id]
  }
}

resource "aws_cloudwatch_event_rule" "dailyRule" {
  name        = "dailyRule"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "dailyTarget" {
  rule      = aws_cloudwatch_event_rule.dailyRule.name
  target_id = "dailyLambdaTarget"
  arn       = aws_lambda_function.dailyLambda.arn
}

resource "aws_lambda_permission" "dailyPermission" {
  statement_id  = "allowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dailyLambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dailyRule.arn
}

resource "null_resource" "runSeeder" {
  provisioner "local-exec" {
    command = <<-EOF
      aws lambda invoke --function-name ${aws_lambda_function.seedLambda.function_name} --region eu-central-1 response.json
    EOF
  }

  depends_on = [aws_lambda_function.seedLambda]
}