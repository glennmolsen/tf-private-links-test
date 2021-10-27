
###
### VPC Setup
###

variable "pvtlinker_public_cidr" {
  type = string
  default = "10.8.0.0/19"
}

variable "pvtlinker_private_cidr" {
  type = string
  default = "10.32.0.0/19"
}

variable "pvtlinker_public_subnet_cidr_blocks" {
  type = list
  default = [ "10.8.0.0/21", "10.8.8.0/21"]
}

variable "pvtlinker_private_subnet_cidr_blocks" {
  type = list
  default = [ "10.32.0.0/21", "10.32.8.0/21"]
}

resource "aws_vpc" "pl" {
  cidr_block       = var.pvtlinker_private_cidr
  tags = {
    Name = "private-linker"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "pl_secondary_cidr" {
  vpc_id = aws_vpc.pl.id
  cidr_block = var.pvtlinker_public_cidr
}

resource "aws_subnet" "pl_public_subnets" {
  count                   = local.num_public_cidrs
  vpc_id                  = aws_vpc.pl.id
  cidr_block              = element(var.pvtlinker_public_subnet_cidr_blocks, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  map_public_ip_on_launch = true
  tags = {
    Name = "pl-public-${count.index}",
    Type = "Public"
  }
  depends_on = [ aws_vpc.pl ]
}

### Routing

resource "aws_internet_gateway" "pl_igw" {
  vpc_id = aws_vpc.pl.id

  tags = {
    Name = "pl-igw"
  }
}

resource "aws_route_table" "pl_public_route_table" {
  count  = local.num_public_cidrs
  vpc_id = aws_vpc.pl.id
  tags = {
    Name = "pl-public_route_table-${count.index}"
  }
}

resource "aws_route" "pl_igw_route" {
  count                  = local.num_public_cidrs
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.pl_igw.id
  route_table_id         = element(aws_route_table.pl_public_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
}

data "aws_subnet_ids" "pl_private_subnets" {
  vpc_id = aws_vpc.pl.id
  filter {
    name = "tag:Type"
    values = ["Private"]
  }
  depends_on = [ aws_subnet.pl_private_subnets ]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "pl_fd_tgw_attach" {
  subnet_ids = data.aws_subnet_ids.pl_private_subnets.ids
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  vpc_id = aws_vpc.pl.id
  tags = {
    Name = "pl-TGW-attach",
  }
}

resource "aws_route" "pl_public_tgw_route" {
  count = local.num_public_cidrs
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  route_table_id         = element(aws_route_table.pl_public_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.pl_fd_tgw_attach]
}

resource "aws_route_table_association" "pl_public_route_association" {
  count          = local.num_public_cidrs
  subnet_id      = element(aws_subnet.pl_public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.pl_public_route_table.*.id, count.index)
}

resource "aws_subnet" "pl_private_subnets" {
  count                   = local.num_private_cidrs
  vpc_id                  = aws_vpc.pl.id
  cidr_block              = element(var.pvtlinker_private_subnet_cidr_blocks, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  map_public_ip_on_launch = "false"
  tags = {
    Name = "pl-private-${count.index}",
    Type = "Private"
  }
  depends_on = [ aws_vpc_ipv4_cidr_block_association.pl_secondary_cidr ]
}

resource "aws_route_table" "pl_private_route_table" {
  count  = local.num_private_cidrs
  vpc_id = aws_vpc.pl.id
  tags = {
    Name = "pl-private_route_table-${count.index}"
  }
}

resource "aws_route" "pl_internal_tgw_route" {
  count                  = local.num_private_cidrs
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  route_table_id         = element(aws_route_table.pl_private_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
}

resource "aws_route" "pl_external_tgw_route" {
  count                  = local.num_private_cidrs
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  route_table_id         = element(aws_route_table.pl_private_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
}

resource "aws_route_table_association" "pl_private_route_association" {
  count          = local.num_private_cidrs
  subnet_id      = element(aws_subnet.pl_private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.pl_private_route_table.*.id, count.index)
}

### Wide open security groups, we're not testing that.
resource "aws_security_group" "pl_HostSg" {
  name = "pl Host SG"
  vpc_id = aws_vpc.pl.id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-linker-HostSg"
  }
}

resource "aws_default_security_group" "pl_default-Sg" {
  vpc_id = aws_vpc.pl.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




