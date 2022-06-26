#
#
#

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  # 今回は AZ 名が事前に必要なのでリージョンは固定
  region = "ap-northeast-1"
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  # 10.0.0.0 ~ 10.0.255.255
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true

  # FIXME: これを true にしておかないと EC2 に public DNS が割り当てられないので、
  #        必要であればチェックしておく。
  enable_dns_hostnames = true

  tags = {
    Name = "Learning Terraform"
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1a"
  # 10.0.0.0 ~ 10.0.0.255
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "Learning Terraform A"
  }
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "ap-northeast-1c"
  # 10.0.1.0 ~ 10.0.1.255
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Learning Terraform C"
  }
}

# VPC を作成した段階で自動でメインルートテーブルが作成されるため、
# シンプルな構成で問題なければそれを利用するので問題ないと思う。
# また subnet を明示的に関連付けしなかった場合もメインルートテーブルが
# 使われるとのこと。
# see: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#main-route-table
#
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "a" {
  route_table_id = aws_vpc.main.main_route_table_id
  subnet_id      = aws_subnet.a.id
}

resource "aws_route_table_association" "c" {
  route_table_id = aws_vpc.main.main_route_table_id
  subnet_id      = aws_subnet.c.id
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Learning Terraform"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "main" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_vpc.main.main_route_table_id
  gateway_id             = aws_internet_gateway.main.id
}

