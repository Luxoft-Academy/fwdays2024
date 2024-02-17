module "vpc" {

  name = var.tag

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  azs     = slice(data.aws_availability_zones.zones.names, 0, 3)

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  cidr = var.vpc_cidr
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
    cidrsubnet(var.vpc_cidr, 8, 3)
  ]
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 4),
    cidrsubnet(var.vpc_cidr, 8, 5),
    cidrsubnet(var.vpc_cidr, 8, 6)
  ]
  private_subnet_tags = {
    "karpenter.sh/discovery"           = var.tag
    "kubernetes.io/role/internal-elb"  = "1"
    "kubernetes.io/cluster/${var.tag}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"           = "1"
    "kubernetes.io/cluster/${var.tag}" = "shared"
  }
}


resource "aws_security_group_rule" "allow_outbound" {
  description       = "Outpound access"
  protocol          = "tcp"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group_rule" "vpc_access" {
  description       = "Inside VPC"
  protocol          = "tcp"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = module.vpc.default_security_group_id
}
