#일단.. 뺐음 인증서 및 R53 은 입력 받는 걸로...
#R53은 보통 상위 계정 혹은 특정 계정에서 몰빵 관리 하는 것 같긴 함.

# resource "aws_acm_certificate" "service" {
#   domain_name       = "${var.service_cert_domain}"
#   validation_method = "DNS"
#
#   tags = "${local.custom_tags}"
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
#
# data "aws_route53_zone" "zone" {
#   name         = "${var.route53_domain}"
#   private_zone = false
# }
#
# resource "aws_route53_record" "service_cert_validation" {
#   name    = "${aws_acm_certificate.service.domain_validation_options.0.resource_record_name}"
#   type    = "${aws_acm_certificate.service.domain_validation_options.0.resource_record_type}"
#   zone_id = "${data.aws_route53_zone.zone.id}"
#   records = ["${aws_acm_certificate.service.domain_validation_options.0.resource_record_value}"]
#   ttl     = 60
# }
#
# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = "${aws_acm_certificate.service.arn}"
#   validation_record_fqdns = ["${aws_route53_record.service_cert_validation.fqdn}"]
# }
