
provider "aws" {
  region     =  var.region
  access_key = "AKIAYINACW7FBO4FB76K"
  secret_key = "AHh3SYcMeLDBwY1XOuCC9lSkRQ1IYx8Oqs4XKiS"
}


resource "aws_vpc" "terr_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "terr_vpc"
  }
}


resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.terr_vpc.id
  cidr_block = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "terr_vpc_public"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terr_vpc.id
}


resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.terr_vpc.id
  cidr_block = var.subnet_p_cidr

  tags = {
    Name = "terr_vpc_private"
  }
}


resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }
}


resource "aws_route_table" "rt_terr_vpc_public" {
  vpc_id = aws_vpc.terr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt_terr_vpc_public"
  }
}


resource "aws_route_table" "rt_terr_vpc_private" {
  vpc_id = aws_vpc.terr_vpc.id

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "rt_terr_vpc_private"
  }
}


resource "aws_route_table_association" "public_association" {
 subnet_id = aws_subnet.public.id
 route_table_id = aws_route_table.rt_terr_vpc_public.id
}


resource "aws_security_group" "allow_hw4" {
  name = "allow_hw4_traffic"
  description = "Allow inbound web traffic"
  vpc_id = aws_vpc.terr_vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    "Name" = "homework4-sg"
  }

}

resource "aws_network_interface" "mysql" {
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.allow_hw4.id]

}


resource "aws_instance" "mysql" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  network_interface {
    network_interface_id = aws_network_interface.mysql.id
    device_index         = 0
  }

  tags = {
    Name = "MySQL-HW4"
  }
}


module "mysql_Instance" {
  source = "./modules/mysql_Instance"
  ami_id           = var.ami_id
  subnet       = aws_subnet.public.id
  security_groups = [aws_security_group.allow_hw4.id] 
}


module "wordpress_instance" {
  source = "./modules/wordpress_instance"
  ami_id           = var.ami_id
  subnet       = aws_subnet.public.id
  security_groups = [aws_security_group.allow_hw4.id] 
  mysql_ip = module.mysql_Instance.mysql-pr-ip
}

