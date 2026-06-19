resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_vpc
}

resource "aws_subnet" "pub_sub-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_pub_sub-1
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pub_sub-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_pub_sub-2
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "prt_sub-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_prt_sub-1
  availability_zone = "eu-north-1a"
}

resource "aws_subnet" "prt_sub-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_prt_sub-2
  availability_zone = "eu-north-1b"
}

