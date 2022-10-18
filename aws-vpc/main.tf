# VPC を作成した段階で自動で Main Route Table が作成されるため、
# シンプルな構成であれば、それを利用するのが良いと思う。
# また Subnet を明示的に関連付けしなかった場合も Main Route Table が 使われるとのこと。
# see: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#main-route-table
#

locals {
  # 10.0.0.0 ~ 10.0.255.255
  cidr_block = "10.0.0.0/16"
  # 今回は AZ 名が事前に必要なのでリージョンは固定
  region = "ap-northeast-1"
  #
  availability_zones = [
    "ap-northeast-1a",
    "ap-northeast-1c",
  ]
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = local.region
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block = local.cidr_block

  enable_dns_support = true

  # FIXME: これを true にしておかないと EC2 に public DNS が割り当てられないので、
  #        必要であればチェックしておく。
  enable_dns_hostnames = true

  tags = {
    Name = "Learning Terraform"
  }
}

## see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "main" {
  # locals で指定したavailability_zone の数だけ subnet を作成する
  for_each = {
    for i, az in local.availability_zones : i => az
  }

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value
  # 10.0.0.0/16 => 10.0.0.0/24
  #             => 10.0.1.0/24
  #             => 10.0.2.0/24
  #             ...
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, each.key)
  # これを設定しない場合は Elastic IP を割り振らない限り
  # 自動で EC2 に Public IP が割り当てられない。
  map_public_ip_on_launch = true

  tags = {
    Name = "Learning Terraform ${upper(replace(each.value, local.region, ""))}"
  }
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_route_table_association" "main" {
  # 作成した Subnet の数だけ route_table との関連付けも作成する
  for_each = aws_subnet.main

  route_table_id = aws_vpc.main.main_route_table_id
  subnet_id      = each.value.id
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

