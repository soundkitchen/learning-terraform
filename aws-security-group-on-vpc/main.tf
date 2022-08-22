# インバウンド・アウトバウンドルールを設定するのに
# ingress, egress を使ってインラインで行う方法と aws_security_group_rule を使う方法の
# 2 通りあるが、前者の場合複数のインバウンドルールが設定出来ないらしく、
# より柔軟性をもたせるため aws_security_group_role を使う事にする。
#

variable "own_ipv4" {
  type = string
}

locals {
  # VPC を東京リージョン固定で作っているので、
  # セキュリティグループも合わせるために固定にしておく。
  region = "ap-northeast-1"

  # 任意の場所からアクセスを許可するポート。
  # 今回は HTTP, HTTPS のふたつ。
  allow_public_access_ports = {
    "http"  = 80,
    "https" = 443,
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = local.region
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "main" {
  tags = {
    Name = "Learning Terraform"
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "main" {
  vpc_id      = data.aws_vpc.main.id
  name        = "learning-terraform"
  description = "use for learning terraform only."

  lifecycle {
    # セキュリティグループは作成後に名前を変更できないので、変更した場合は
    # 削除・新規作成が行われる。その時に既に他のリソースに割り当てられていた場合、
    # 削除に失敗してしまう。
    # それを回避するために create_before_destroy を設定しておくことで
    # 削除・新規作成の順番を
    # 1. 新規作成
    # 2. 新規のものにリソースを関連付け
    # 3. 既存のものを削除
    # に変更する事ができる。
    create_before_destroy = true
  }
}

# SSH のインバウンドを設定する。
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ssh_ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.own_ipv4]
  description       = "SSH from home"
}

# allow_public_access_ports に登録されているインバウンドを設定する。
resource "aws_security_group_rule" "public_ingress" {
  for_each = local.allow_public_access_ports

  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# 全てのアウトバウンドを設定する
resource "aws_security_group_rule" "all_egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
