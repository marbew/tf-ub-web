terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "tf-sshkey"   # Create pub key to ec2
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

resource "aws_instance" "tf-ubuntu" {
  ami           = "ami-0fb391cce7a602d1f"
  instance_type = "t2.micro"
  key_name = aws_key_pair.kp.key_name
  security_groups = ["ssh_web"]

  user_data = <<-EOF
  #!/bin/bash
  sudo su - root
  apt update && apt install ansible -y
  git clone https://github.com/marbew/tf-ub-web.git && cd tf-ub-web
  mkdir /etc/ansible && touch ansible.cfg hosts
  sed -i '/^#inventory.*  /s/^#//' /etc/ansible/ansible.cfg
  echo "localhost ansible_connection=local" >> /etc/ansbile/hosts
  ansible-playbook apache.yml 
  EOF

  tags = {
    Name = "tf-ubuntu"
  }
}

resource "aws_security_group" "ssh_web" {
  name = "ssh_web"

  #Incoming traffic
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #replace it with your ip address ["35.158.102.17/32"]
  }

  #Outgoing traffic
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

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
