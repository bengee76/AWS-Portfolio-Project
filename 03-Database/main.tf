variable "adminPassword" {
  description = "Database password"
  type        = string
  sensitive = true
}

resource "aws_lb" "frontLb" {
    name               = "frontLb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.frontLbGroup.id]
    subnets            = [aws_subnet.subnetPublic_1a.id, aws_subnet.subnetPublic_1b.id]
}

resource "aws_lb" "backLb" {
    name               = "backLb"
    internal           = true
    load_balancer_type = "application"
    security_groups    = [aws_security_group.backLbGroup.id]
    subnets            = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
}

resource "aws_security_group" "frontLbGroup" {
    name = "frontLbGroup"
    vpc_id = aws_vpc.myVpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "backLbGroup" {
    name = "backLbGroup"
    vpc_id = aws_vpc.myVpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.frontInstanceGroup.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "frontInstanceGroup" {
    name = "frontInstanceGroup"
    vpc_id = aws_vpc.myVpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.frontLbGroup.id]
    }

    egress { 
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backInstanceGroup" {
    name = "backInstanceGroup"
    vpc_id = aws_vpc.myVpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.backLbGroup.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group" "frontTargetGroup" {
    name     = "frontTargetGroup"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.myVpc.id
    health_check {
        path                = "/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-299"
    }
}

resource "aws_lb_target_group" "backTargetGroup" {
    name     = "backTargetGroup"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.myVpc.id
    health_check {
        path                = "/api/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-299"
    }
}

resource "aws_lb_listener" "frontListener" {
    load_balancer_arn = aws_lb.frontLb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.frontTargetGroup.arn
    } 
}

resource "aws_lb_listener" "backListener" {
    load_balancer_arn = aws_lb.backLb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.backTargetGroup.arn
    } 
}

resource "aws_autoscaling_attachment" "frontAttachment" {
    autoscaling_group_name = aws_autoscaling_group.frontGroup.id
    lb_target_group_arn   = aws_lb_target_group.frontTargetGroup.arn
}

resource "aws_autoscaling_attachment" "backAttachment" {
    autoscaling_group_name = aws_autoscaling_group.backGroup.id
    lb_target_group_arn   = aws_lb_target_group.backTargetGroup.arn
}


resource "aws_autoscaling_group" "frontGroup" {
    desired_capacity     = 2
    max_size             = 3
    min_size             = 1
    vpc_zone_identifier  = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
    launch_template {
        id      = aws_launch_template.frontTemplate.id
    }
}

resource "aws_autoscaling_group" "backGroup" {
    desired_capacity     = 2
    max_size             = 3
    min_size             = 1
    vpc_zone_identifier  = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
    launch_template {
        id = aws_launch_template.backTemplate.id
    }
    depends_on = [ null_resource.runSeeder ]
}

resource "aws_iam_role" "frontRole" {
    name = "frontRole"

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

resource "aws_iam_role" "backRole" {
    name = "backRole"

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

resource "aws_iam_policy" "ecrPolicy" {
    name = "ecrPolicy"

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

resource "aws_iam_policy" "ssmPolicy" {
    name = "ssmPolicy"

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

resource "aws_iam_role_policy_attachment" "ecrFrontAttachment" {
    role       = aws_iam_role.frontRole.name
    policy_arn = aws_iam_policy.ecrPolicy.arn
}

resource "aws_iam_role_policy_attachment" "ecrBackAttachment" {
    role       = aws_iam_role.backRole.name
    policy_arn = aws_iam_policy.ecrPolicy.arn
}

resource "aws_iam_role_policy_attachment" "backSsmAttach" {
    role       = aws_iam_role.backRole.name
    policy_arn = aws_iam_policy.ssmPolicy.arn
}



resource "aws_iam_role_policy_attachment" "frontSsmAttach" { ###TEMORARY
  role       = aws_iam_role.frontRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "backSsmAttach" { ###TEMORARY
  role       = aws_iam_role.backRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



resource "aws_iam_instance_profile" "frontProfile" {
    name = "frontInstanceProfile"
    role = aws_iam_role.frontRole.name
}

resource "aws_iam_instance_profile" "backProfile" {
    name = "backInstanceProfile"
    role = aws_iam_role.backRole.name
}

resource "aws_launch_template" "frontTemplate" {
    name = "frontTemplate"
    image_id = "ami-009082a6cd90ccd0e"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.frontInstanceGroup.id]

    iam_instance_profile {
        name = aws_iam_instance_profile.frontProfile.name
    }

    user_data = base64encode(templatefile("${path.module}/App/frontend/frontData.sh", {
    lbDns = aws_lb.backLb.dns_name
    }))
}

resource "aws_launch_template" "backTemplate" {
    name = "backTemplate"
    image_id = "ami-009082a6cd90ccd0e"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.backInstanceGroup.id]

    iam_instance_profile {
        name = aws_iam_instance_profile.backProfile.name
    }

    user_data = base64encode(templatefile("${path.module}/App/backend/backData.sh", {
        dbDns = aws_db_instance.coockieDb.address
    }))
}

resource "aws_security_group" "dbSecurityGroup" {
  name        = "dbSecurityGroup"
  description = "Security group for the database"
  vpc_id      = aws_vpc.myVpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.backInstanceGroup.id, aws_security_group.lambdaSg.id ]
  }
}

resource "aws_db_instance" "coockieDb" {
  allocated_storage    = 20
  db_name              = "coockieDb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  port = 3306
  vpc_security_group_ids = [ aws_security_group.dbSecurityGroup.id ]
  username             = "admin"
  password             = var.adminPassword
  db_subnet_group_name = aws_db_subnet_group.dbGroup.name
}