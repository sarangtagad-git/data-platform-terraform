# =============================================================================
# EKS Cluster
# Creates the control plane with the provided IAM role and VPC configuration
# =============================================================================
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-eks"
  role_arn = var.eks_cluster_role_arn
  version  = var.cluster_version

  vpc_config {    
    subnet_ids = var.private_subnet_ids
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks"
  })
}

# =============================================================================
# EKS Node Groups
# Creates one managed node group per entry in var.node_groups (primary + secondary)
# Each node group gets its own instance type and scaling config
# =============================================================================
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-eks-${each.key}"
  node_role_arn   = var.eks_node_group_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [each.value.instance_type]

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-${each.key}"
  })
}

# =============================================================================
# EKS Add-ons
# Installs essential cluster add-ons after node groups are ready:
#   vpc-cni    — pod networking
#   coredns    — DNS resolution inside the cluster
#   kube-proxy — network rules on each worker node
# depends_on ensures node groups are ready before add-ons are installed
# =============================================================================
# =============================================================================
# EKS Access Entry for MWAA
# Grants the MWAA execution role access to the EKS cluster
# Maps the IAM role to Kubernetes username "mwaa-user"
# The RoleBinding in kubernetes/airflow-rbac.yaml binds this username to
# the airflow-pod-role — allowing MWAA to create/delete pods via KubernetesPodOperator
# =============================================================================
resource "aws_eks_access_entry" "mwaa" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.mwaa_role_arn
  user_name     = "mwaa-user"
  type          = "STANDARD"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-mwaa-eks-access"
  })
}

resource "aws_eks_addon" "main" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy"])

  cluster_name = aws_eks_cluster.main.name
  addon_name   = each.key

  depends_on = [aws_eks_node_group.main]
}
