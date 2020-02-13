data "terraform_remote_state" "vpc" {
  backend   = "s3"
  workspace = "${terraform.workspace}"
  config = {
    bucket = "jisu-kops-test"
    key    = "terraform/moduleExample/ref_remote_state/vpc/terraform.state"
    region = "ap-northeast-2"
  }
}

variable "custom_tags" {
  default = {
    "TerraformManaged" = "true"
  }
}


module "eks" {
  source = "../../../modules/eks"

  region = "${data.terraform_remote_state.vpc.outputs.region}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  cluster_name = "jisu-tf-eks"

  cluster_subnet_ids = "${data.terraform_remote_state.vpc.outputs.public_subnets_ids}"

  node_ami_id = "ami-0c772c294acb393ce"

  worker-node-type = "m4.large"

  node_asg_min_size = 3

  node_asg_max_size = 5

  node_subnet_ids = "${data.terraform_remote_state.vpc.outputs.private_subnets_ids}"

  custom_tags = "${var.custom_tags}"

  kube_admin_instance_key = "jisu-bastion"

  kube_admin_instance_subnet_id = "${data.terraform_remote_state.vpc.outputs.public_subnets_ids[0]}"

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
