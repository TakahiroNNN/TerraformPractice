#########################################################
# 
#【概要】
# 起動するEC2インスタンスの設定ファイル
# 
#【備考】
# コメントを確認すること
# 
#########################################################


locals {
  # プロジェクト名（動作には関係ない）
  project = "gsd_infra_automation"

  # I AM ユーザーに関して
  iam = {
    # ユーザーのリージョン（AWSコンソール画面右上）
    region = "ap-northeast-1"
    # アクセスキー
    AWS_ACCESS_KEY_ID = ""
    # シークレットアクセスキー
    AWS_SECRET_ACCESS_KEY = ""
  }

  # VPC(Virtual Private Cloud)に関して
  vpc = {
    # CIDR(Classless Inter-Domain Routing)
    cidr_block = "10.0.0.0/16"
    # タグ付けする名前
    name = "vpc_name"
    # サブネットについて
    subnet = {
      # パブリックサブネット
      public = {
        # 1
        a = "10.0.0.0/24"
        # 2
        # c = "10.0.4.0/24"
      }
    }
  }

  # EC2(Elastic Compute Cloud)に関して
  ec2 = {
    # 名前とタグ
    name = "gsd0000"
    # OSイメージ（Amazon マシンイメージ）のID
    ami = "ami-0f9816f78187c68fb"
    # インスタンスタイプ
    instance_type = "t2.micro"
  }
}