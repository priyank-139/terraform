resource "aws_vpc" "t4-vpc" {
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "hasi_vault-vpc"
  }
}


resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.t4-vpc.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true


  tags = {
    Name = "vault_public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.t4-vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-west-2b"


  tags = {
    Name = "vault_private-subnet"
  }
}


resource "aws_internet_gateway" "t4-igw" {
  vpc_id = aws_vpc.t4-vpc.id


  tags = {
    Name = "vault-igw"
  }
}

resource "aws_route_table" "t4-routeTable1" {
  vpc_id = aws_vpc.t4-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.t4-igw.id
  }

  tags = {
    Name = "vault-routeTable1"
  }
}

resource "aws_route_table_association" "associate" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.t4-routeTable1.id
}

resource "aws_eip" "ip" {
  vpc = true
  tags = {
    Name = "hashi-elasticIP"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.public-subnet.id


  tags = {
    Name = "hashi_nat-gateway"
  }
}

resource "aws_route_table" "t4routeTable-2" {
  vpc_id = aws_vpc.t4-vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "hashi_routeTable-2"
  }
}

resource "aws_route_table_association" "associate2" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.t4routeTable-2.id
}



provider "tls" {}
resource "tls_private_key" "t" {
  algorithm = "RSA"
}
resource "aws_key_pair" "test" {
  key_name   = "hashi-vault"
  public_key = tls_private_key.t.public_key_openssh
}
provider "local" {}
resource "local_file" "key" {
  content  = tls_private_key.t.private_key_pem
  filename = "hashi-vault.pem"

}

resource "aws_security_group" "wp-sg" {
  name        = "wp"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.t4-vpc.id


  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "ssh"
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


  tags = {
    Name = "hashi-sg"
  }
}

resource "aws_instance" "wp-os" {
  ami                    = "ami-017fecd1353bcc96e"
  instance_type          = "t2.micro"
  key_name               = "hashi-vault"
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.wp-sg.id]
  tags = {
    Name = "hashi-vault-pub"
  }
}

resource "aws_security_group" "hashi-vault" {
  name        = "basic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.t4-vpc.id


  ingress {
    description = "hashicorp_vault"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "hashi-vault-sg"
  }
}

resource "aws_instance" "hashi_corp_vault" {
  ami                    = "ami-017fecd1353bcc96e"
  instance_type          = "t2.micro"
  key_name               = "hashi-vault"
  subnet_id              = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.hashi-vault.id]
  tags = {
    Name = "hashi_vault-pvt"
  }
}

