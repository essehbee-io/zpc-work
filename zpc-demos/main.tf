terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}




#**************************AWS Part Begins*************************************

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}



resource "aws_instance" "example" {
  ami                    = "ami-00cc4623561d117c6"
  instance_type          = "t4g.micro"
  vpc_security_group_ids = [aws_security_group.allow_inbound.id]
}

resource "aws_instance" "example1" {
  ami                    = "ami-00cc4623561d117c6"
  instance_type          = "t4g.micro"
  vpc_security_group_ids = [aws_security_group.allow_inbound.id]

}

resource "aws_security_group_rule" "example" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_inbound.id
}

resource "aws_security_group_rule" "example2" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_inbound.id
}

resource "aws_security_group_rule" "example3" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_inbound.id
}

resource "aws_security_group_rule" "example3" {
  type              = "ingress"
  from_port         = 21
  to_port           = 21
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_inbound.id
}

resource "aws_security_group" "allow_inbound" {
  name        = "allow_inbound"
  description = "Allow inbound traffic"


  tags = {
    Name = "allow_inbound"
  }
}
resource "aws_security_group_rule" "FireFlow_221" {
  type              = "ingress"
  from_port         = "8566"
  to_port           = "8566"
  protocol          = "tcp"
  cidr_blocks       = ["8.8.8.8/32"]
  security_group_id = aws_security_group.allow_inbound.id
}
resource "aws_security_group_rule" "FireFlow_227" {
  type              = "ingress"
  from_port         = "7897"
  to_port           = "7897"
  protocol          = "tcp"
  cidr_blocks       = ["7.5.6.3/32"]
  security_group_id = aws_security_group.allow_inbound.id
}
resource "aws_security_group_rule" "FireFlow_230" {
  type              = "ingress"
  from_port         = "2412"
  to_port           = "2412"
  protocol          = "tcp"
  cidr_blocks       = ["7.5.6.3/32"]
  security_group_id = aws_security_group.allow_inbound.id
}
resource "aws_security_group_rule" "FireFlow_238" {
  type              = "ingress"
  from_port         = "100"
  to_port           = "100"
  protocol          = "tcp"
  cidr_blocks       = ["5.5.5.5/32"]
  security_group_id = aws_security_group.allow_inbound.id
}
resource "aws_security_group_rule" "FireFlow_2400" {
  type              = "ingress"
  from_port         = "44"
  to_port           = "44"
  protocol          = "tcp"
  cidr_blocks       = ["8.8.8.8/32"]
  security_group_id = aws_security_group.allow_inbound.id
}
resource "aws_security_group_rule" "FireFlow_240" {
  type              = "ingress"
  from_port         = "40"
  to_port           = "40"
  protocol          = "tcp"
  cidr_blocks       = ["8.8.8.8/32"]
  security_group_id = aws_security_group.allow_inbound.id
}