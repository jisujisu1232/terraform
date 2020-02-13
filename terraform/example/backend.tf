terraform {
  backend "s3" {
    bucket = "jisu-kops-test"
    key    = "terraform/jisu-cluster/terraform.state"
    region = "ap-northeast-2"
  }
}
