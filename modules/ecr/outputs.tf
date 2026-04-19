output "repository_url" {
  description = "ECR repository URL — used as the image path in KubernetesPodOperator"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.main.name
}
