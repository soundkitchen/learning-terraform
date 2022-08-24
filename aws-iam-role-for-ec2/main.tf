#
#
#

locals {
  # 実践では variable にして外部から変更できるほうが望ましいが
  # ココではなるだけシンプルにするために locals で固定しつつ変更しやすいようにしておく。
  iam_role_name = "learning-terraform-ec2-worker"
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "main" {
  name               = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
resource "aws_iam_role_policy" "main" {
  name   = local.iam_role_name
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.role_policy.json
}

# 最終的にこれの名前が EC2 インスタンスと紐づけられる。
# コンソールから操作するとこのリソースは隠蔽されてるっぽくみえるが、
# これを設定しないと IAM Role を紐付けるプルダウンに出てこない。
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "main" {
  name = local.iam_role_name
  role = aws_iam_role.main.name
}

# どのサービス・アカウントからアクションが実行されるのを許可するかを定義する。
# 今回は EC2 に紐付ける想定なので ec2.amazonaws.com のみを定義している。
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# どのアクションを許可するかを定義する。
data "aws_iam_policy_document" "role_policy" {
  # EC2 の情報の READ のみ許可。
  statement {
    actions = [
      "ec2:Describe*",
    ]
    resources = ["*"]
  }

  # S3 のオブジェクトへの基本的な読み書きのみ許可。
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:GetObjectTagging",
      "s3:DeleteObjectTagging",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:PutObject",
    ]
    # 実案件投入時はココはプロジェクトに関連するバケット情報のみを指定したほうが良い
    resources = ["*"]
  }
}

output "iam_role_name" {
  value = aws_iam_instance_profile.main.name
}
