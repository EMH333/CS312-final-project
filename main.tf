terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile = "default"
}

resource "aws_security_group" "mc_firewall" {
  name        = "minecraft_firewall"
  description = "Allow inbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "minecraft_tcp" {
  security_group_id = aws_security_group.mc_firewall.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 25565
  ip_protocol = "tcp"
  to_port     = 25565
}

resource "aws_vpc_security_group_ingress_rule" "minecraft_udp" {
  security_group_id = aws_security_group.mc_firewall.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 25565
  ip_protocol = "udp"
  to_port     = 25565
}

resource "aws_vpc_security_group_ingress_rule" "minecraft_ssh" {
  security_group_id = aws_security_group.mc_firewall.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

//keep egress open
resource "aws_vpc_security_group_egress_rule" "minecraft_egress" {
  security_group_id = aws_security_group.mc_firewall.id

  cidr_ipv4 = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}

// let users log in
resource "aws_key_pair" "minecraft_server" {
  key_name   = "minecraft_server"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t3.small"

  tags = {
    Name = "MinecraftServer"
  }

  key_name = aws_key_pair.minecraft_server.key_name

  vpc_security_group_ids = [aws_security_group.mc_firewall.id]

  //connection configuration
  connection {
    user = "ubuntu"
    host = self.public_ip
    agent = true //may need to set this to private_key = file("~/.ssh/id_rsa")
  }

  //create the directory then copy to it
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/cookbooks",
      "mkdir -p ~/cookbooks/minecraft_server",
    ]
  }

  provisioner "file" {
    source = "cookbook/"
    destination = "/home/ubuntu/cookbooks/minecraft_server"
  }

  //bootstrap and run chef on the node
  provisioner "remote-exec" {
    inline = [
        "sudo mv /home/ubuntu/cookbooks /cookbooks",
        "sudo apt-get update",
        "sudo apt-get install -y curl",
        "curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -v 18",
        "sudo cinc-client -z -o 'minecraft_server'"
    ]
  }
}
