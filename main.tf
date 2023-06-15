# Terraformの設定情報 
terraform {
    # AWSのプロバイダ設定
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 4.0"
        }
    }

    # バックエンド設定。Terraformの状態ファイルの保存先
    backend "local" {}
}


##############################################
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
##############################################


# AWS Provider. I AM ユーザーのようなもの
provider "aws" {
  region     = "ap-northeast-1" # アジアパシフィック（東京）
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# VPC. VPCの起動構成の設定
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}






##############################################
##############################################
###########　ここまで　#################
##############################################
##############################################





# VPC

resource "aws_vpc" "main" {
  cidr_block = local.vpc.cidr_block
  tags = {
    Name = local.vpc.name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = local.vpc.name
  }
}

resource "aws_subnet" "public" {
  for_each          = local.vpc.subnet.public
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}${each.key}"
  cidr_block        = each.value
  tags = {
    Name = "${local.environment}-public-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.environment}-public"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# EC2

resource "aws_instance" "main" {
  for_each                = local.ec2
  ami                     = each.value.ami
  instance_type           = each.value.instance_type
  disable_api_termination = false
  key_name                = lookup(each.value, "key_name", null)
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3000
    throughput            = 125
    tags = {
      Name = "${each.key}-root"
    }
    volume_size = each.value.volumes.root.size
    volume_type = "gp3"
  }
  subnet_id = aws_subnet.public[each.value.subnet.zone].id
  tags = {
    Name        = each.key
    Environment = local.environment
  }
  vpc_security_group_ids = [for key in each.value.security_groups : aws_security_group.main[key].id]
}

resource "aws_eip" "main" {
  for_each = local.ec2
  instance = aws_instance.main[each.key].id
  tags = {
    Name = "${local.environment}-ec2instance-${each.key}"
  }
}

# Security Group

resource "aws_security_group" "main" {
  for_each = local.security_group
  name     = "${local.environment}-${each.key}"
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${local.environment}-${each.key}"
  }
}

# egress は制限しない前提
resource "aws_security_group_rule" "egress" {
  for_each          = local.security_group
  security_group_id = aws_security_group.main[each.key].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# IPアドレスは全削除を回避するためIP毎にリソース作成
locals {
  cidr_blocks = flatten([
    for _k, _v in local.security_group : [
      for _k2, _v2 in lookup(_v, "cidr_block_rule", {}) : {
        for ip in _v2.cidr_blocks : "${_k}-${_k2}-${ip}" => merge(_v2, {
          ip     = ip
          sg_key = _k
        })
      }
    ]
  ])
  security_groups = flatten([
    for _k, _v in local.security_group : [
      for _k2, _v2 in lookup(_v, "security_group_rule", {}) : {
        for group in _v2.groups : "${_k}-${_k2}-${group}" => merge(_v2, {
          group  = group
          sg_key = _k
        })
      }
  ]])
}

# IP アドレスを指定するルール
resource "aws_security_group_rule" "cidr_blocks" {
  for_each          = merge(local.cidr_blocks...)
  security_group_id = aws_security_group.main[each.value.sg_key].id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  type              = "ingress"
  cidr_blocks       = [each.value.ip]
}

# セキュリティグループを指定するルール
resource "aws_security_group_rule" "security_groups" {
  for_each                 = merge(local.security_groups...)
  security_group_id        = aws_security_group.main[each.value.sg_key].id
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  type                     = "ingress"
  source_security_group_id = aws_security_group.main[each.value.group].id
}

# LB

resource "aws_s3_bucket" "lb-log" {
  bucket = "${local.project}-${local.environment}-lb-log"
}

resource "aws_s3_bucket_policy" "lb-log" {
  bucket = aws_s3_bucket.lb-log.id
  policy = templatefile("${path.module}/templates/bucket-policy-lb-log.json", {
    bucket_name = aws_s3_bucket.lb-log.id
  })
}

/*
resource "aws_lb" "main" {
  name               = "${local.environment}-${local.alb.name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [for group in local.alb.security_groups : local.security_group_ids[group]]
  subnets            = [for zone in local.alb.public_subnet_zones : local.subnet_ids.public[zone]]

  enable_deletion_protection = true

  access_logs {
    bucket  = local.log_bucket_name
    prefix  = local.alb.name
    enabled = true
  }
}

# https アクセスする前提
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.alb.certificate_arn

  # 適切でないアクセスは 503 を返す
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.value.target_group_key].arn
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${local.environment}-lb-${local.alb.name}"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check {
    enabled             = true
    matcher             = "200"
    path                = local.alb.healthcheck_path
    port                = "traffic-port"
    healthy_threshold   = 5
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "main" {
  for_each = local.ec2
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.main[each.key].id
  port             = 80
}
*/