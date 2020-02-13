data "aws_ami" "eks-worker-node-ami" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"]
}

data "aws_region" "current" {}

locals {
  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

resource "aws_launch_configuration" "node" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.cluster-node-profile.name}"
  image_id                    = "${var.node_ami_id == "" ? data.aws_ami.eks-worker-node-ami.id : var.node_ami_id}"
  instance_type               = "${var.worker-node-type}"
  name_prefix                 = "${var.cluster_name}-node-lc-"
  security_groups             = ["${aws_security_group.node.id}"]
  user_data_base64            = "${base64encode(local.node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node" {
  desired_capacity     = "${var.node_asg_min_size}"
  launch_configuration = "${aws_launch_configuration.node.id}"
  max_size             = "${var.node_asg_max_size}"
  min_size             = "${var.node_asg_min_size}"
  name                 = "${var.cluster_name}-node-asg"
  vpc_zone_identifier  = "${var.node_subnet_ids}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}
