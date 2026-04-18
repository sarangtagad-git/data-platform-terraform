# ------------------------------------------------------------------------------
# EKS CLUSTER ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------------------------------------------
# EKS NODE GROUP ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eks_node_group" {
  name = "${var.project_name}-${var.environment}-eks-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-node-group"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ------------------------------------------------------------------------------
# MWAA (AIRFLOW) EXECUTION ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_role" "mwaa" {
  name = "${var.project_name}-${var.environment}-airflow"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = [
          "airflow.amazonaws.com",
          "airflow-env.amazonaws.com"
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-airflow"
  })
}

resource "aws_iam_role_policy" "mwaa" {
  name   = "${var.project_name}-${var.environment}-mwaa-policy"
  role   = aws_iam_role.mwaa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Permission 1: MWAA publish its own metrics
      {
        Effect   = "Allow"
        Action   = ["airflow:PublishMetrics"]
        Resource = "*"
      },

      # Permission 2: Read DAGs and requirements from S3
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetAccountPublicAccessBlock",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },

      # Permission 3: Write logs to CloudWatch
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups",
          "logs:DescribeResourcePolicies"
        ]
        Resource = "*"
      },

      # Permission 4: Publish metrics to CloudWatch
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
      },

      # Permission 5: SQS for internal Celery task queue
      {
        Effect = "Allow"
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:ap-south-1:*:airflow-celery-*"
      },

      # Permission 6: KMS for encryption used by SQS and S3
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:ViaService" = [
              "sqs.ap-south-1.amazonaws.com",
              "s3.ap-south-1.amazonaws.com"
            ]
          }
        }
      },

      # Permission 7: Read secrets
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })
}

# Note: AmazonMWAAServiceRolePolicy is a service-linked policy — cannot be attached to custom roles
# All required MWAA permissions are covered by the inline policy above (aws_iam_role_policy.mwaa)

# ------------------------------------------------------------------------------
# GITHUB ACTIONS OIDC ROLE
# ------------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions"
  max_session_duration = 7200   # 2 Hours so token should live that long

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          # Wildcard allows both pull_request and push events from this repo
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-github-actions"
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.project_name}-${var.environment}-github-actions-policy"
  role   = aws_iam_role.github_actions.id

  # NOTE: AdministratorAccess used for portfolio project
  # In production → restrict to specific services (S3, DynamoDB, EKS, IAM etc.)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["*"]
      Resource = ["*"]
    }]
  })
}

