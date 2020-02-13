terraform {
  backend "s3" {
    bucket = "jisu-kops-test"
    key    = "terraform/moduleExample/ref_remote_state/vpc/terraform.state"
    region = "ap-northeast-2"
  }
}
