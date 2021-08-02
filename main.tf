provider "aws" {
  region     = "us-west-2"
  profile                 = "213463172031"
}

locals {
  num_public_cidrs  = length(var.public_subnet_cidr_blocks)
  num_private_cidrs  = length(var.private_subnet_cidr_blocks)
//  num_consumer_public_cidrs  = length(var.consumer_public_subnet_cidr_blocks)
//  num_consumer_private_cidrs  = length(var.consumer_private_subnet_cidr_blocks)
  num_remote_public_cidrs  = length(var.remote_public_subnet_cidr_blocks)
  num_remote_private_cidrs  = length(var.remote_private_subnet_cidr_blocks)
  num_availability_zones = length(data.aws_availability_zones.available)
}

data "aws_availability_zones" "available" {
  state = "available"
}