#
#
#

# 作成されるバケット名は terraform.tfvars で指定する
variable "bucket_name" {
  type = string
}

terraform {}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "bucket_access_policy_assoc" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_access_policy.json
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  # routing_rule はひとつ以上書けて複数の設定が可能。
  # 4.19 現在 replace_key_with や replace_key_prefix_with に空文字列を指定すると
  # terraform 側で省略された形で反映されてしまうため、
  # 「 404 ならトップへリダイレクト」という設定が上手く反映されない。
  # なので、必要であれば routing_rules で直接 JSON 形式で指定すると良い。
  #
  # see: https://github.com/hashicorp/terraform-provider-aws/issues/24048
  #routing_rule {
  #  condition {
  #    http_error_code_returned_equals = "404"
  #  }
  #  redirect {
  #    replace_key_with = ""
  #    # デフォルトが 301 でブラウザにキャッシュされてしまうので
  #    # 特別な要件がなければ 307 or 302 を指定するようにしてる。
  #    http_redirect_code = "307"
  #  }
  #}
  #
  # コンソールでも使える json 形式で指定したい場合は
  # routing_rules と file 関数を組み合わせれば良い。
  routing_rules = file("routing_rules.json")
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration
resource "aws_s3_bucket_cors_configuration" "cors_config" {
  bucket = aws_s3_bucket.bucket.bucket

  # cors_rule はひとつ以上書けて複数設定が可能
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = [
      var.bucket_name,
      aws_s3_bucket_website_configuration.website_config.website_endpoint
    ]
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "bucket_access_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

# see: https://www.terraform.io/language/values/outputs
output "bucket_url" {
  # 4.19 現在 aws_s3_bucket の website_domain, website_endpoint は
  # バケット作成時には取得できないので aws_s3_bucket_website_configuration から取得する。
  # おそらく aws_s3_bucket_website_configuration が独立実装された影響っぽいので
  # そのうち aws_s3_bucket の attribute は deprecated になる？
  value = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}/"
}
