terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
    region = "ap-south-1"
}

data "aws_ami" "image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_iam_role" "ssm-role" {
  name = "SSM-Automation-N"
}

resource "aws_iam_instance_profile" "ssmp" {
  role = data.aws_iam_role.ssm-role.id
}

resource "tls_private_key" "terraform_generated_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "aws_keys_pairs_3"
  public_key = tls_private_key.terraform_generated_private_key.public_key_openssh
}

resource "local_file" "cloud_pem" {
  filename = "/home/ec2-user/.ssh/aws_keys_pairs_3.pem"
  content  = tls_private_key.terraform_generated_private_key.private_key_pem
}

resource "aws_instance" "terraform_pubinstance" {
  ami           = data.aws_ami.image.id
  key_name      = "aws_keys_pairs_3"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ssmp.id
  tags = {
    "Name" = "Terraform-public-server"
  }
}
