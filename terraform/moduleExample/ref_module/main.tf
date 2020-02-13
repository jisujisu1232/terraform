variable "custom_tags" {
  default = {
    "TerraformManaged" = "true"
  }
}

module "vpc" {
  source       = "../../modules/vpc"
  region       = "ap-northeast-2"
  product_name = "jisu"
  cidr_block   = "172.17.0.0/16"
  stage        = "dev"
  subnet_pub_info = [
    {
      "cidr" = "172.17.10.0/24",
      "az"   = "a",
      "task" = "common"
    },
    {
      "cidr" = "172.17.11.0/24",
      "az"   = "c",
      "task" = "common"
    },
  ]
  subnet_pri_info = [
    {
      "cidr" = "172.17.20.0/24",
      "az"   = "a",
      "task" = "app"
    },
    {
      "cidr" = "172.17.21.0/24",
      "az"   = "c",
      "task" = "app"
    },
  ]
  subnet_data_info = [
    {
      "cidr" = "172.17.30.0/24",
      "az"   = "a",
      "task" = "app"
    },
    {
      "cidr" = "172.17.31.0/24",
      "az"   = "c",
      "task" = "app"
    },
  ]
  data_subnet_route_nat = true
  nat_azs               = ["a", "c"]
  custom_tags           = "${var.custom_tags}"
}

module "eks" {
  source = "../../modules/eks"

  region = "ap-northeast-2"

  vpc_id = "${module.vpc.vpc_id}"

  cluster_name = "jisu-tf-eks"

  cluster_subnet_ids = "${module.vpc.public_subnet_ids}"

  node_ami_id = ""

  worker-node-type = "m4.large"

  node_asg_min_size = 3

  node_asg_max_size = 5

  node_subnet_ids = "${module.vpc.private_subnet_ids}"

  custom_tags = "${var.custom_tags}"

  kube_admin_instance_key = "jisu-bastion"

  kube_admin_instance_subnet_id = "${module.vpc.public_subnet_ids[0]}"

  kube_admin_cidrs = ["58.151.93.17/32"]
}

output "kubeconfig" {
  value = "${module.eks.kubeconfig}"
}

output "config_map_aws_auth" {
  value = "${module.eks.config_map_aws_auth}"
}

output "creator_kubectl_command" {
  value = "${module.eks.creator_kubectl_command}"
}
