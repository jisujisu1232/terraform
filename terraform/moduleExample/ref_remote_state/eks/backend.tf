terraform {
  backend "s3" {
    bucket = "jisu-kops-test"
    key    = "terraform/moduleExample/ref_remote_state/eks/terraform.state"
    region = "ap-northeast-2"
  }
}
