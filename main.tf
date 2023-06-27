#########################################################
# 
#【概要】
# TerraformによるEC2起動の自動化のソースコード
# 
#【備考】
# アクセスキー/シークレットアクセスキー を const.tf に
# ハードコーディングする場合は、別途コメントアウト部分を切り替える必要がある
# （【】部分に記載）
# 
#########################################################


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


##############################################
# 【AWS アクセスキー情報（入力要求）】
# ※ const.tf 使用時はコメントアウトすること
##############################################
# variable "AWS_ACCESS_KEY_ID" {}
# variable "AWS_SECRET_ACCESS_KEY" {}
##############################################


provider "aws" {
  region = local.iam.region

  # 【入力要求時】
  # access_key = var.AWS_ACCESS_KEY_ID
  # secret_key = var.AWS_SECRET_ACCESS_KEY

  # 【const.tf 使用時】
  access_key = local.iam.AWS_ACCESS_KEY_ID
  secret_key = local.iam.AWS_SECRET_ACCESS_KEY
}

# VPC. VPCの起動構成の設定
resource "aws_vpc" "main" {
  cidr_block = local.vpc.cidr_block
  tags = {
    Name = local.vpc.name
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  for_each = local.vpc.subnet.public
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.iam.region}${each.key}"
  cidr_block        = each.value
  tags = {
    Name = "gsd-public-${each.key}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "gsd-route-table"
  }
}

# Subnet と RouteTable の関連付け
resource "aws_route_table_association" "rtb_asc" {
  for_each = local.vpc.subnet.public
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = local.vpc.name
  }
}

# Route Table Entry. (RouteTable と InternetGateway の関連付け)
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
}

# Security Group
resource "aws_security_group" "sec_group" {
  name        = local.security_group.name
  description = local.security_group.description
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${local.security_group.name}"
  }
}

# Security Group Rule (ingress)
resource "aws_security_group_rule" "ingress" {
  for_each          = local.security_group.ingress
  security_group_id = aws_security_group.sec_group.id
  type              = "ingress"
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# Security Group Rule (egress)
resource "aws_security_group_rule" "egress" {
  for_each          = local.security_group.egress
  security_group_id = aws_security_group.sec_group.id
  type              = "egress"
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = local.ec2.ami
  instance_type          = local.ec2.instance_type
  key_name               = local.ec2.key_name
  vpc_security_group_ids = [aws_security_group.sec_group.id]
  subnet_id = aws_subnet.public[keys(local.vpc.subnet.public)[0]].id
  associate_public_ip_address = true
  tags = {
    Name = local.ec2.name
  }
}

# Elastic IP
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  tags = {
    Name = local.ec2.name
  }
}


# $%& DEBUG
output "output" {
  value = [local.project, aws_eip.main.public_ip]
  # value = aws_subnet.public["a"]
  # value = aws_route_table_association.rtb_asc
}

/*

# */