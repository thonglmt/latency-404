data "aws_availability_zones" "available" {}

locals {
  name   = "example"
  region = "ap-southeast-1"

  your_public_ip = "116.109.24.61"
  vpc_cidr       = "192.168.123.0/24"
  azs            = slice(data.aws_availability_zones.available.names, 0, 1)

  private_hosted_zone = "example-corp.internal"

  common_tags = {
    Team        = "example-team"
    Owner       = "example-owner"
    Purpose     = "example-purpose"
    Terraform   = "true"
    Environment = "sandbox"
  }
}
