data "aws_ami" "eks-worker-node-ami" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.jisu-cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"]
}

data "aws_region" "current" {}

locals {
  jisu-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.jisu-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.jisu-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "jisu-cluster-node-lc" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.jisu-cluster-node-profile.name}"
  image_id                    = "${data.aws_ami.eks-worker-node-ami.id}"
  instance_type               = "${var.worker-node-type}"
  name_prefix                 = "${var.cluster-name}-node-lc-"
  security_groups             = ["${aws_security_group.jisu-cluster-node-sg.id}"]
  user_data_base64            = "${base64encode(local.jisu-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "jisu-cluster-node-asg" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.jisu-cluster-node-lc.id}"
  max_size             = 2
  min_size             = 1
  name                 = "${var.cluster-name}-node-asg"
  vpc_zone_identifier  = "${aws_subnet.jisu-tf-pri.*.id}"

  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}
