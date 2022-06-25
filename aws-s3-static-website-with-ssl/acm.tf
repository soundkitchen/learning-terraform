#
#
#

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"
  # CloudFront 用の証明書なのでバージニアリージョンで作成する
  provider = aws.virginia
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "acm" {
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
  validation_record_fqdns = [for record in aws_route53_record.acm : record.fqdn]
  # 証明書をバージニアで発行したので同じリージョンで追跡する必要がある
  provider = aws.virginia
}
