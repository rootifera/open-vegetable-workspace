resource "aws_vpc" "omurVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "omurVPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.omurVPC.id

  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_eip" "eip_nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip_nat_gateway.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.omurVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.omurVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "public_rt_asc_pubsb1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_asc_pubsb2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_asc_privsb1" {
  subnet_id      = aws_subnet.cluster_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_asc_privsb2" {
  subnet_id      = aws_subnet.cluster_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.omurVPC.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1f"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.omurVPC.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "cluster_subnet_1" {
  vpc_id            = aws_vpc.omurVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1f"

  tags = {
    Name = "cluster-subnet-1"
  }
}

resource "aws_subnet" "cluster_subnet_2" {
  vpc_id            = aws_vpc.omurVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "cluster-subnet-2"
  }
}

