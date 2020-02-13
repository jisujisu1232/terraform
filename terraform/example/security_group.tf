#eks cluster
resource "aws_security_group" "jisu-cluster-sg" {
  name        = "${var.cluster-name}-sg"
  description = "Cluster commuication with worker nodes"
  vpc_id      = "${aws_vpc.jisu_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster-name}-sg"
  }
}

resource "aws_security_group_rule" "jisu-cluster-ingress-workstation-https" {
  cidr_blocks       = ["58.151.93.17/32"]
  description       = "Allow workstation to commuicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.jisu-cluster-sg.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "jisu-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.jisu-cluster-sg.id}"
  source_security_group_id = "${aws_security_group.jisu-cluster-node-sg.id}"
  to_port                  = 443
  type                     = "ingress"
}


#worker node
resource "aws_security_group" "jisu-cluster-node-sg" {
  name        = "${var.cluster-name}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.jisu_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
      "Name", "${var.cluster-name}-node-sg",
      "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "jisu-cluster-node-ingress-self" {
  description               = "Allow node to communicate with each other"
  from_port                 = 0
  protocol                  = "-1"
  security_group_id         = "${aws_security_group.jisu-cluster-node-sg.id}"
  source_security_group_id  = "${aws_security_group.jisu-cluster-node-sg.id}"
  to_port                   = 65535
  type                      = "ingress"
}

resource "aws_security_group_rule" "jisu-cluster-node-ingress-cluster" {
  description               = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                 = 1025
  protocol                  = "tcp"
  security_group_id         = "${aws_security_group.jisu-cluster-node-sg.id}"
  source_security_group_id  = "${aws_security_group.jisu-cluster-sg.id}"
  to_port                   = 65535
  type                      = "ingress"
}
