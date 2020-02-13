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

module "jisu-service" {
  source                       = "../../../modules/2tier"
  region                       = "${data.terraform_remote_state.vpc.outputs.region}"
  service_name                 = "jisuweb"
  route53_domain               = "kdiego.cf."
  service_cert_domain          = "*.kdiego.cf"
  acm_certificate_arn          = "arn:aws:acm:ap-northeast-2:270881836940:certificate/4bfbc5ed-b8c0-4934-9a88-2eb9aeff3ae2"
  vpc_id                       = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  elb_subnets                  = ["${data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]}", "${data.terraform_remote_state.vpc.outputs.public_subnet_ids[1]}"]
  service_end_user_cidrs       = ["0.0.0.0/0"]
  is_elb_internal              = false
  service_bucket_name          = "jisu-service-test"
  service_log_s3_key_prefix    = "LOG"
  log_expiration_days          = 90
  asg_ami_id                   = "ami-06e830129032eacc5"
  asg_key_name                 = "jisu-bastion"
  asg_subnets                  = ["${data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]}", "${data.terraform_remote_state.vpc.outputs.public_subnet_ids[1]}"]
  instance_http_port           = 8080
  service_deregistration_delay = 60
  custom_tags                  = "${var.custom_tags}"
}
