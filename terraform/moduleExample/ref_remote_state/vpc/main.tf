variable "custom_tags" {
  default = {
    "TerraformManaged" = "true"
  }
}

module "vpc" {
  source       = "../../../modules/vpc"
  region       = "ap-northeast-2"
  product_name = "jisu"
  cidr_block   = "172.17.0.0/16"
  stage        = "${terraform.workspace}"
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
