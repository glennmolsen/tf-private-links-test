
###
### Consumer VPC Setup
###


resource "aws_vpc" "consumer" {
  cidr_block       = var.private_cidr
  tags = {
    Name = "${var.project_name}-consumer"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "consumer_secondary_cidr" {
  vpc_id = aws_vpc.consumer.id
  cidr_block = var.public_cidr
}

resource "aws_subnet" "consumer_public_subnets" {
  count                   = local.num_public_cidrs
  vpc_id                  = aws_vpc.consumer.id
  cidr_block              = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-consumer-public_subnet-${count.index}",
    Type = "Public"
  }
  depends_on = [ aws_vpc.consumer ]
}

### Routing

resource "aws_internet_gateway" "consumer_igw" {
  vpc_id = aws_vpc.consumer.id

  tags = {
    Name = "${var.project_name}-consumer-igw"
  }
}

resource "aws_route_table" "consumer_public_route_table" {
  count  = local.num_public_cidrs
  vpc_id = aws_vpc.consumer.id
  tags = {
    Name = "${var.project_name}-consumer-public_route_table-${count.index}"
  }
}

resource "aws_route" "consumer_igw_route" {
  count                  = local.num_public_cidrs
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.consumer_igw.id
  route_table_id         = element(aws_route_table.consumer_public_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
}

resource "aws_route" "consumer_public_tgw_route" {
  count = local.num_public_cidrs
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  route_table_id         = element(aws_route_table.consumer_public_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.consumer_fd_tgw_attach]
}

resource "aws_route_table_association" "consumer_public_route_association" {
  count          = local.num_public_cidrs
  subnet_id      = element(aws_subnet.consumer_public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.consumer_public_route_table.*.id, count.index)
}

resource "aws_subnet" "consumer_private_subnets" {
  count                   = local.num_private_cidrs
  vpc_id                  = aws_vpc.consumer.id
  cidr_block              = element(var.private_subnet_cidr_blocks, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.project_name}-consumer-private_subnet-${count.index}",
    Type = "Private"
  }
  depends_on = [ aws_vpc_ipv4_cidr_block_association.consumer_secondary_cidr ]
}

resource "aws_route_table" "consumer_private_route_table" {
  count  = local.num_private_cidrs
  vpc_id = aws_vpc.consumer.id
  tags = {
    Name = "${var.project_name}-consumer-private_route_table-${count.index}"
  }
}

resource "aws_route" "consumer_tgw_route" {
  count                  = local.num_private_cidrs
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  route_table_id         = element(aws_route_table.consumer_private_route_table.*.id, count.index)
  timeouts {
    create = "10m"
  }
}

resource "aws_route_table_association" "consumer_private_route_association" {
  count          = local.num_private_cidrs
  subnet_id      = element(aws_subnet.consumer_private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.consumer_private_route_table.*.id, count.index)
}

### Wide open security groups, we're not testing that.
resource "aws_security_group" "consumer_HostSg" {
  name = "${var.project_name}-consumer Host SG"
  vpc_id = aws_vpc.consumer.id

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
    Name = "${var.project_name}-consumer-HostSg"
  }
}

resource "aws_default_security_group" "consumer_default-Sg" {
  vpc_id = aws_vpc.consumer.id

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

# Set up transit gateway and attach

data "aws_subnet_ids" "consumer_private_subnets" {
  vpc_id = aws_vpc.consumer.id
  filter {
    name = "tag:Type"
    values = ["Private"]
  }
  depends_on = [ aws_subnet.consumer_private_subnets ]
}

resource "aws_ec2_transit_gateway" "consumer_fd_main" {
  description = "FD Transit Gateway"
  tags = {
    Name = "${var.project_name}-consumer-TGW",
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "consumer_fd_tgw_attach" {
  subnet_ids = data.aws_subnet_ids.consumer_private_subnets.ids
  transit_gateway_id = aws_ec2_transit_gateway.consumer_fd_main.id
  vpc_id = aws_vpc.consumer.id
  tags = {
    Name = "${var.project_name}-consumer-TGW-attach",
  }
}
