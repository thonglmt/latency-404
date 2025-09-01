data "aws_availability_zones" "available" {}

locals {
  name   = "example"
  region = "ap-southeast-1"

  vpc_cidr = "192.168.123.0/24"
  azs      = slice(data.aws_availability_zones.available.names, 0, 1)

  common_tags = {
    Team        = "example-team"
    Owner       = "example-owner"
    Purpose     = "example-purpose"
    Terraform   = "true"
    Environment = "sandbox"
  }
}
