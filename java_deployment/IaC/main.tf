  provider "aws" {
  region = "ap-south-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags       = { Name = "java-app-vpc" }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-south-1a"
  tags              = { Name = "private-subnet" }
}

# Internet Gateway (needed for ALB)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "java-app-igw" }
}

# Route Table for public subnet (for ALB)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "public-rt" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ALB subnet (2-public subnet) - for ALB
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "ap-south-1a"
  tags              = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "ap-south-1b"
  tags              = { Name = "public-subnet-2" }
}

resource "aws_route_table_association" "public_association_1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_association_2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Security Groups

# ALB SG - allow inbound 443 from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow inbound HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
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

# NGINX SG - allow inbound 80 from ALB SG
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow inbound HTTP from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tomcat SG - allow inbound 8080 from NGINX SG
resource "aws_security_group" "tomcat_sg" {
  name        = "tomcat-sg"
  description = "Allow inbound 8080 from NGINX"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB setup
resource "aws_lb" "app_alb" {
  name                       = "java-app-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [aws_subnet.public1.id, aws_subnet.public2.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

# EC2 Launch Configuration for NGINX (user_data installs nginx and configures proxy)

resource "aws_instance" "nginx" {
  ami                         = "ami-0f918f7e67a3323f0"
  instance_type               = "t3.micro"
  key_name                    = "bastion"
  subnet_id                   = [aws_subnet.public1.id]
  security_groups             = [aws_security_group.nginx_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              cat > /etc/nginx/conf.d/proxy.conf << EOL
              upstream tomcat_backend {
                  server ${aws_instance.tomcat1.private_ip}:8080;
                  server ${aws_instance.tomcat2.private_ip}:8080;
              }
              server {
                  listen 80;
                  location / {
                      proxy_pass http://tomcat_backend;
                      proxy_set_header Host \$host;
                      proxy_set_header X-Real-IP \$remote_addr;
                      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                  }
              }
              EOL
              systemctl restart nginx
            EOF

  tags = {
    Name = "NGINX-Proxy"
  }
}

# 3 Tomcat EC2 instances
resource "aws_instance" "tomcat1" {
  ami                         = "ami-0f918f7e67a3323f0"
  instance_type               = "t3.micro"
  key_name                    = "bastion"
  subnet_id                   = aws_subnet.private.id
  security_groups             = [aws_security_group.tomcat_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "Tomcat-Server-1"
  }
}

resource "aws_instance" "tomcat2" {
  ami                         = "ami-0f918f7e67a3323f0"
  instance_type               = "t3.micro"
  key_name                    = "bastion"
  subnet_id                   = aws_subnet.private.id
  security_groups             = [aws_security_group.tomcat_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "Tomcat-Server-2"
  }
}

# Register NGINX EC2 instance with Target Group (via IP targets)
resource "aws_lb_target_group_attachment" "nginx_attachment" {
  target_group_arn = aws_lb_target_group.nginx_tg.arn
  target_id        = aws_instance.nginx.id
  port             = 80
}

# Route 53 records (replace hosted_zone_id with your zone id and domain name)

variable "domain_name" {
  default = "try-devops.xyz"
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["192.0.3.50"]
}

variable "tags" {
  description = "Tags to apply to the hosted zone"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "DevOps-Lab"
  }
}
resource "aws_route53_zone" "public" {
  name    = var.domain_name
  comment = "Public hosted zone for ${var.domain_name}"
  tags    = var.tags
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.domain_name}"
  ]

  tags = {
    Name = "Java App ACM Cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = aws_route53_zone.public.id
  records = [each.value.value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
}

