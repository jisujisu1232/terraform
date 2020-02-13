data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }
}

data "aws_subnet" "kube_admin" {
  id = "${var.kube_admin_instance_subnet_id}"
}

locals {
  name_prefix = "${data.aws_subnet.kube_admin.tags["prefix"]}kubectl"
  name_suffix = "${data.aws_subnet.kube_admin.tags["suffix"]}"
}

resource "aws_security_group" "kubectl" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
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
        "Name", "${local.name_prefix}-sg"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_security_group_rule" "kubectl" {
  description       = "Allow kubectl Instance to communicate with the cluster API Server"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.kubectl.id}"
  cidr_blocks       = "${var.kube_admin_cidrs}"
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-kubectl-https" {
  description              = "Allow kubectl Instance to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster.id}"
  source_security_group_id = "${aws_security_group.kubectl.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_eip" "kubectl" {
  count = "${var.is_kube_admin_instance_public ? 1 : 0}"
  vpc   = true
  tags = "${
    merge(
      map(
        "Name", "${local.name_prefix}${local.name_suffix}-eip"
      ),
      var.custom_tags
    )
  }"
}

locals {
  kubectl-userdata = <<KUBECTLUSERDATA
#!/bin/bash
pathStr="$PATH"
if [[ $pathStr != */usr/local/bin* ]]; then
   export PATH=$PATH:/usr/local/bin
fi
which pip &> /dev/null
if [ $? -ne 0 ] ; then
    echo "PIP NOT INSTALLED"
    [ `which yum` ] && $(yum install -y epel-release; yum install -y python-pip) && echo "PIP INSTALLED"
    [ `which apt-get` ] && apt-get -y update && apt-get -y install python-pip && echo "PIP INSTALLED"
    [ `which apt` ] && apt -y update && apt -y install python-pip && echo "PIP INSTALLED"
    pip install --upgrade pip &> /dev/null
fi
pip install awscli --ignore-installed six &> /dev/null

if [ $? -ne 0 ] ; then
  pip install --upgrade pip &> /dev/null
  pip install awscli --ignore-installed six &> /dev/null
fi
cd ~
cat <<'EOF' >> ~/kubeconfig
${local.kubeconfig}
EOF
cat <<'EOF' >> ~/config_map_aws_auth.yaml
${local.config_map_aws_auth}
EOF
curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl
chmod +x ./kubectl
cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
mkdir ~/.kube
mv ~/kubeconfig ~/.kube/config
KUBECTLUSERDATA
}

resource "aws_iam_role" "kubectl" {
  name = "${local.name_prefix}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "kubectl" {
  name        = "${local.name_prefix}-policy"
  path        = "/"
  description = "${local.name_prefix}-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "${aws_eks_cluster.cluster.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*",
                "codecommit:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "kubectl" {
  role       = "${aws_iam_role.kubectl.name}"
  policy_arn = "${aws_iam_policy.kubectl.arn}"
}

resource "aws_iam_instance_profile" "kubectl" {
  name = "${local.name_prefix}-profile"
  role = "${aws_iam_role.kubectl.name}"
}

resource "aws_instance" "kubectl" {
  ami                    = "${data.aws_ami.amazon-linux.id}"
  instance_type          = "${var.kube_admin_instance_instance_type}"
  iam_instance_profile   = "${aws_iam_instance_profile.kubectl.name}"
  key_name               = "${var.kube_admin_instance_key}"
  vpc_security_group_ids = ["${aws_security_group.kubectl.id}"]
  subnet_id              = "${var.kube_admin_instance_subnet_id}"
  user_data_base64       = "${base64encode(local.kubectl-userdata)}"
  tags = "${
    merge(
      map(
        "Name", "${local.name_prefix}${local.name_suffix}"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_eip_association" "kubectl" {
  count         = "${var.is_kube_admin_instance_public ? 1 : 0}"
  instance_id   = "${aws_instance.kubectl.id}"
  allocation_id = "${aws_eip.kubectl[count.index].id}"
}
