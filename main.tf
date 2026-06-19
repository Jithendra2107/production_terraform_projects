resource "aws_key_pair" "resource" {
  key_name   = "deployer-key"
  public_key = file("/home/jithendra/.ssh/id_ed25519.pub")
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "pub_sub_1_assoc" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.pub_sub-1.id
}

resource "aws_route_table_association" "pub_sub_2_assoc" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.pub_sub-2.id
}

resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-1a.id
  }
}

resource "aws_route_table_association" "example-q" {
  subnet_id      = aws_subnet.prt_sub-1.id
  route_table_id = aws_route_table.private-1.id
}

resource "aws_route_table" "private-2" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-1b.id
  }
}

resource "aws_route_table_association" "example-o" {
  subnet_id      = aws_subnet.prt_sub-2.id
  route_table_id = aws_route_table.private-2.id
}

resource "aws_eip" "eip-1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat-1a" {
  allocation_id = aws_eip.eip-1.id
  subnet_id     = aws_subnet.pub_sub-1.id

  depends_on = [aws_internet_gateway.ig]
}

resource "aws_eip" "eip-2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat-1b" {
  allocation_id = aws_eip.eip-2.id
  subnet_id     = aws_subnet.pub_sub-2.id

  depends_on = [aws_internet_gateway.ig]
}

resource "aws_security_group" "sg_lb" {
   vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    to_port   = 80
  }

  ingress {
    protocol  = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 443
    to_port   = 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion_gp" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["49.37.153.241/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion_host" {
  ami = "ami-0aba19e56f3eaec05"
  instance_type = "t3.micro"
  subnet_id                   = aws_subnet.pub_sub-1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.bastion_gp.id ]
  key_name = aws_key_pair.resource.key_name
  tags = {
  Name = "bastion-host"
}
}


resource "aws_security_group" "sg_ec2" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_lb.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_gp.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = [ aws_subnet.pub_sub-1.id, aws_subnet.pub_sub-2.id]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  target_type = "instance"

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-template"
  image_id = "ami-0aba19e56f3eaec05"
  instance_type = "t3.micro"

  key_name = aws_key_pair.resource.key_name
  
  vpc_security_group_ids = [
    aws_security_group.sg_ec2.id
  ]

  user_data = base64encode(file("${path.module}/user-data.sh"))
}

resource "aws_autoscaling_group" "name" {
  name                      = "terraform-auto-scaling"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.prt_sub-1.id, aws_subnet.prt_sub-2.id]
  target_group_arns = [aws_lb_target_group.tg.arn]
  launch_template {
    id = aws_launch_template.web.id
  }
}

output "alb_dns_name" {
  value = aws_lb.lb.dns_name
} 
