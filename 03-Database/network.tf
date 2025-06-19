resource "aws_vpc" "myVpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        name = "myVPC"
    }
}

resource "aws_subnet" "subnetPublic_1a" {
    vpc_id            = aws_vpc.myVpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "eu-central-1a"
    tags = {
        name = "subnetPublic_1a"
    }
}

resource "aws_subnet" "subnetPublic_1b" {
    vpc_id = aws_vpc.myVpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-central-1b"
    tags = {
        name = "subnetPublic_1b"
    }
}       

resource "aws_subnet" "subnetPrivate_1a" {
    vpc_id            = aws_vpc.myVpc.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "eu-central-1a"
    tags = {
        name = "subnetPrivate_1a"
    }
}

resource "aws_subnet" "subnetPrivate_1b" {
    vpc_id            = aws_vpc.myVpc.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "eu-central-1b"
    tags = {
        name = "subnetPrivate_1b"
    }
}

resource "aws_internet_gateway" "internetGateway" {
    vpc_id = aws_vpc.myVpc.id
    tags = {
        name = "internetGateway"
    }  
}

resource "aws_route_table" "publicRouteTable" {
    vpc_id = aws_vpc.myVpc.id
    tags = {
        name = "publicRouteTable"
    }
}

resource "aws_route" "publicRoute" {
    route_table_id         = aws_route_table.publicRouteTable.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.internetGateway.id
}

resource "aws_route_table_association" "subnetPublicAssociation1a" {
    subnet_id      = aws_subnet.subnetPublic_1a.id
    route_table_id = aws_route_table.publicRouteTable.id
}
resource "aws_route_table_association" "subnetPublicAssociation1b" {
    subnet_id      = aws_subnet.subnetPublic_1b.id
    route_table_id = aws_route_table.publicRouteTable.id
}

resource "aws_eip" "natEip_1a" {
    domain = "vpc"
}

resource "aws_eip" "natEip_1b" {
    domain = "vpc"
}

resource "aws_nat_gateway" "natGateway_1a" {
    subnet_id = aws_subnet.subnetPublic_1a.id
    allocation_id = aws_eip.natEip_1a.id
    depends_on = [ aws_internet_gateway.internetGateway ]
}
resource "aws_nat_gateway" "natGateway_1b" {
    subnet_id = aws_subnet.subnetPublic_1b.id
    allocation_id = aws_eip.natEip_1b.id
    depends_on = [ aws_internet_gateway.internetGateway ]
}

resource "aws_route_table" "privateRouteTable_1a" {
    vpc_id = aws_vpc.myVpc.id
    tags = {
        name = "privateRouteTable_1a"
    }
}

resource "aws_route_table" "privateRouteTable_1b" {
    vpc_id = aws_vpc.myVpc.id
    tags = {
        name = "privateRouteTable_1b"
    }
}

resource "aws_route" "privateRoute_1a" {
    route_table_id         = aws_route_table.privateRouteTable_1a.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.natGateway_1a.id
}

resource "aws_route" "privateRoute_1b" {
    route_table_id         = aws_route_table.privateRouteTable_1b.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.natGateway_1b.id
}

resource "aws_route_table_association" "subnetPrivateAssociation_1a" {
    subnet_id      = aws_subnet.subnetPrivate_1a.id
    route_table_id = aws_route_table.privateRouteTable_1a.id
}

resource "aws_route_table_association" "subnetPrivateAssociation_1b" {
    subnet_id      = aws_subnet.subnetPrivate_1b.id
    route_table_id = aws_route_table.privateRouteTable_1b.id
}

resource "aws_db_subnet_group" "dbGroup" {
    name       = "db subnet group"
    subnet_ids = [aws_subnet.subnetPrivate_1a.id, aws_subnet.subnetPrivate_1b.id]
}