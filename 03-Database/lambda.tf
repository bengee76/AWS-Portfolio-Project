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

resource "aws_iam_role_policy_attachment" "lambda_ssm_policy" {
  role       = aws_iam_role.LambdaRole.name
  policy_arn = aws_iam_policy.ssmPolicy.arn
}

resource "aws_security_group" "lambdaSg" {
  name        = "lambdaSg"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.rdsSg.id]
  }
}

resource "null_resource" "lambdaLayer" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash    
      cd ${path.module}/Lambda
      pip install -r requirements.txt -t python/
    EOF
  }  
}

resource "archive_file" "layerZip" {
  type = "zip"
  output_path = "${path.module}/Lambda/layers/dailyLambdaLayer.zip"
  source_dir = "$(path.module)/Lambda/python)"
  depends_on = [ null_resource.lambdaLayer ]
}

resource "aws_lambda_layer_version" "dailyLayer" {
  filename            = data.archive_file.layerZip.output_path
  layer_name          = "dailyLambdaLayer"
  compatible_runtimes = ["python3.12"]
  source_code_hash    = data.archive_file.layerZip.output_base64sha256
}

data "archive_file" "lambdaDailyZip" {
  type        = "zip"
  output_path = "${path.module}/Lambda/dailyLambda.zip"
  
  source {
    content  = file("${path.module}/Lambda/index.py")
    filename = "index.py"
  }
    source {
    content  = file("${path.module}/App/backend/Models/models.py")
    filename = "models.py"
  }
}


data "archive_file" "lambdaSeedZip" {
  type        = "zip"
  output_path = "${path.module}/Lambda/seedLambda.zip"
  
  source {
    content  = file("${path.module}/Lambda/seed.py")
    filename = "seed.py"
  }
    source {
    content  = file("${path.module}/App/backend/Models/models.py")
    filename = "models.py"
  }
}

resource "aws_lambda_function" "dailyLambda" {
  function_name = "dailyLambda"
  role          = aws_iam_role.LambdaRole.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  layers = [ aws_lambda_layer_version.dailyLayer.arn ]
  filename = data.archive_file.lambdaDailyZip.output_path
  source_code_hash = data.archive_file.lambdaDailyZip.output_base64sha256 #Track file changes

  environment {
    variables = {
      DB_DNS = aws_db_instance.dbInstance.address
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
  runtime       = "python3.12"
  layers = [ aws_lambda_layer_version.dailyLayer.arn ]
  filename = data.archive_file.lambdaSeedZip.output_path
  source_code_hash = data.archive_file.lambdaSeedZip.output_base64sha256 #Track file changes
  depends_on = [ aws_db_instance.coockieDb ]

  environment {
    variables = {
      DB_DNS = aws_db_instance.dbInstance.address
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
    security_group_ids = [aws_security_group.lambdaSg.id]
  }
}

resource "aws_cloudwatch_event_rule" "dailyRule" {
  name        = "dailyRule"
  schedule_expression = "cron(0/3 * * * *)"  #Testing, change later to "cron(0 0 * * *)"
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
      aws lambda invoke --function-name ${aws_lambda_function.seedLambda.function_name} --region eu-central-1
    EOF
  }

  depends_on = [aws_lambda_function.seedLambda]
}