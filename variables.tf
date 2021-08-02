variable "region" {
  type        = string
  default     = "us-west-2"
  description = "The default region."
}

# What account do you want to deploy into?
variable "account" {
  type = string
  default = "{your account id}"
}

# Where do you store your AWS credentials?
variable "credentials-file" {
  type = string
  default = "~/.aws/credentials"
}

variable "project_name" {
  type = string
  default = "gmo-private-link-test"
}

# SSH keypair related variables

# aws keypair reference name
variable "keypair_name" {
  type = string
  default = "gmo-test"
}

# Your actual public key string.
variable "ssh_pubkey" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbpV3hxupaKfijO8nfPG9ps08KrRRuCU71jbW6yd49GmLt3hpxRDvQ43XL6ZV2XWASRse8q63+zRhbfoxT4Ur2+UAKzzHAVetA9GztY2agTnc58j04iY+Slok0VHLYmCgmEP3h+plw7Hxuwhovo20k+4yaad5W7Fti0vT47sWLHyYycz9BQDHu+ZBNMp9yb2FPW1POHFgbgb/lWv7ACwiE1uCYn/ECyN2xKATJVo71F5sdz1PMERfkEuQGQu1ECtJZfJMwSx8IGgrbKWjiVQsa5Tf7PB/JWtAtg5r3agiqjbPvgYUdVo/+MpQ5ozrZzvTsAQ6Tc73Ydy7BvySDeFWR"
}

# The local path to your ssh private key
variable "local_ssh_privkey" {
  type = string
  default = "~/.ssh/gmo-test.pem"
}

# Provider VPC Variables

variable "public_cidr" {
  type = string
  default = "10.8.0.0/19"
}

variable "private_cidr" {
  type = string
  default = "10.32.0.0/19"
}

variable "public_subnet_cidr_blocks" {
  type = list
  default = [ "10.8.0.0/21", "10.8.8.0/21", "10.8.16.0/21"]
}

variable "private_subnet_cidr_blocks" {
  type = list
  default = [ "10.32.0.0/21", "10.32.8.0/21", "10.32.16.0/21"]
}

variable "deletion_protection" {
  default     = false
  description = "Will we block the LB from being removed"
  type        = string
}

variable "listener_lb_port" {
  default     = 8000
  description = "HTTP port LB should listen on"
  type        = string
}

variable "listener_instance_port" {
  default     = 80
  description = "HTTP port the LB should forward traffic to"
  type        = string
}

# Consumer VPC Variables
//
//variable "consumer_public_cidr" {
//  type = string
//  default = "10.64.0.0/19"
//}
//
//variable "consumer_private_cidr" {
//  type = string
//  default = "10.96.0.0/19"
//}
//
//variable "consumer_public_subnet_cidr_blocks" {
//  type = list
//  default = [ "10.64.0.0/21", "10.64.8.0/21", "10.64.16.0/21"]
//}
//
//variable "consumer_private_subnet_cidr_blocks" {
//  type = list
//  default = [ "10.96.0.0/21", "10.96.8.0/21", "10.96.16.0/21"]
//}


# Remote VPC Variables

variable "remote_public_cidr" {
  type = string
  default = "10.0.0.0/19"
}

variable "remote_private_cidr" {
  type = string
  default = "10.32.0.0/19"
}

variable "remote_public_subnet_cidr_blocks" {
  type = list
  default = [ "10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]
}

variable "remote_private_subnet_cidr_blocks" {
  type = list
  default = [ "10.32.0.0/21", "10.32.8.0/21", "10.32.16.0/21"]
}
