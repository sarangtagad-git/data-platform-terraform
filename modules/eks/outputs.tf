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

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider — used by IRSA trust policies"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the EKS OIDC provider without https:// — used in IRSA trust policy conditions"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}