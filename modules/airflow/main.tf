# =============================================================================
# S3 Bucket for Airflow DAGs
# Dedicated bucket to store Airflow DAG Python files — separate from data lake
# Versioning enabled to track DAG file changes over time
# =============================================================================
resource "aws_s3_bucket" "dags" {
  bucket = "${var.project_name}-${var.environment}-airflow-dags"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-airflow-dags"
  })
}

resource "aws_s3_bucket_versioning" "dags" {
  bucket = aws_s3_bucket.dags.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dags" {
  bucket = aws_s3_bucket.dags.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# =============================================================================
# DAGs Folder Placeholder
# MWAA requires the dags/ prefix to exist in S3 before environment creation
# =============================================================================
resource "aws_s3_object" "dags_folder" {
  bucket = aws_s3_bucket.dags.id
  key    = "dags/"
  content = ""
}

# =============================================================================
# Security Group for MWAA
# Allows MWAA workers to communicate with each other (self-referencing ingress)
# Allows all outbound traffic for package downloads and API calls
# =============================================================================
resource "aws_security_group" "mwaa" {
  name   = "${var.project_name}-${var.environment}-mwaa-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true # allow traffic within the same security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-mwaa-sg"
  })
}

# =============================================================================
# MWAA Environment (Apache Airflow)
# Managed Airflow cluster wired to S3 DAGs bucket, VPC, security group, and IAM role
# environment_class and worker counts are configurable per environment via tfvars
# =============================================================================
resource "aws_mwaa_environment" "main" {
  name              = "${var.project_name}-${var.environment}-airflow"
  source_bucket_arn = aws_s3_bucket.dags.arn
  dag_s3_path       = "dags/"
  environment_class = var.environment_class

  execution_role_arn = var.mwaa_execution_role_arn
  airflow_version    = var.airflow_version

  min_workers = var.min_workers
  max_workers = var.max_workers
  webserver_access_mode = "PUBLIC_ONLY"

  network_configuration {
    subnet_ids         = slice(var.private_subnet_ids, 0,2)
    security_group_ids = [aws_security_group.mwaa.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-airflow"
  })
}
