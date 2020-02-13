locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.jisu-cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.jisu-cluster.certificate_authority.0.data}
  name: ${aws_eks_cluster.jisu-cluster.arn}
contexts:
- context:
    cluster: ${aws_eks_cluster.jisu-cluster.arn}
    user: ${aws_eks_cluster.jisu-cluster.arn}
  name: ${aws_eks_cluster.jisu-cluster.arn}
current-context: ${aws_eks_cluster.jisu-cluster.arn}
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.jisu-cluster.arn}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - --region
      - ${var.region}
      - eks
      - get-token
      - --cluster-name
      - ${var.cluster-name}
      command: aws
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.jisu-cluster-node-role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}
