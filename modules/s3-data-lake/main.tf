# ------------------------------------------------------------------------------
# S3 BUCKET
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket        = "${var.project_name}-${var.environment}-data-lake-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-data-lake"
  })
}

# ------------------------------------------------------------------------------
# VERSIONING — keep history of all file changes, allows recovery
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "main" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# ENCRYPTION — encrypt all data at rest using AES256 (SSE-S3)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------------------------
# PUBLIC ACCESS BLOCK — block ALL public access from all angles
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# LIFECYCLE RULES — auto-archive old data to save storage costs
# raw/ → Standard-IA (day 90) → Glacier (day 180) → Delete (expiry days)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_rules_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "raw-data-lifecycle"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = var.raw_data_expiry_days
    }
  }
}

# ------------------------------------------------------------------------------
# BUCKET POLICY — enforce HTTPS only, deny all non-encrypted transport
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
