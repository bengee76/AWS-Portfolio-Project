terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "myInstance" {
  ami = "ami-00f07845aed8c0ee7"
  instance_type = "t2.micro"
  key_name = "" #Existing Key pair
  vpc_security_group_ids = [aws_security_group.mysg.id]
  tags = {
    Name = "CoockieInstance"
  }
}

resource "aws_security_group" "mysg" {
  name = "myGroup"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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