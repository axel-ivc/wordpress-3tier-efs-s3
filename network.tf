# VPC
resource "aws_vpc" "WebApps-vpc" {
  cidr_block           = var.VPC_NET
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = { Name = "WebApps-vpc" }
}

###############################################################################
# PUBLIC PART
###############################################################################

# ALB public subnets
# One subnet in each AZ
resource "aws_subnet" "WebApps-SubNpublic" {
  count = 2

  vpc_id                  = aws_vpc.WebApps-vpc.id
  cidr_block              = var.VPC_PUBLIC_SUBNETS[count.index]
  availability_zone       = var.VPC_AZS[count.index]
  map_public_ip_on_launch = "true"

  tags = { Name = "WebApps-SubNpublic${count.index}" }
}

# Security group for public subnets
resource "aws_security_group" "WebApps-SGpublic" {
  name        = "webapps-public"
  description = "SG for public subnets"
  vpc_id      = aws_vpc.WebApps-vpc.id

  ingress {
    protocol = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["77.222.156.0/23"]
    from_port   = 80
    to_port     = 80
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["77.222.156.0/23"]
    from_port   = 22
    to_port     = 22
  }

  ingress {
    protocol    = "-1"
    cidr_blocks = [var.VPC_NET]
    from_port   = 0
    to_port     = 0
  }

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = { Name = "WebApps-SGpublic" }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "WebApps-igw" {
  vpc_id = aws_vpc.WebApps-vpc.id

  tags = { Name = "WebApps-igw" }
}

# Route table for public subnets (default route to IGW)
resource "aws_route_table" "WebApps-RTigw" {
  vpc_id = aws_vpc.WebApps-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.WebApps-igw.id
  }

  tags = { Name = "WebApps-RTigw" }
}

# Assign route table to public subnets
resource "aws_route_table_association" "WebApps-RTassocPub" {
  count = 2

  subnet_id      = aws_subnet.WebApps-SubNpublic[count.index].id
  route_table_id = aws_route_table.WebApps-RTigw.id
}

###############################################################################
# PRIVATE PART
###############################################################################

# APP/RDS private subnets
# One APP subnet and one RDS subnet in each AZ
resource "aws_subnet" "WebApps-SubNprivate" {
  vpc_id                  = aws_vpc.WebApps-vpc.id
  map_public_ip_on_launch = "false"

  for_each          = var.VPC_PRIVATE_SUBNETS
  cidr_block        = each.value
  availability_zone = var.VPC_AZS[replace(each.key, "/^(APP|RDS)/", "") == "a" ? 0 : 1]

  tags = { Name = "WebApps-SubNprivate${each.key}" }
}

# Security group for private subnets
resource "aws_security_group" "WebApps-SGprivate" {
  name        = "webapps-private"
  description = "SG for private subnets"
  vpc_id      = aws_vpc.WebApps-vpc.id

  ingress {
    protocol    = "-1"
    cidr_blocks = [var.VPC_NET]
    from_port   = 0
    to_port     = 0
  }

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = { Name = "WebApps-SGprivate" }
}

# Network interface for NAT instance
resource "aws_network_interface" "WebApps-NATeni" {
  subnet_id         = aws_subnet.WebApps-SubNpublic[0].id
  security_groups   = [aws_security_group.WebApps-SGpublic.id]
  source_dest_check = false
  description       = "NAT instance ENI"

  tags = { Name = "WebApps-NATeni" }
}

# EIP and its association can be enabled
# resource "aws_eip" "nat_instance_eip" {
#   vpc = true
#   network_interface = aws_network_interface.WebApps-NATeni.id

#   tags = { Name  = "WebApps-EIP" }
# }

# Route table for private subnets (default route to NAT's ENI)
resource "aws_route_table" "WebApps-RTnat" {
  vpc_id = aws_vpc.WebApps-vpc.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.WebApps-NATeni.id
  }

  # Do not alter RT because of NAT instance ID changes
  lifecycle {
    ignore_changes = [route]
  }

  tags = { Name = "WebApps-RTnat" }
}

# Assign route table to private subnets
resource "aws_route_table_association" "WebApps-RTassocPriv" {
  for_each = var.VPC_PRIVATE_SUBNETS

  subnet_id      = aws_subnet.WebApps-SubNprivate[each.key].id
  route_table_id = aws_route_table.WebApps-RTnat.id
}