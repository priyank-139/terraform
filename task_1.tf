provider "aws" {
  region = "us-west-2"
}


# terraform {
#  backend "s3" {
#    bucket = "tool-terra-s3"
#    key    = "output"
#    region = "us-west-2"
#  }
# }





resource "aws_vpc" "dominators" {
  cidr_block       = var.cidr_vpc
  instance_tenancy = "default"

  tags = {
    Name = "task-1-terreform"
  }
}



resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.dominators.id
  cidr_block = var.cidr_public_subnet

  tags = {
    Name = "public_subnet-terra-1"
  }
}



resource "aws_subnet" "dominators" {
  vpc_id     = aws_vpc.dominators.id
  cidr_block = var.cidr_private_subnet

  tags = {
    Name = "private_subnet-terra-1"
  }
}





resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dominators.id

  tags = {
    Name = "dominators-igw"
  }
}




resource "aws_route_table" "route" {
  vpc_id = aws_vpc.dominators.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id



  }

}


resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.route.id
}






resource "aws_instance" "ec2demo" {
  ami           = "ami-017fecd1353bcc96e"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.main.id

  tags = {
    Name = "terra-ec2"
  }

}

