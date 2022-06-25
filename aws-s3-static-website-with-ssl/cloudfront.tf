#
# CloudFront の設定を行う
#

# see: https://www.terraform.io/language/values/locals
locals {

  # CloudFront の custorm_error_response を定義するためのエラーコードのリスト
  error_codes = [400, 403, 404, 405, 414, 416, 500, 501, 502, 503, 504]
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = var.domain
  aliases         = [var.domain]

  # S3 Static Website の機能を使って directory index を利用したいので
  # あえてカスタムオリジンとして紐づけする
  origin {
    domain_name = aws_s3_bucket_website_configuration.website_config.website_endpoint
    origin_id   = aws_s3_bucket_website_configuration.website_config.website_endpoint
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }
  #
  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    target_origin_id         = aws_s3_bucket_website_configuration.website_config.website_endpoint
    cache_policy_id          = aws_cloudfront_cache_policy.cache_policy_for_s3.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
  }
  #
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  #
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method  = "sni-only"
  }

  # カスタムエラーページは複数指定できる
  # 指定できるエラーコードはコンソールで確認する限りでは以下の通り
  # 400, 403, 404, 405, 414, 416
  # 500, 501, 502, 503, 504
  #
  # 同じような定義を繰り返す場合は dynamic blocks を使うとキレイに書けるらしい。
  # see: https://www.terraform.io/language/expressions/dynamic-blocks
  dynamic "custom_error_response" {
    for_each = { for c in local.error_codes : c => 0 }
    content {
      error_code            = custom_error_response.key
      error_caching_min_ttl = custom_error_response.value
    }
  }
  #custom_error_response {
  #  error_code            = 400
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 403
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 404
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 405
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 414
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 416
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 500
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 501
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 502
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 503
  #  error_caching_min_ttl = 0
  #}
  #custom_error_response {
  #  error_code            = 504
  #  error_caching_min_ttl = 0
  #}

  # S3 と ACM の設定を待ってから実行されるようにしておく。
  #depends_on = [
  #  aws_acm_certificate.main
  #]
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy
resource "aws_cloudfront_cache_policy" "cache_policy_for_s3" {
  name        = "TerraformTestCachePolicy"
  comment     = "For Terraform Test"
  default_ttl = 30
  min_ttl     = 0
  max_ttl     = 3600

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# オリジンリクエストポリシーにはデフォルトで登録されている CORS-Origin を使うので
# Data Source で読み込む
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy
data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}
