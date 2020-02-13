variable "custom_tags" {
  description = "Custom Tags"
  type        = map
  default     = {}
}

variable "service_name" {
  description = "Service Name"
  type        = string
}

variable "service_cert_domain" {
  description = "Service ACM certificate Domain"
  type        = string
}

variable "route53_domain" {
  description = "Route53 Domain"
  type        = string
}

variable "acm_certificate_arn" {
  description = "Service ACM Certification ARN"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "service_bucket_name" {
  description = "S3 Bucket Name to store ELB Access Log"
  type        = string
}

variable "service_log_s3_key_prefix" {
  description = "Service Logs S3 Key prefix"
  type        = string
  default     = "LOG"
}

variable "log_expiration_days" {
  description = "s3 Log File's expiration days"
  default     = 90
}

variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "elb_subnets" {
  description = "Web ELB Subnets"
  type        = list
}

variable "service_end_user_cidrs" {
  description = "Service End User CIDRs"
}

variable "is_elb_internal" {
  description = "Web ELB internal/internet-facing(true/false)"
  default     = false
}

variable "asg_ami_id" {
  description = "Autoscaling Group Launch configuration AMI ID"
  default     = ""
}

variable "asg_key_name" {
  description = "ASG Instances Key name"
  default     = ""
}

variable "instance_ssh_port" {
  description = "Instance ssh Port"
  default     = 22
}

variable "instance_http_port" {
  description = "Instance Http Port"
  default     = 80
}

variable "health_check_path" {
  description = "ALB Health Check Path"
  default     = "/"
}

variable "service_deregistration_delay" {
  description = "Service Deregistration Delay"
  default     = 300
}

variable "service_sticky_time" {
  description = "Service Sticky Time"
  default     = 1
}

variable "asg_instance_type" {
  description = "Autoscaling Group instance Type"
  default     = "t2.micro"
}

variable "asg_subnets" {
  description = "Autoscaling Group Subnet IDs"
  type        = list
}

variable "asg_min_size" {
  description = "Autoscaling Group Min Size"
  default     = 2
}

variable "asg_max_size" {
  description = "Autoscaling Group Max Size"
  default     = 4
}

variable "deploy_s3_key_prefix" {
  description = "CodeDeploy App S3 Key prefix"
  type        = string
  default     = "build"
}

locals {
  custom_tags = "${
    merge(
      map(
        "Service", "${var.service_name}",
        "workspace", "${terraform.workspace}"
      ),
      var.custom_tags
    )
  }"
}
