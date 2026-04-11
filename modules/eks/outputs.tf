output "cluster_name" {
  description = "Name of the EKS cluster"
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "API server endpoint URL of the EKS cluster"
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate authority data for the EKS cluster"
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_group_names" {
  description = "Map of node group names keyed by node group identifier"
  value = { for k, v in aws_eks_node_group.main : k => v.node_group_name }
}