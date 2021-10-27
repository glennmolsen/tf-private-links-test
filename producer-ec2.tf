
###
### Set up a test instance
###

### keypair setup

//resource "aws_key_pair" "testingKeypair" {
//  key_name   = var.keypair_name
//  public_key = var.ssh_pubkey
//}


# gathering the AMI to build

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = [ "hvm" ]
  }
  owners = ["099720109477"] # Canonical
}

output "amis" {
  value = data.aws_ami.ubuntu.description
}

resource "aws_instance" "producers" {
  count = local.num_public_cidrs
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = element(aws_subnet.producer_public_subnets.*.id, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  key_name = var.keypair_name
  vpc_security_group_ids = [
    aws_security_group.HostSg.id,]
  associate_public_ip_address = true
  tags = {
    Name = "producer-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo /etc/init.d/nginx start",
    ]

    connection {
      type = "ssh"
      host = self.public_ip
      user = "ubuntu"
      private_key = file(var.local_ssh_privkey)
      agent = true
    }
  }
}

### Setup Public NLB

data "aws_subnet_ids" "public_subnets" {
  vpc_id = aws_vpc.producer.id
  filter {
    name = "tag:Type"
    values = [ "Public" ]
  }
  depends_on = [ aws_subnet.producer_public_subnets ]
}

resource "aws_lb" "front_end" {
  name = "producer-nlb-public"
  internal = false
  load_balancer_type = "network"
  subnets = data.aws_subnet_ids.public_subnets.ids
  enable_deletion_protection = var.deletion_protection
  enable_cross_zone_load_balancing = true
  idle_timeout = 400
  tags = {
    Name = "producer-nlb-public"
    Type = "Public"
  }
  depends_on = [ aws_route.producer_igw_route ]
}

resource "aws_lb_target_group" "tg-public" {
  name     = "tg-public"
  port     = var.listener_instance_port
  protocol = "TCP"
  vpc_id   = aws_vpc.producer.id
  tags     = {
    Name = "tg-public"
    Type = "Public"
  }
  # Use default health_check on listener_instance_port1
}

resource "aws_lb_listener" "public-listener" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = var.listener_lb_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-public.arn
  }
}

resource "aws_lb_target_group_attachment" "public-tg-attach-0" {
  target_group_arn  = aws_lb_target_group.tg-public.arn
  port              = var.listener_instance_port
  target_id           = aws_instance.producers[0].id
  depends_on = [ aws_instance.producers[0] ]
}

resource "aws_lb_target_group_attachment" "public-tg-attach-1" {
  target_group_arn  = aws_lb_target_group.tg-public.arn
  port              = var.listener_instance_port
  target_id           = aws_instance.producers[1].id
  depends_on = [ aws_instance.producers[1] ]
}

###
### Set up the PrivateLink Endpoint Service
###

//resource "aws_vpc_endpoint_service" "provider_service" {
//  acceptance_required        = false
//  network_load_balancer_arns = [aws_lb.front_end.arn]
//  tags = {
//    Name = "endpoint-service"
//    Region = var.region
//  }
//  private_dns_name = "burritos.${var.region}.sfdc.pl"
//  depends_on = [ aws_lb.front_end, aws_lb_target_group_attachment.public-tg-attach-0]
//}
