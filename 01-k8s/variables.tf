variable "karpenter_version" {
  default = "v0.32.1"
}

variable "cluster_name" {
}

variable "karpenter_master_node_label_name" {
  default = "role"
}

variable "karpenter_master_node_label_value" {
  default = "karpenter"
}
