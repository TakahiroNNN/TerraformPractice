locals {
  project = "gsd_infra_automation"
  region  = "ap-northeast-1"
  iam = {
    AWS_ACCESS_KEY_ID     = ""
    AWS_SECRET_ACCESS_KEY = ""
  }
  vpc = {
    cidr_block = "10.0.0.0/16"
    name       = "vpc_name"
    subnet = {
      public = {
        a = "10.0.0.0/24"
      }
    }
  }
  ec2 = {
    name = "gsd0000"
    # AMI ID: Amazon Linux 2023 AMI（東京リージョン）
    ami           = "ami-0f9816f78187c68fb"
    instance_type = "t2.micro"
  }
}