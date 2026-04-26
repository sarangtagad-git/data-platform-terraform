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

  # Required for aws_eks_access_entry — default mode (CONFIG_MAP) does not support it
  # API_AND_CONFIG_MAP keeps backward compatibility while enabling the Access Entry API
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
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

# =============================================================================
# EKS OIDC Provider
# Prerequisite for IRSA — tells AWS IAM to trust tokens issued by this cluster
# Pods can then exchange their Kubernetes token for temporary AWS credentials
# without relying on the node instance profile (blocked by IMDSv2 hop limit)
# =============================================================================
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-oidc"
  })
}

# =============================================================================
# EKS Access Entry for Admin IAM User
# Grants the local terraform-admin IAM user kubectl access to the cluster
# Without this, only the GitHub Actions OIDC role (cluster creator) has access
# =============================================================================
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.admin_iam_arn
  type          = "STANDARD"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-admin-eks-access"
  })
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.admin_iam_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# =============================================================================
# EKS Access Entry for GitHub Actions
# Grants the GitHub Actions OIDC role cluster-admin access so Terraform can
# apply Kubernetes resources (namespace, RBAC, ServiceAccount) via the
# kubernetes provider during CI/CD runs
# =============================================================================
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-github-actions-eks-access"
  })
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
