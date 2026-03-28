provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {                               # vpc creation 
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "prod-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name   = "prod-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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

resource "aws_key_pair" "prod" {
  key_name   = "prod-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "ec2" {                                  #EC2 Creation
  ami                         = "ami-id"
  instance_type               = "r5.2xlarge"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.prod.key_name 

  root_block_device {
    volume_size = 60
    volume_type = "gp3"
  }

  ebs_block_device {                                          #storage-ebs
    device_name           = "/dev/sdh"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "prod-ec2"
  }
}


resource "aws_s3_bucket" "bucket" {                          #s3-bucket 
  bucket = "prod-s3-bckt"

  tags = {
    Name = "bkt-prod"
  }
}
