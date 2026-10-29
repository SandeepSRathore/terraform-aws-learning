# A VPC is your private network in AWS. "Public" subnets have a route
# to the internet through an Internet Gateway.
#
#   VPC 10.0.0.0/16
#    ├── public subnet 10.0.0.0/24 (AZ a) ─┐
#    ├── public subnet 10.0.1.0/24 (AZ b) ─┼── route table: 0.0.0.0/0 → Internet Gateway
#    └── ...                               ─┘

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.public_subnet_count)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id = aws_vpc.this.id
  # cidrsubnet("10.0.0.0/16", 8, 1) = "10.0.1.0/24"
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, { Name = "${var.name}-public-${local.azs[count.index]}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
