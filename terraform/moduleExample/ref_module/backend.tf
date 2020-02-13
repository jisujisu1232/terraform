terraform {
  backend "s3" {
    bucket = "jisu-kops-test"
    key    = "terraform/moduleExample/terraform.state"
    region = "ap-northeast-2"
  }
}
