resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "test"
    project = "sprints"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.0.0.0/24"

}

resource "aws_internet_gateway" "sp-gateway" {
  vpc_id = aws_vpc.dev.id
}

resource "aws_route_table" "sp-route"{
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sp-gateway.id
  }
}

resource "aws_route_table_association" "sp-rtp" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.sp-route.id
}

resource "aws_security_group" "sp-sg" {
  name        = "ec2 terraform security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

data "aws_ami" "sp-ubuntu" {
    most_recent = true
 
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
 
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
 
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
 
    owners = ["099720109477"]
}

resource "aws_instance" "sp-ec2" {
  ami           = data.aws_ami.sp-ubuntu.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id     = aws_subnet.subnet-1.id
  security_groups  = [aws_security_group.sp-sg.id]
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
  EOF
 
}
