data "aws_ami" "coockieAmi" {
  most_recent = true
  filter {
    name = "name"
    values = [ "myAmi" ]
  }
}

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

resource "aws_instance" "Test" {
  instance_type = "t2.micro"
  ami = data.aws_ami.coockieAmi.id
  subnet_id = aws_subnet.subnet_1.id
  vpc_security_group_ids = [ aws_security_group.mySg.id ]

  tags = {
    Name = "coockieAmi"
  }
}


#NO PUBLIC IPV4 ADDRESS