terraform {
  backend "s3" {
    bucket = "jisu-terraform-test"
    key    = "terraform/moduleExample/ref_remote_state/eks/terraform.state"
    region = "ap-northeast-2"
  }
}
