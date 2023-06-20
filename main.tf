# Terraformの設定情報 
terraform {
  # AWSのプロバイダ設定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  # バックエンド設定。tfstateファイルを AWS S3 へ保存。
  backend "s3" {
    # 作成した S3バケット
    bucket = "gsd-terraform-state"
    # 作成した S3バケットのリージョン
    region = "ap-northeast-1"
    # tfstateファイルの保存先（パス）
    key = "terraform.tfstate"
    # tfstateファイルをサーバー側で暗号化するか
    encrypt = true
  }
}


##############################################
# AWS アクセスキー情報（入力要求）
##############################################
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
##############################################


# AWS Provider. I AM ユーザーのようなもの
provider "aws" {
  region = local.region

  # 入力要求時
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY

  # const.tf 使用時
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
  # aws_vpc.main: 上で定義した VPC を参照
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