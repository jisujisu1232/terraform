data "aws_subnet" "asg" {
  id = "${var.asg_subnets[0]}"
}

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

locals {
  name_prefix = "${data.aws_vpc.vpc.tags["prefix"]}${var.service_name}"
  asg_name_prefix = "${data.aws_subnet.asg.tags["prefix"]}${var.service_name}"
}

resource "aws_launch_configuration" "this" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.service.name}"
  image_id                    = "${var.asg_ami_id}"
  instance_type               = "${var.asg_instance_type}"
  name_prefix                 = "${local.asg_name_prefix}-lc-"
  security_groups             = ["${aws_security_group.service_asg.id}"]
  key_name                    = "${var.asg_key_name}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  desired_capacity     = "${var.asg_min_size}"
  launch_configuration = "${aws_launch_configuration.this.id}"
  max_size             = "${var.asg_max_size}"
  min_size             = "${var.asg_min_size}"
  name                 = "${local.asg_name_prefix}-asg"
  vpc_zone_identifier  = "${var.asg_subnets}"

  tag {
    key                 = "Name"
    value               = "${local.asg_name_prefix}"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = "${aws_autoscaling_group.this.id}"
  alb_target_group_arn   = "${aws_lb_target_group.service_alb.arn}"
}
