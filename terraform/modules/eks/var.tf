variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "vpc_id" {
  description = "VPC ID with EKS and Nodes"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Subnet IDs with EKS"
  type        = list(string)
  default     = []
}

variable "node_ami_id" {
  description = "Node Instance ami id"
  type        = string
  default     = ""
}

variable "worker-node-type" {
  description = "Node Instance's Type"
  type        = string
  default     = "m4.large"
}

variable "node_subnet_ids" {
  description = "Subnet IDs with Node Instances"
  type        = list(string)
}

variable "node_asg_min_size" {
  description = "Worker Node Autoscaling Group Min Size"
  default     = 1
}

variable "node_asg_max_size" {
  description = "Worker Node Autoscaling Group Max Size"
  default     = 2
}

variable "custom_tags" {
  description = "Custom Tags"
  type        = map
  default     = {}
}

variable "kube_admin_instance_subnet_id" {
  description = "Kube Admin Instance Subnet ID"
  type        = string
}

variable "is_kube_admin_instance_public" {
  description = "Kube Admin Instance Public (true/false)"
  default     = true
}

variable "kube_admin_cidrs" {
  description = "Kube Admin CIDRs"
  type        = list(string)
  default     = []
}

variable "kube_admin_instance_instance_type" {
  description = "Kube Admin Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "kube_admin_instance_key" {
  description = "Kube Admin Instance PEM Key"
  type        = string
}
