terraform {
  backend "s3" {
    bucket = "jisu-kops-test"
    key    = "terraform/moduleExample/ref_remote_state/3tier/terraform.state"
    region = "ap-northeast-2"
  }
}
