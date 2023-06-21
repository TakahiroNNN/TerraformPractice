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
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
##############################################


provider "aws" {
  region = local.iam.region

  # 【入力要求時】
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY

  # 【const.tf 使用時】
  # access_key = local.iam.AWS_ACCESS_KEY_ID
  # secret_key = local.iam.AWS_SECRET_ACCESS_KEY
}

# VPC. VPCの起動構成の設定
resource "aws_vpc" "main" {
  cidr_block = local.vpc.cidr_block
  tags = {
    Name = local.vpc.name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = local.vpc.name
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  for_each          = local.vpc.subnet.public
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}${each.key}"
  cidr_block        = each.value

  tags = {
    Name = "env-public-${each.key}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "env-public"
  }
}

# Route Table Entry.パケットの送信先としてターゲットを指定する単一のルーティングルール
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# EC2 Instance
resource "aws_instance" "main" {
  ami           = local.ec2.ami
  instance_type = local.ec2.instance_type
  tags = {
    Name = local.ec2.name
  }
}

# $%& DEBUG
output "output" {
  value = local.project
}

/*

# */