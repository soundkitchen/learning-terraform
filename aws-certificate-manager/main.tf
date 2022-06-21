#
# デフォルトのリージョンとバージニアリージョンに ACM の設定をする
# module についての説明は以下より
#
# see: https://www.terraform.io/language/modules/syntax

#
variable "domains" {
  type = list(string)
}

# 何も指定しなければコチラの provider が使われる
provider "aws" {}

# provider に aws.virginia を指定することでコチラが使われるようになる
# see: https://www.terraform.io/language/providers/configuration#alias-multiple-provider-configurations
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# AWS_DEFAULT_REGION で指定したリージョンに ACM の設定をする
module "default_acm" {
  source = "./modules"
  # モジュール側の variable で指定してある名前で値を渡す
  domains = var.domains
}

# CloudFront などで必要になるバージニアリージョンに ACM の設定をする
module "virginia_acm" {
  source  = "./modules"
  domains = var.domains
  # モジュールで使用する provider を明示的に指定する
  providers = {
    aws = aws.virginia
  }
}

# それぞれのリージョンに設定した ACM の arn を表示する
# モジュール側の output で指定してある名前で取得できる
#
# see: https://www.terraform.io/language/values/outputs
output "default_arn" {
  value = module.default_acm.arn
}
output "virginia_arn" {
  value = module.virginia_acm.arn
}
