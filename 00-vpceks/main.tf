terraform {
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "zones" {}

data "aws_region" "current" {}

provider "aws" {
  region = "us-east-1"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

