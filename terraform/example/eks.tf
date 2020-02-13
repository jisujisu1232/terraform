resource "aws_eks_cluster" "jisu-cluster" {
  name          = "${var.cluster-name}"
  role_arn      = "${aws_iam_role.jisu-cluster-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.jisu-cluster-sg.id}"]
    subnet_ids         = "${aws_subnet.jisu-tf-pub.*.id}"
  }

  depends_on = [
    "aws_iam_role_policy_attachment.jisu-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.jisu-cluster-AmazonEKSServicePolicy"
  ]
}
