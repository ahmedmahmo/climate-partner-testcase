resource "aws_eip" "nat_eip" {
  vpc = true
}

###############
# Multi Zone Public and Private Subnet
###############
resource "aws_subnet" "public_subnet_a" {
  vpc_id = data.aws_vpc.this.id
  cidr_block = "172.31.48.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-48"
    Project = local.application_name
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = data.aws_vpc.this.id
  cidr_block = "172.31.49.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-49"
    Project = local.application_name
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id = data.aws_vpc.this.id
  cidr_block = "172.31.50.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "Private-Subnet-50"
    Project = local.application_name
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id = data.aws_vpc.this.id
  cidr_block = "172.31.51.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = {
    Name = "Private-Subnet-51"
    Project = local.application_name
  }
}


###############
# Routing Tables
###############
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.this.id
  tags = {
    Name        = "private-route-table"
    Project     = local.application_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.this.id
  tags = {
    Name        = "public-route-table"
    Project     = local.application_name
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private.id
}

#################
# Security Groups
#################
resource "aws_security_group" "alb" {
name   = "${local.application_name}-sg-alb"
vpc_id = var.vpc_id

ingress {
  protocol         = "tcp"
  from_port        = 80
  to_port          = 80
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

ingress {
  protocol         = "tcp"
  from_port        = 443
  to_port          = 443
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

egress {
  protocol         = "-1"
  from_port        = 0
  to_port          = 0
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${local.application_name}-sg-task"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#####################
# LoadBalancer
#####################
resource "aws_lb" "main" {
  name               = "${local.application_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "main" {
  name        = "${local.application_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}