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
    bucket = "gsd-terraform-state" # 作成したS3バケット
    region = "ap-northeast-1"
    key = "terraform.tfstate"
    encrypt = true
  }
}


##############################################
# AWS アクセスキー情報
##############################################
# 入力要求
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}

# ローカルでの作業時
# variable "acs_key" {
#   default = ""
# }
# variable "sec_key" {
#   default = ""
# }
##############################################


# AWS Provider. I AM ユーザーのようなもの
provider "aws" {
  region = "ap-northeast-1" # アジアパシフィック（東京）
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY

  # ローカルでの作業時
  # access_key = var.acs_key
  # secret_key = var.sec_key
}



# VPC. VPCの起動構成の設定
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_name"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  # aws_vpc.main: 上で定義した VPC を参照
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "vpc_name"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.0.0/24"

  tags = {
    Name = "env-public-a"
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
  # AMI ID: Amazon Linux 2023 AMI（東京リージョン）
  ami           = "ami-0f9816f78187c68fb"
  instance_type = "t2.micro"
  tags = {
    Name = "gsd0000"
  }
}



# $%& DEBUG
output "output" {
  value = ""
}
