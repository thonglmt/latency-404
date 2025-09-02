module "example_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "A security group for service instances."
  vpc_id      = module.example_vpc.vpc_id

  # # TODO: REMOVE when not debugging
  # ingress_cidr_blocks = ["${local.your_public_ip}/32"] # Change this to your public IP address
  # ingress_rules       = ["ssh-tcp", "all-icmp"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-icmp"
      source_security_group_id = module.example_monitoring_security_group.security_group_id
    },
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.example_monitoring_security_group.security_group_id
    },
  ]

  tags = local.common_tags
}

module "example_monitoring_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "monitoring-${local.name}"
  description = "Security group for monitoring instances."
  vpc_id      = module.example_vpc.vpc_id

  ingress_cidr_blocks = ["${local.your_public_ip}/32"] # Change this to your public IP address
  ingress_rules       = ["ssh-tcp", "all-icmp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = "${local.your_public_ip}/32"
    },
  ]

  tags = local.common_tags
}
