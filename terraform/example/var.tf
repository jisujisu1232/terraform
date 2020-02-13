variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "availability_zones" {
  type    = list(string)
  default = ["a", "c"]
}

variable "project_name" {
  type    = string
  default = "jisu-tf"
}

variable "project_tags" {
  type = map
  default = {
    project = "jisu-tf"
    test    = "test2"
  }
}

variable "project_key" {
  default = "jisu-bastion"
}

variable "cluster-name" {
  default = "jisu-cluster"
}

variable "worker-node-type" {
  default = "m4.large"
}
