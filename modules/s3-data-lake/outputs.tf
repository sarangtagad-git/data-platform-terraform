output "bucket_id" {
  description = "ID of the S3 bucket created for data lake"
  value       = aws_s3_bucket.main.id
}

output "bucket_name" {
  description = "Name of the S3 bucket created for data lake"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket created for data lake — used by IAM policies"
  value       = aws_s3_bucket.main.arn
}
