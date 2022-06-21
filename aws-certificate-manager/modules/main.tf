#
# ACM の証明書リクエストからバリデーション用の DNS の設定までを行うモジュール
#

# このブロックが無いと読み込み元ファイルからリージョン指定した provider を
# 指定したときに warning が出る
terraform {
  required_providers {
    aws = {}
  }
}

# 読み込み元から指定される、証明書に設定するドメインのリスト
# 先頭のドメインはホストゾーンとして設定してあるドメインな必要がある
variable "domains" {
  type = list(string)
}

# ホストゾーンは先に設定を済ませてある想定なので Data Source で定義
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone
data "aws_route53_zone" "main" {
  name = element(var.domains, 0)
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
resource "aws_acm_certificate" "main" {
  domain_name               = element(var.domains, 0)
  subject_alternative_names = var.domains
  validation_method         = "DNS"
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "acm_record" {
  #
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  # FIXME: allow_overwrite を true にしておかないと複数ドメインを指定した場合に
  #        重複する設定があった場合にエラーとなってしまう。
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
resource "aws_acm_certificate_validation" "acm_validate" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_record : record.fqdn]
}

# output を指定することによって読み込み元へ値を返すことができる
#
# see: https://www.terraform.io/language/values/outputs
output "arn" {
  value = aws_acm_certificate.main.arn
}
