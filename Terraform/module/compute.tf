resource "aws_lb" "front_lb" {
  name               = "${var.project}-${var.environment}-front-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.front_lb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  tags = {
    Name = "${var.project}-${var.environment} Front Load Balancer"
  }
}

resource "aws_lb_target_group" "front_target_group" {
  name     = "${var.project}-${var.environment}-front-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
  tags = {
    Name = "${var.project}-${var.environment} Front Target Group"
  }
}

resource "aws_lb_listener" "front_listener" {
  load_balancer_arn = aws_lb.front_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_target_group.arn
  }
  tags = {
    Name = "${var.project}-${var.environment} Front Listener"
  }
}

resource "aws_security_group" "front_lb_sg" {
  name   = "${var.project}-${var.environment}-front-lb-group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "back_lb" {
  name               = "${var.project}-${var.environment}-back-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.back_lb_sg.id]
  subnets            = [for subnet in aws_subnet.private_subnets : subnet.id]
  tags = {
    Name = "${var.project}-${var.environment} Back Load Balancer"
  }
}

resource "aws_lb_target_group" "back_target_group" {
  name     = "${var.project}-${var.environment}-back-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
  tags = {
    Name = "${var.project}-${var.environment} Back Target Group"
  }
}

resource "aws_lb_listener" "back_listener" {
  load_balancer_arn = aws_lb.back_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_target_group.arn
  }
}

resource "aws_security_group" "back_lb_sg" {
  name   = "${var.project}-${var.environment}-back-lb-group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.front_instance_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "front_asg" {
  name                = "${var.project}-${var.environment}-front-asg"
  desired_capacity    = var.desired
  max_size            = var.max
  min_size            = var.min
  vpc_zone_identifier = [for subnet in aws_subnet.private_subnets : subnet.id]
  launch_template {
    id = aws_launch_template.front_template.id
  }
}

resource "aws_autoscaling_group" "back_asg" {
  name                = "${var.project}-${var.environment}-back-asg"
  desired_capacity    = var.desired
  max_size            = var.max
  min_size            = var.min
  vpc_zone_identifier = [for subnet in aws_subnet.private_subnets : subnet.id]
  launch_template {
    id = aws_launch_template.back_template.id
  }
  depends_on = [null_resource.run_seeder]
}

resource "aws_autoscaling_attachment" "front_attachment" {
  autoscaling_group_name = aws_autoscaling_group.front_asg.id
  alb_target_group_arn   = aws_lb_target_group.front_target_group.arn
}

resource "aws_autoscaling_attachment" "back_attachment" {
  autoscaling_group_name = aws_autoscaling_group.back_asg.id
  alb_target_group_arn   = aws_lb_target_group.back_target_group.arn
}



resource "aws_launch_template" "front_template" {
  name                   = "${var.project}-${var.environment}-front-template"
  image_id               = "ami-009082a6cd90ccd0e"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.front_instance_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.front_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/../../Scripts/frontData.sh", {
    lbDns       = aws_lb.back_lb.dns_name,
    ENVIRONMENT = var.environment
  }))
}

resource "aws_launch_template" "back_template" {
  name                   = "${var.project}-${var.environment}-back-template"
  image_id               = "ami-009082a6cd90ccd0e"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.back_instance_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.back_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/../../Scripts/backData.sh", {
    dbDns       = aws_db_instance.my_db.address,
    ENVIRONMENT = var.environment
  }))
}

resource "aws_security_group" "front_instance_sg" {
  name   = "${var.project}-${var.environment}-front-instance-group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.front_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "back_instance_sg" {
  name   = "${var.project}-${var.environment}-back-instance-group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.back_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "front_role" {
  name = "${var.project}-${var.environment}-front-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "back_role" {
  name = "${var.project}-${var.environment}-back-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_policy" {
  name = "${var.project}-${var.environment}-ecr-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_policy" {
  name = "${var.project}-${var.environment}-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "kms:Decrypt",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.environment == "staging" ? 2 : 0
  role       = count.index == 0 ? aws_iam_role.front_role.name : aws_iam_role.back_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "ecr_front_attachment" {
  role       = aws_iam_role.front_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecr_back_attachment" {
  role       = aws_iam_role.back_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "back_ssm_attachment" {
  role       = aws_iam_role.back_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "front_profile" {
  name = "${var.project}-${var.environment}-front-instance-profile"
  role = aws_iam_role.front_role.name
}

resource "aws_iam_instance_profile" "back_profile" {
  name = "${var.project}-${var.environment}-back-instance-profile"
  role = aws_iam_role.back_role.name
}