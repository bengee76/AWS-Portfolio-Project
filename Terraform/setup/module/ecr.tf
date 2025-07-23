locals {
  variables = {
    ends = ["frontend", "backend"]
  }
}

resource "aws_ecr_repository" "my_ecr" {
  for_each = toset(local.variables.ends)
  name     = "${var.project}-${var.environment}/${each.value}"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr"
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  for_each   = aws_ecr_repository.my_ecr
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
