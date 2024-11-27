resource "aws_vpc" "myVpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.myVpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.myVpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-central-1b"
}

resource "aws_internet_gateway" "myGateway" {
  vpc_id = aws_vpc.myVpc.id
}

data "aws_route_table" "default" {
  vpc_id = aws_vpc.myVpc.id

  filter {
    name = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "default_route" {
  route_table_id = data.aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.myGateway.id
}

resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = data.aws_route_table.default.id
}

resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id = aws_subnet.subnet_2.id
  route_table_id = data.aws_route_table.default.id
}

#Security group allowing http trafic from LB into the instance
resource "aws_security_group" "myInstanceGroup" {
  name = "instanceGroup"
  vpc_id = aws_vpc.myVpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [ aws_security_group.myLbGroup.id ] 
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#LB security group
resource "aws_security_group" "myLbGroup" {
  name = "albGroup"
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

#Bucket with index.html object
resource "aws_s3_bucket" "myBucket" {
  bucket = "coockie-bucket-76"
}

resource "aws_s3_object" "myObject" {
  bucket = aws_s3_bucket.myBucket.bucket
  
  key = "index.html"
  source = "index.html"
}

#IAM role with attached policy allowing instance to use index object from S3 bucket
resource "aws_iam_role" "myRole" {
  name = "s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "myPolicy" {
  name   = "s3_policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.myBucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "myAttachment" {
  role = aws_iam_role.myRole.name
  policy_arn = aws_iam_policy.myPolicy.arn
}

resource "aws_iam_instance_profile" "myProfile" {
  name = "s3_profile"
  role = aws_iam_role.myRole.name
}

resource "aws_launch_template" "myTemplate" {
  name = "coockieTemplate"
  instance_type = "t2.micro"
  image_id = "ami-08ec94f928cf25a9d"
  vpc_security_group_ids = [ aws_security_group.myInstanceGroup.id ]

  iam_instance_profile {
    name = aws_iam_instance_profile.myProfile.name
  }

  user_data = base64encode(file("user-data.sh"))
}

resource "aws_autoscaling_group" "myAsg" {
  min_size = 1
  max_size = 2
  desired_capacity = 2
  vpc_zone_identifier = [ aws_subnet.subnet_1.id, aws_subnet.subnet_2.id ]
  launch_template {
    id = aws_launch_template.myTemplate.id
  }
}

resource "aws_lb" "myLb" {
  name = "coockieBalancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.myLbGroup.id ]
  subnets = [ aws_subnet.subnet_1.id, aws_subnet.subnet_2.id ]
}

resource "aws_lb_target_group" "myTargetGroup" {
  name = "coockieTarget"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myVpc.id
}

#Listener that forwards http traffic on port 80 to the Load Balancer
resource "aws_lb_listener" "myListener" {
  load_balancer_arn = aws_lb.myLb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.myTargetGroup.arn
  }
}

#Attachment that makes Instances created by ASG a part of LB target group
resource "aws_autoscaling_attachment" "myAsgAttachment" {
  autoscaling_group_name = aws_autoscaling_group.myAsg.id
  lb_target_group_arn = aws_lb_target_group.myTargetGroup.arn
}

output "balancerDns" {
  value = aws_lb.myLb.dns_name
}