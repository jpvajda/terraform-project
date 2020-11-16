provider "aws" {
  region     = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "fcc-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "prod"
  }
}

# gateway

resource "aws_internet_gateway" "fcc-gateway" {
  vpc_id = aws_vpc.fcc-vpc.id

  tags = {
    Name = "prod"
  }
}

# route table

resource "aws_route_table" "fcc-route-table" {
  vpc_id = aws_vpc.fcc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fcc-gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.fcc-gateway.id
  }

  tags = {
    Name = "prod"
  }
}

#subnet

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.fcc-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

# route table association

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.fcc-route-table.id
}

# security policy for web traffic

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow webtraffic inbound traffic"
  vpc_id      = aws_vpc.fcc-vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
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
    Name = "allow_web_traffic"
  }
}

# network interface

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# elastic ip
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.fcc-gateway]
}


# create server and enable apache
resource "aws_instance" "web-server-instance" {
  ami               = "ami-0a91cd140a1fc148a"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  key_name          = "main-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo your first web server > /var/www/html/index.hmtl"
              EOF
  tags = {
    Name = "web-server"
  }
}
