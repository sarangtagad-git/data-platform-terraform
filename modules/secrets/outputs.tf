output "kubeconfig_secret_arn" {
  description = "ARN of the kubeconfig secret in Secrets Manager"
  value       = aws_secretsmanager_secret.kubeconfig.arn
}

output "kubeconfig_secret_name" {
  description = "Name of the kubeconfig secret in Secrets Manager"
  value       = aws_secretsmanager_secret.kubeconfig.name
}
