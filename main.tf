terraform {
  cloud {
    organization = "infra-team"
    workspaces {
      name = "terraform_study"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "tfcloud_test" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.tfcloud_key.key_name

  vpc_security_group_ids = [ aws_security_group.test_sg.id, aws_security_group.web-sg.id ]
  subnet_id = data.aws_subnets.public.ids[0]
  associate_public_ip_address = true

  tags = {
    Name = "tfcloud-test"
  }
}

resource "aws_default_vpc" "default" {}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
  filter {
    name = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_security_group" "test_sg" {
  name = "test_sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web-sg" {
  name = "web-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "instance_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "instance_key" {
  content = tls_private_key.instance_key.private_key_pem
  filename = "tfcloud_key.pem"
}

resource "aws_key_pair" "tfcloud_key" {
  key_name   = "tfcloud_key"
  public_key = tls_private_key.instance_key.public_key_openssh
}