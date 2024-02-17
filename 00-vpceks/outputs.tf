output "cluster_name" {
  value = module.eks.cluster_name
}

output "karpenter_master_node_label_name" {
  value = local.karpenter_master_node_label_name
}

output "karpenter_master_node_label_value" {
  value = local.karpenter_master_node_label_value
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
