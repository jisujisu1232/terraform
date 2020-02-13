output "codecommit_url_http" {
  value=aws_codecommit_repository.service.clone_url_http
}

output "codecommit_url_ssh" {
  value=aws_codecommit_repository.service.clone_url_ssh
}

output "alb_endpoint" {
  value=aws_lb.service_alb.dns_name
}

output "service_bucket_name" {
  value=var.service_bucket_name
}

output "codecommit_master_key" {
  value= [
    aws_iam_access_key.codecommit_master.id,
    aws_iam_access_key.codecommit_master.secret
  ]
}

output "codecommit_user_name" {
  value = aws_iam_user.codecommit_normal_user.name
}
