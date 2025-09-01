//
// AMI
//
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

//
// Example EC2 instance
//
// A simple EC2 instance to host a web application
module "example_ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = local.name

  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t3.micro"
  availability_zone = element(module.example_vpc.azs, 0)
  subnet_id         = element(module.example_vpc.private_subnets, 0)
  vpc_security_group_ids = [
    module.example_security_group.security_group_id,
  ]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies           = {}

  hibernation = true

  # user_data_base64            = "base64encode(local.user_data)"
  # user_data_replace_on_change = false

  root_block_device = {
    encrypted = true
    type      = "gp3"
    size      = 30
  }

  tags = local.common_tags
}

# //
# // Monitoring EC2 instance
# //
# // An EC2 instance to monitor the above EC2 instance
# module "monitoring_example_ec2" {
#   source = "terraform-aws-modules/ec2-instance/aws"

#   name = "monitoring-${local.name}"

#   ami               = data.aws_ami.ubuntu.id
#   instance_type     = "t3.micro"
#   availability_zone = element(module.example_vpc.azs, 0)
#   subnet_id         = element(module.example_vpc.public_subnets, 0)
#   vpc_security_group_ids = [
#     module.example_monitoring_security_group.security_group_id,
#   ]

#   create_iam_instance_profile = true
#   iam_role_description        = "IAM role for EC2 instance"
#   iam_role_policies           = {}

#   hibernation = true

#   # user_data_base64            = "base64encode(local.user_data)"
#   # user_data_replace_on_change = false

#   root_block_device = {
#     encrypted  = true
#     type       = "gp3"
#     throughput = 200
#     size       = 30
#   }

#   tags = local.common_tags
# }
