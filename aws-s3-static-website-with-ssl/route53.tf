#
# Route53 の設定を行う
#

# ホストゾーンの設定は先にコンソールなどから済ませておく
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone
data "aws_route53_zone" "main" {
  name = var.hosted_zone
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = true
  }
  depends_on = [aws_cloudfront_distribution.main]
}

output "domain_url" {
  value = aws_route53_record.main.name
}
