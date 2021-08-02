
###
### Set up a test instance
###


resource "aws_instance" "consumer_testInstances" {
  count = local.num_public_cidrs
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = element(aws_subnet.consumer_public_subnets.*.id, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  key_name = var.keypair_name
  vpc_security_group_ids = [
    aws_security_group.consumer_HostSg.id,]
  associate_public_ip_address = true
  tags = {
    Name = "${var.project_name}-consumer-test_instance-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt install traceroute"
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

###
### Consumer Endpoint Setup
###

// comment out to demonstrate BEFORE | AFTER
resource "aws_vpc_endpoint" "pltest_service" {
  vpc_id            = aws_vpc.consumer.id
  service_name = aws_vpc_endpoint_service.provider_service.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.consumer_HostSg.id,
  ]

  subnet_ids = data.aws_subnet_ids.consumer_private_subnets.ids
  private_dns_enabled = false
  depends_on = [ aws_vpc_endpoint_service.provider_service ]
}