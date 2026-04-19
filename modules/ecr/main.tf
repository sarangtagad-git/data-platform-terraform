# =============================================================================
# ECR Repository
# Stores Docker images for EKS task containers used by KubernetesPodOperator
# Image scanning enabled on push to detect vulnerabilities automatically
# =============================================================================
resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-${var.environment}-etl-job"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-etl-job"
  })
}

# =============================================================================
# ECR Lifecycle Policy
# Keeps only the last 10 images — auto-expires older ones to control storage costs
# =============================================================================
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images, expire older ones"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
