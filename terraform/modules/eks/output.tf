locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority.0.data}
  name: ${aws_eks_cluster.cluster.arn}
contexts:
- context:
    cluster: ${aws_eks_cluster.cluster.arn}
    user: ${aws_eks_cluster.cluster.arn}
  name: ${aws_eks_cluster.cluster.arn}
current-context: ${aws_eks_cluster.cluster.arn}
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.cluster.arn}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - --region
      - ${var.region}
      - eks
      - get-token
      - --cluster-name
      - ${var.cluster_name}
      command: aws
KUBECONFIG
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
    - rolearn: ${aws_iam_role.node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${aws_iam_role.kubectl.arn}
      username: admin
      groups:
        - system:masters
CONFIGMAPAWSAUTH
}

output "kubeconfig" {
  description = "kubeconfig YAML"
  value       = "${local.kubeconfig}"
}

output "config_map_aws_auth" {
  description = "kube ConfigMap YAML"
  value       = "${local.config_map_aws_auth}"
}

output "cluster_sg_id" {
  value = "${aws_security_group.cluster.id}"
}

output "node_sg_id" {
  value = "${aws_security_group.node.id}"
}

output "creator_kubectl_command" {
  value = <<NEED

terraform apply 명령 실행자가

사용한 provider 의 aws profile 을 사용

EKS RBAC 에 kubectl 용으로 생성된 인스턴스 Role 을 추가해야 한다.
#생성시 사용된 IAM이 EKS RBAC 설정 됨.

1.
aws eks --region ap-northeast-2 update-kubeconfig --name ${var.cluster_name}
혹은 output kubeconfig 을 참조하여 생성된 Cluster 를 향한 kubectl 설정

2.
output config_map_aws_auth의 내용을 apply 하여 RBAC Role 추가


kubectl apply -f [output config_map_aws_auth].yaml

NEED
}
