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

#Instance with Nginx web server configured with index.html file form S3 bucket
resource "aws_instance" "myInstance" {
  ami = "ami-08ec94f928cf25a9d"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.myProfile.name

  user_data = file("user-data.sh")
}

#Ami used in a Target Group in main.tf
resource "aws_ami_from_instance" "myAmiFromInstance" {
  name = "myAmi"
  source_instance_id = aws_instance.myInstance.id
  tags = {
    Name = "coockieAmi"
  }
}

#Terminate source instance after AMI creation
resource "null_resource" "terminateInastance" {
  triggers = {
    ami_id = aws_ami_from_instance.myAmiFromInstance.id
  }

  provisioner "local-exec" {
    command = <<EOT
    aws ec2 terminate-instances --instance-ids ${aws_instance.myInstance.id}
    EOT
  }

  depends_on = [ aws_ami_from_instance.myAmiFromInstance ]
}