// Create a private hosted zone for internal DNS resolution
// between our EC2 instances.
module "example_corp_private_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  zones = {
    "example-corp.internal" = {
      domain_name = "example-corp.internal"
      comment     = "example-corp.internal"
      description = "Private hosted zone for example-corp.internal"
      vpc = [
        {
          vpc_id = module.example_vpc.vpc_id,
        },
      ]
      tags = {
        Name = "example-corp.internal"
      }
    }
  }

  tags = local.common_tags
}

module "example_corp_private_zone_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_id = module.example_corp_private_zones.route53_zone_zone_id["example-corp.internal"]

  records = [
    {
      name = "example"
      type = "A"
      ttl  = 3600
      records = [
        module.example_ec2.private_ip
      ]
    },
    # {
    #   name = "monitoring"
    #   type = "A"
    #   ttl  = 3600
    #   records = [
    #     module.monitoring_example_ec2.private_ip
    #   ]
    # }
  ]

  depends_on = [module.example_corp_private_zones]
}
