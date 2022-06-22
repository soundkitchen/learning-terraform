# main.tf には汎用的なもののみ書くようにしておいて、
# Route 53 と S3 の設定はそれぞれ route53.tf, s3.tf で行うようにしてみる
# 色々ググってみると variables.tf に variable の宣言のみを
# 書くのが良いといった記事も見かけるので、今後の試行錯誤によっては
# 取り入れてみるのもアリかも知れない。

# ドメインを登録するホストゾーン名
variable "hosted_zone" {
  type = string
}

# 作成されるドメイン・バケット名
variable "domain" {
  type = string
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
}

