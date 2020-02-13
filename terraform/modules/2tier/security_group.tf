#WEB LB SG
data "aws_subnet" "service_alb" {
  id = "${var.elb_subnets[0]}"
}

resource "aws_security_group" "service_alb" {
  name        = "${data.aws_subnet.service_alb.tags["prefix"]}alb-sg"
  description = "${data.aws_subnet.service_alb.tags["prefix"]}alb-sg"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    merge(
      map(
        "Name", "${data.aws_subnet.service_alb.tags["prefix"]}alb-sg"
      ),
      local.custom_tags
    )
  }"
}

resource "aws_security_group_rule" "service_alb_http" {
  count             = "${length(var.service_end_user_cidrs) > 0 ? 1 : 0}"
  cidr_blocks       = "${var.service_end_user_cidrs}"
  description       = "${var.service_name} HTTP"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.service_alb.id}"
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "service_alb_https" {
  count             = "${length(var.service_end_user_cidrs) > 0 ? 1 : 0}"
  cidr_blocks       = "${var.service_end_user_cidrs}"
  description       = "${var.service_name} HTTPS"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.service_alb.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group" "service_asg" {
  name        = "${data.aws_subnet.service_alb.tags["prefix"]}asg-sg"
  description = "${data.aws_subnet.service_alb.tags["prefix"]}asg-sg"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    merge(
      map(
        "Name", "${data.aws_subnet.service_alb.tags["prefix"]}asg-sg"
      ),
      local.custom_tags
    )
  }"
}

resource "aws_security_group_rule" "service_asg_ssh_end_user" {
  count             = "${length(var.service_end_user_cidrs) > 0 ? 1 : 0}"
  cidr_blocks       = "${var.service_end_user_cidrs}"
  description       = "${var.service_name} ASG Instances HTTP port"
  from_port         = "${var.instance_ssh_port}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.service_asg.id}"
  to_port           = "${var.instance_ssh_port}"
  type              = "ingress"
}

resource "aws_security_group_rule" "service_asg_http_alb" {
  source_security_group_id = "${aws_security_group.service_alb.id}"
  description              = "${var.service_name} ASG Instances HTTP port"
  from_port                = "${var.instance_http_port}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.service_asg.id}"
  to_port                  = "${var.instance_http_port}"
  type                     = "ingress"
}
# resource "aws_security_group_rule" "cluster-ingress-node-https" {
#   description              = "Allow pods to communicate with the cluster API Server"
#   from_port                = 443
#   protocol                 = "tcp"
#   security_group_id        = "${aws_security_group.cluster.id}"
#   source_security_group_id = "${aws_security_group.node.id}"
#   to_port                  = 443
#   type                     = "ingress"
# }
#
#
# #worker node
# resource "aws_security_group" "node" {
#   name        = "${var.cluster_name}-node-sg"
#   description = "Security group for all nodes in the cluster"
#   vpc_id      = "${var.vpc_id}"
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = "${
#     merge(
#       map(
#         "Name", "${var.cluster_name}-node-sg",
#         "kubernetes.io/cluster/${var.cluster_name}", "owned",
#       ),
#       var.custom_tags
#     )
#   }"
# }
#
# resource "aws_security_group_rule" "node-ingress-self" {
#   description              = "Allow node to communicate with each other"
#   from_port                = 0
#   protocol                 = "-1"
#   security_group_id        = "${aws_security_group.node.id}"
#   source_security_group_id = "${aws_security_group.node.id}"
#   to_port                  = 65535
#   type                     = "ingress"
# }
