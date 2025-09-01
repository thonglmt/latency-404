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
// Your SSH public key
// It can be generated with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/example
//
module "instance_key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.2"

  key_name   = "example-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhd52FXyGq0RvRMt9MJcEnVpJgZIBahZB5Eee26JCj8rdQoHQbV+S1CNc9GH7WD3nkIonx1eqIVCBzH4CqUEEh/jRFfl3tAE9ryLCeEaachLgrLyt+dAscs18YK3osgO/qj8s8znuY1M12SF1VTE6aSMhyRw9jq/HR719urcKnj6zen8YCelWI0yKo//KaDFmwr/NsTU9IhTsJrdTiuRgFeR5MtluTSo1TcA2uZUA/qdPapVWQOuov9qoxKsB7F/g6LXshwV+BEJlSOjxnPJDn8minvWJlCwsVpn+QRRYP9pXEIftiUZoVkdiBOpf9DeAPgAUupAsWxUXRn8zFZYWYpdgolE/FGHClDF8p05XI1Bz8cIuWM0WvLg5eyUS0lO3hQ3A1QgArtb8HAC1X5JvG5yD9qQzVPdPNn5uPDdv1Zog43iJMHR4utiHZJYm4YJ368Gir6rGozVG+weM2gexpl8dqCIpQkniPXfSuWyupSa5EaEQ5DukYo6GUtg6T0LDQmPUyO64Tid6o3rXf4rO3uShcj+uTR/0aNr8zZkOSKjrh2It3o2n7VXso+EOecxMrfQv6rbmj+U9B+xa0RS8UDMgblncM81goJshdKB61894lXnH8F9IxI6cP+PMy1xQsECnnhMVjbDhrrn+l+LnjtSQgPqIeEQ7Z75UkulQVpw=="
  tags       = local.common_tags
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
  # # TODO: remove when not debugging
  # subnet_id = element(module.example_vpc.public_subnets, 0)
  subnet_id = element(module.example_vpc.private_subnets, 0)
  vpc_security_group_ids = [
    module.example_security_group.security_group_id,
  ]

  # # TODO: remove when not debugging
  # associate_public_ip_address = true

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies           = {}

  hibernation = true

  user_data                   = file("../../../example-service/deploy/ec2/user-data.sh")
  user_data_replace_on_change = false

  root_block_device = {
    encrypted = true
    type      = "gp3"
    size      = 30
  }

  key_name = module.instance_key_pair.key_pair_name

  tags = local.common_tags
}

//
// Monitoring EC2 instance
//
// An EC2 instance to monitor the above EC2 instance
//
module "monitoring_example_ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "monitoring-${local.name}"

  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t3.micro"
  availability_zone = element(module.example_vpc.azs, 0)
  subnet_id         = element(module.example_vpc.public_subnets, 0)
  vpc_security_group_ids = [
    module.example_monitoring_security_group.security_group_id,
  ]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies           = {}

  associate_public_ip_address = true

  hibernation = true

  user_data                   = file("../../../monitoring-service/deploy/ec2/user-data.sh")
  user_data_replace_on_change = false

  key_name = module.instance_key_pair.key_pair_name

  root_block_device = {
    encrypted  = true
    type       = "gp3"
    throughput = 200
    size       = 30
  }

  tags = local.common_tags
}
