resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project}-${var.environment} VPC"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.project}-${var.environment} Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.my_vpc.cidr_block, 8, count.index + 1 + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.project}-${var.environment} Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.project}-${var.environment} Internet Gateway"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.project}-${var.environment} Public Route Table"
  }
}

resource "aws_route" "publicRoute" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  count = length(var.availability_zones)
  tags = {
    Name = "${var.project}-${var.environment} NAT eip ${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.availability_zones)
  subnet_id     = aws_subnet.public_subnets[count.index].id
  allocation_id = aws_eip.nat_eip[count.index].id
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "${var.project}-${var.environment} NAT Gateway ${count.index + 1}"
  }
}

resource "aws_route_table" "private_route_tables" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.project}-${var.environment} Private Route Table ${count.index + 1}"
  }
}

resource "aws_route" "private_route" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.private_route_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private_association" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id]
  tags = {
    Name = "${var.project}-${var.environment} DB Subnet Group"
  }
}