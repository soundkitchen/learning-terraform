# main.tf には汎用的なもののみ書くようにしておいて、
# サービス毎の設定はそれぞれファイルを分けて行うようにしてみる
# もうすでにだいぶ煩雑になってきている気がするので、
# 積極的にモジュール化を考えていったほうが良さそう。

# ドメインを登録するホストゾーン名
variable "hosted_zone" {
  type = string
}

# 作成されるドメイン・バケット名は terraform.tfvars で指定する
variable "domain" {
  type = string
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
}

# ACM 用にバージニアリージョンを指定した provider も用意する
# see: https://www.terraform.io/language/providers/configuration#alias-multiple-provider-configurations
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
