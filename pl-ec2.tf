
###
### Set up a test instance
###


resource "aws_instance" "pvtlinker" {
  count = local.num_public_cidrs
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = element(aws_subnet.pl_public_subnets.*.id, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index % local.num_availability_zones)
  key_name = var.keypair_name
  vpc_security_group_ids = [
    aws_security_group.pl_HostSg.id,]
  associate_public_ip_address = true
  tags = {
    Name = "pvtlinker-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt install traceroute",
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
