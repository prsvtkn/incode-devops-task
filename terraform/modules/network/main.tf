provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-main" })
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnets_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-private-subnet-${count.index + 1}" })
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnets_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnets_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-public-subnet-${count.index + 1}" })
}

### IGW and NGW
resource "aws_eip" "eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-igw" })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-nat-gw" })
}

### Route tables
resource "aws_main_route_table_association" "main_private" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-public-rt" })
}

resource "aws_route_table_association" "public_subnet_association" {
  for_each       = { for name, subnet in aws_subnet.public_subnet : name => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-private-rt" })

}

resource "aws_route_table_association" "private_subnet_association" {
  for_each       = { for name, subnet in aws_subnet.private_subnet : name => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-alb-sg"

  ingress {
    description = "Allow 433 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-alb-sg" })
}

resource "aws_security_group" "ecs_fargate_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-ecs-fargate-sg"

  ingress {
    description     = "Allow 5001 from ALB"
    from_port       = 5001
    to_port         = 5001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all to ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups  = [aws_security_group.alb_sg.id, aws_security_group.aurora_sg.id]
  }

  egress {
    description = "Allow all from Aurora"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups  = [aws_security_group.aurora_sg.id]
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-ecs-fargate-sg" })
}

resource "aws_security_group" "aurora_sg" {
  name        = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-sg"
  description = "Security group for Aurora PostgreSQL cluster"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Allow 5432 from ECS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups  = [aws_security_group.ecs_fargate_sg.id]
  }

  egress {
    description = "Allow all to ECS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups  = [aws_security_group.ecs_fargate_sg.id]
  }
}

### ALB
resource "aws_lb" "alb" {
  name                       = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  enable_deletion_protection = false # for demo

  subnets                          = [for subnet in aws_subnet.public_subnet : subnet.id]
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id # let's imagine we already have a bucket
    prefix  = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-alb"
    enabled = true
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-alb" })
}

resource "aws_lb_target_group" "small_demo_app_tg" {
  name                   = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-small-demo-app-tg"
  port                   = 5001
  protocol               = "TLS"
  vpc_id                 = aws_vpc.main.id
  target_type            = "ip"
  connection_termination = true
  deregistration_delay   = 10

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    port                = "traffic-port"
    protocol            = "TCP"
  }
}

resource "aws_lb_listener" "listener_5001" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 5001
  protocol          = "TLS"
  certificate_arn   = var.listener_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  alpn_policy       = "HTTP2Preferred"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.small_demo_app_tg.arn
  }
}

### VPC endpoints for private subnets
resource "aws_vpc_endpoint" "s3gw" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-endpoint-s3gw" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnet : subnet.id]
  security_group_ids  = [aws_security_group.ecs_fargate_sg.id]
  private_dns_enabled = true
  tags                = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-endpoint-s3" })
}

resource "aws_vpc_endpoint" "s3sm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnet : subnet.id]
  security_group_ids  = [aws_security_group.ecs_fargate_sg.id]
  private_dns_enabled = true
  tags                = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-endpoint-sm" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  # route_table_ids = [aws_route_table.main.id]
  subnet_ids          = [for subnet in aws_subnet.private_subnet : subnet.id]
  security_group_ids  = [aws_security_group.ecs_fargate_sg.id]
  private_dns_enabled = true
  tags                = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-endpoint-ecr-dkr" })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnet : subnet.id]
  security_group_ids  = [aws_security_group.ecs_fargate_sg.id]
  private_dns_enabled = true
  tags                = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-endpoint-ecr-api" })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnet : subnet.id]
  security_group_ids  = [aws_security_group.ecs_fargate_sg.id]
  private_dns_enabled = true
  tags                = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-endpoint-logs" })
}
