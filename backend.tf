#########################################################
# 
#【概要】
# バックエンドの設定ファイル（tfstateファイルの保存先を指定）
# 
#【備考】
# 下記はテンプレートとして記載済み。コメントを外して切り替えること。
# ・ローカルに保存する場合
# ・AWS S# に保存する場合
# 
#########################################################


terraform {
  # ローカルに保存する場合
  # backend "local" {
  # }

  # AWS S3 に保存する場合
  backend "s3" {
    # 作成したバケット名
    bucket = "gsd-terraform-state"
    # 作成したバケットのAWSリージョン
    region = "ap-northeast-1"
    # tfstateファイルの保存先（パス）
    key = "terraform.tfstate"
    # tfstateファイルをサーバー側で暗号化するか
    encrypt = true
  }
}