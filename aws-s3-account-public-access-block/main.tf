#
#
#

variable "block_public_acls" {
  type    = bool
  default = true
}

variable "ignore_public_acls" {
  type    = bool
  default = false
}

variable "block_public_policy" {
  type    = bool
  default = true
}

variable "restrict_public_buckets" {
  type    = bool
  default = false
}

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_account_public_access_block
resource "aws_s3_account_public_access_block" "main" {
  block_public_acls       = var.block_public_acls
  ignore_public_acls      = var.ignore_public_acls
  block_public_policy     = var.block_public_policy
  restrict_public_buckets = var.restrict_public_buckets
}
