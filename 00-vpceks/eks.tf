locals {
  karpenter_master_node_label_name  = "role"
  karpenter_master_node_label_value = "karpenter"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name    = var.tag
  cluster_version = "1.28"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_endpoint_public_access = true
  kms_key_administrators         = [data.aws_caller_identity.current.arn]

  manage_aws_auth_configmap = false
  create_aws_auth_configmap = false

  cluster_security_group_tags = {
    "karpenter.sh/discovery" = var.tag
  }
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.tag
  }

  eks_managed_node_groups = {

    karpenter-intertra-28 = {
      min_size       = 2
      max_size       = 2
      desired_size   = 2
      instance_types = ["t3.medium"]
      labels = {
        "${local.karpenter_master_node_label_name}" = local.karpenter_master_node_label_value
      }
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        Karperter                    = aws_iam_policy.karpenter.arn
        VolumeAccess                 = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        ALB                          = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
        EC2                          = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
      }
    }
  }
}

