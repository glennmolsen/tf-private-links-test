provider "aws" {
  region     = "us-west-2"
  profile    = var.account
}

locals {
  num_public_cidrs  = length(var.producer_public_subnet_cidr_blocks)
  num_private_cidrs  = length(var.producer_private_subnet_cidr_blocks)
  num_availability_zones = length(data.aws_availability_zones.available)
}

data "aws_availability_zones" "available" {
  state = "available"
}

