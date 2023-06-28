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
    name = "gsd-vpc"
    # サブネットについて
    subnet = {
      # パブリックサブネット
      public = {
        # 1 (EC2 を紐づけるサブネット)
        a = "10.0.0.0/24"
        # 2
        c = "10.0.4.0/24"
        # 3
        d = "10.0.16.0/24"
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
    # キーペア（ログイン）
    key_name = "gsd-InfraAutomation"
  }

  # セキュリティグループに関して
  security_group = {
    # セキュリティグループ名
    name = "group000"
    # 説明
    description = "just test"
    # インバウンドルールに関して
    ingress = {
      # インバウンドルール000
      rule_000 = {
        # プロトコル
        protocol = "tcp"
        # ポート範囲（下限）
        from_port = 22
        # ポート範囲（上限）
        to_port = 22
        # ソース
        cidr_blocks = ["10.0.0.0/32"]
        # 説明 - オプション
        description = "ssh"
      }
      # インバウンドルール001
      rule_001 = {
        # プロトコル
        protocol = "tcp"
        # ポート範囲（下限）
        from_port = 80
        # ポート範囲（上限）
        to_port = 80
        # ソース
        cidr_blocks = ["10.0.0.0/32", "255.255.255.255/32"]
        # 説明 - オプション
        description = "http"
      }
    }
    # アウトバウンドルールに関して
    egress = {
      # アウトバウンドルール000
      rule_000 = {
        # プロトコル
        protocol = "-1"
        # ポート範囲（下限）
        from_port = 0
        # ポート範囲（上限）
        to_port = 0
        # ソース
        cidr_blocks = ["0.0.0.0/0"]
        # 説明 - オプション
        description = "just test"
      }
    }
  }
}
