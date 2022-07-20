#
#
#

#
variable "username" {
  type = string
}

#
variable "buckets" {
  type = list(string)
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "s3_operator" {
  statement {
    # FIXME: s3:ListAllMyBuckets を指定してしまうと全てのバケット名が見えてしまうため
    #        使う側でバケット名を指定して操作してもらうようにする。
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = flatten([
      for a in [
        for b in var.buckets : b == "*" ? "*" : "arn:aws:s3:::${b}"
      ] : a == "*" ? ["*"] : [a, "${a}/*"]
    ])
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "s3_operator" {
  name        = "TFS3Operator"
  description = "Learning Terraform"
  policy      = data.aws_iam_policy_document.s3_operator.json
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user
resource "aws_iam_user" "main" {
  name = var.username
}

# aws_iam_policy_attachment と aws_iam_user_policy_attachment の違いは
# AWS リソース全体に対して排他処理かどうかとのこと。
# おそらくだけども、必要に迫られなければ aws_iam_user_policy_attachment を使うほうが
# 意図しない変更やトラブルに合わずに済みそう。
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment
resource "aws_iam_user_policy_attachment" "main" {
  user       = aws_iam_user.main.name
  policy_arn = aws_iam_policy.s3_operator.arn
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key
resource "aws_iam_access_key" "main" {
  user = aws_iam_user.main.name
}

# aws_iam_access_key の secret を output で書き出そうとすると
# セキュリティまわりのエラーが出てしまうため、ファイルに書き出すことで
# 消失するリスクも回避できるようにしておく。
# terraform import して読み込んだ場合は key / secret の情報は取得できないため
# ファイルに保存することはできない。
#
# see: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "credentials" {
  filename             = "${path.module}/creadentials.txt"
  file_permission      = "0644"
  directory_permission = "0755"
  content              = <<EOF
AWS_ACCESS_KEY_ID=${aws_iam_access_key.main.id}
AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.main.secret}
EOF
}
