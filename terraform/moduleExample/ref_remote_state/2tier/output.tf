output "codecommit_url_http" {
  value=module.jisu-service.codecommit_url_http
}

output "codecommit_url_ssh" {
  value=module.jisu-service.codecommit_url_ssh
}

output "alb_endpoint" {
  value=module.jisu-service.alb_endpoint
}

output "service_bucket_name" {
  value=module.jisu-service.service_bucket_name
}

output "codecommit_master_key" {
  value=module.jisu-service.codecommit_master_key
}

output "codecommit_user_name" {
  value=module.jisu-service.codecommit_user_name
}
