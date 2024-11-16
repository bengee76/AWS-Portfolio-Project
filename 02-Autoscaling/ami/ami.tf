#Bucket with index object used in instance
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

resource "aws_vpc" "myVpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.myVpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.myVpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
}

#Security group allowing http traffic
resource "aws_security_group" "mySg" {
  name = "myGroup"
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

#Instance with Nginx web server configured with index.html file form S3 bucket
resource "aws_instance" "myInstance" {
  ami = "ami-08ec94f928cf25a9d"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.myProfile.name
  subnet_id =  aws_subnet.subnet_1.id
  vpc_security_group_ids = [aws_security_group.mySg.id]

  user_data = file("user-data.sh")
  tags = {
    Name = "coockieInstance"
  }
}

#Ami used in a Target Group in main.tf
resource "aws_ami_from_instance" "myAmiFromInstance" {
  name = "myAmi"
  source_instance_id = aws_instance.myInstance.id
  tags = {
    Name = "coockieAmi"
  }
}