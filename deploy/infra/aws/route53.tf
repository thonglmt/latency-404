// Create a private hosted zone for internal DNS resolution
// between our EC2 instances.
module "example_corp_private_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  zones = {
    "${local.private_hosted_zone}" = {
      domain_name = local.private_hosted_zone
      comment     = local.private_hosted_zone
      description = "Private hosted zone for ${local.private_hosted_zone}"
      vpc = [
        {
          vpc_id = module.example_vpc.vpc_id,
        },
      ]
      tags = {
        Name = local.private_hosted_zone
      }
    }
  }

  tags = local.common_tags
}

module "example_corp_private_zone_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name    = local.private_hosted_zone
  private_zone = true

  records = [
    {
      name = "example"
      type = "A"
      ttl  = 3600
      records = [
        module.example_ec2.private_ip
      ]
    },
    {
      name = "monitoring"
      type = "A"
      ttl  = 3600
      records = [
        module.monitoring_example_ec2.private_ip
      ]
    }
  ]

  depends_on = [module.example_corp_private_zones]
}
