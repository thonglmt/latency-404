provider "aws" {
  region = local.region

  # assume_role {
  #   role_arn     = "arn:aws:iam::12345678:role/ROLE_NAME"
  #   session_name = "SESSION_NAME"
  #   external_id  = "EXTERNAL_ID"
  # }
}
