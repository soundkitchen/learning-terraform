# やっている事はほぼほぼ「 S3 で静的ウェブサイトを立てる」と同じなので、
# 細かいコメントは省くことにする
#

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "main" {
  bucket = var.domain
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.main.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
  #
  routing_rules = file("routing_rules.json")
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration
resource "aws_s3_bucket_cors_configuration" "cors_config" {
  bucket = aws_s3_bucket.main.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = [var.domain]
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
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "policy_assoc" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_access_policy.json
}
