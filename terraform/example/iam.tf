#eks cluster
resource "aws_iam_role" "jisu-cluster-role" {
  name = "${var.cluster-name}-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "jisu-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.jisu-cluster-role.name}"
}

resource "aws_iam_role_policy_attachment" "jisu-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.jisu-cluster-role.name}"
}


#worker node
resource "aws_iam_role" "jisu-cluster-node-role" {
  name = "${var.cluster-name}-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal":{
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "jisu-cluster-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.jisu-cluster-node-role.name}"
}

resource "aws_iam_role_policy_attachment" "jisu-cluster-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.jisu-cluster-node-role.name}"
}

resource "aws_iam_role_policy_attachment" "jisu-cluster-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.jisu-cluster-node-role.name}"
}

resource "aws_iam_instance_profile" "jisu-cluster-node-profile" {
  name = "${var.cluster-name}-node-profile"
  role = "${aws_iam_role.jisu-cluster-node-role.name}"
}
