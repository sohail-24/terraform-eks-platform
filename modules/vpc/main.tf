############################################
# Availability Zones
############################################

data "aws_availability_zones" "available" {}

############################################
# VPC
############################################

resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

############################################
# Internet Gateway
############################################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

############################################
# Public Subnets
############################################

resource "aws_subnet" "public_1" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  map_public_ip_on_launch = true

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-public-1"

    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

resource "aws_subnet" "public_2" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  map_public_ip_on_launch = true

  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-public-2"

    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

############################################
# Private Subnets
############################################

resource "aws_subnet" "private_1" {

  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_1_cidr

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-1"

    "kubernetes.io/role/internal-elb" = "1"

    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

resource "aws_subnet" "private_2" {

  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_2_cidr

  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-2"

    "kubernetes.io/role/internal-elb" = "1"

    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

############################################
# NAT Elastic IP
############################################

resource "aws_eip" "nat" {

  domain = "vpc"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

############################################
# NAT Gateway
############################################

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.project_name}-nat"
  }
}

############################################
# Public Route Table
############################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route" "public_internet" {

  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

############################################
# Public Route Associations
############################################

resource "aws_route_table_association" "public_1" {

  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {

  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

############################################
# Private Route Table
############################################

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route" "private_nat" {

  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.nat.id
  destination_cidr_block = "0.0.0.0/0"
}

############################################
# Private Route Associations
############################################

resource "aws_route_table_association" "private_1" {

  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {

  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

