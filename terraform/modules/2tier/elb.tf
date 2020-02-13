resource "aws_lb" "service_alb" {
  internal           = "${var.is_elb_internal}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.service_alb.id}"]
  subnets            = "${var.elb_subnets}"

  enable_deletion_protection = false

  access_logs {
    bucket  = "${var.service_bucket_name}"
    prefix  = "${var.service_log_s3_key_prefix}${substr(var.service_log_s3_key_prefix, length(var.service_log_s3_key_prefix) - 1, 1) == "/" ? "" : "/"}${var.service_name}-ALB"
    enabled = true
  }

  tags = "${local.custom_tags}"
}

resource "aws_lb_target_group" "service_alb" {
  name                 = "${local.name_prefix}-tg"
  port                 = "${var.instance_http_port}"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.service_deregistration_delay}"
  lifecycle {
    create_before_destroy = true
  }
  stickiness {
    cookie_duration = "${var.service_sticky_time < 1 ? 1 : var.service_sticky_time}"
    enabled         = "${var.service_sticky_time > 1 ? true : false}"
    type            = "lb_cookie"
  }
  health_check {
    path                = "${var.health_check_path}"
    port                = "${var.instance_http_port}"
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "service_https" {
  load_balancer_arn = "${aws_lb.service_alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "${aws_acm_certificate.service.arn}"
  certificate_arn   = "${var.acm_certificate_arn}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.service_alb.arn}"
  }
}

resource "aws_lb_listener" "service_http" {
  load_balancer_arn = "${aws_lb.service_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
