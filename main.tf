terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
#    tls = {
#      version = "=4.0.5"
#    }
  }
  cloud {
    organization = "example-org-3e44a7"
    workspaces {
      name = "terraform_practice_aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = "<access_key>"
  secret_key = "<secret_key>"
  default_tags {
    cost_center: "12345"
  }
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/22"
  instance_tenancy = "default"
  tags = {
    "Name": "vpc1"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name": "Subnet1"
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "myec2" {
  ami = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"
  tags = {
    Name = "myec2-practice"
  }
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet1.id
  key_name = var.keypairname
  vpc_security_group_ids = [aws_security_group.myec2-SG.id]
  user_data = "${file("scripts/install_apache.sh")}"
  depends_on = [aws_key_pair.myec2-keypair]
}

resource "aws_key_pair" "myec2-keypair" {
  key_name = var.keypairname
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVonMOI9aCSdrkYyzLC7/HssizMdJHfqcoHEhEO3IBZCSkVjTtmMeBhTbMs2bjAZVRnPLGw2xZrGL0vwoSnVDgPAz9mH9rsBEeVO6CDVfh2rIXNB0nJ9gJvLDdmlXQ0uZ2jWtbdTgAz6YSGTzVn8mAdY+9Xi0jyKK/2QxmXm0wBVXcJ3yx9as7JFS4Uh87pK8QXNOIFb/gBYwaP50zfIU8DlpLnup7nKcH69Jg6RNN9l4LqFvY042G+n7f7ef1jv4Sm7JD7frQ5qEeWp2lAjxkt9OKr47QQ5nlqUlFymiouuP9ENiV84NMix9jF4LJ0RszIYfbznsy5eQ5xa6yiDwZZ29TXHC0e5y8MfWUoLHttpIp+GhlAxgXv4Tei+KjfTGSuMgS2vOb8/DD2azbGd4+JS7Kl1aQf2xJu6KMgmNW7ULxgBQR22tdQmmkr1RYX1HUtmdTtUR69ZOOQx9Yd5H0SbdjyRrtNli9JTb9wMuvCh+PxfXaPUiYQPRMb17Qnw0= satish@Satishs-MacBook-Pro.local"
#  public_key = tls_private_key.myec2_KP_priv_Key.public_key_openssh

#  provisioner "local-exec" {
#    command = "echo '${tls_private_key.myec2_KP_priv_Key.private_key_pem}' > ./my-keypair.pem"
#  }
}

resource "aws_security_group" "myec2-SG" {
  description = "security group for myec2 instance"
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name: "myec2-SG"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    protocol  = "TCP"
    to_port   = 22
    description = "Allow SSH from anywhere"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    protocol  = "TCP"
    to_port   = 80
    description = "Allow HTTP from anywhere"
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description = "Allow all outbound traffic"
  }
}

#resource "tls_private_key" "myec2_KP_priv_Key" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}

resource "aws_internet_gateway" "vpc1-igw-1" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1-igw-1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.vpc1-igw-1.id
  }
}

resource "aws_route_table_association" "subnet1_my_route_table_assoc" {
  route_table_id = aws_route_table.my-route-table.id
  subnet_id = aws_subnet.subnet1.id
}