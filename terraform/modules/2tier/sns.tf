resource "aws_sns_topic" "admin" {
  name = "${local.name_prefix}-ADMIN"
}
