#
#
#

# ホストゾーンは先に登録してある想定なので Data Resource で情報を取得する
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

  # S3 とドメインの紐づけには CNAME を使う方法と Route53 で A のエイリアスを
  # 使う方法と 2 通りあるが、 Route53 を使っていてなおかつ特別な事情がなければ
  # A を使うのが良いと思う。
  alias {
    # FIXME: aws_s3_bucket の website_domain だと作成時に null になってしまう時があるため、
    #        回避策として aws_s3_bucket_website_configuration の website_domain から
    #        値をとってくる。
    name                   = aws_s3_bucket_website_configuration.website_config.website_domain
    zone_id                = aws_s3_bucket.main.hosted_zone_id
    evaluate_target_health = true
  }
}

# see: https://www.terraform.io/language/values/outputs
output "website_url" {
  value = "http://${aws_route53_record.main.name}/"
}
