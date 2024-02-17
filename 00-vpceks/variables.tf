variable "vpc_cidr" {}

variable "tag" {}

variable "karpenter_master_node_label_name" {
  default = "role"
} 
variable "karpenter_master_node_label_value" {
  default = "karpenter"
}

variable "parent_domain" {}