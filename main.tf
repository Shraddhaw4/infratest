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
  filename = "./cloudtls.pem"
  content  = tls_private_key.terraform_generated_private_key.private_key_pem
}

resource "aws_instance" "terraform_pubinstance" {
  ami           = data.aws_ami.image.id
  key_name      = "Jenkins-Server"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ssmp.id
  tags = {
    "Name" = "Terraform-public-server"
  }
  provisioner "file" {
    source      = "./cloudtls.pem"
    destination = "/home/ec2-user/.ssh/cloudtls.pem"
    on_failure  = fail

  }

  provisioner "remote-exec" {
    inline = [
      "cd ~/.ssh",
      "sudo chmod 600 *.pem",
      "echo -e 'Host *\n\tStrictHostKeyChecking no\n\tUser ec2-user\nIdentityFile /home/ec2-user/.ssh/cloudtls.pem' > config",
      "sudo chmod 600 config"
    ]
    on_failure = fail
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("Jenkins-Server.pem")
    host        = self.public_ip
  }
}


resource "aws_security_group" "Terraform_private_SG" {
  name        = "Terraform-Project-Private_SG"
  description = "Terraform-Project-Private_SG"
  depends_on = [
    aws_instance.terraform_pubinstance
  ]

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.terraform_pubinstance.private_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# #private instances
resource "aws_instance" "terraform_prvinstance" {
  depends_on = [
    aws_instance.terraform_pubinstance
  ]
  ami                    = data.aws_ami.image.id
  key_name               = "aws_keys_pairs_3"
  vpc_security_group_ids = [aws_security_group.Terraform_private_SG.id]
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ssmp.id
  tags = {
    "Name" = "Terraform-private-server"
  }
}
