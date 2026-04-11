output "dags_bucket_arn" {
  description = "ARN of the S3 bucket storing Airflow DAG files"
  value       = aws_s3_bucket.dags.arn
}

output "mwaa_security_group_ids" {
  description = "List of security group IDs attached to the MWAA environment"
  value       = [aws_security_group.mwaa.id]
}

output "mwaa_environment_arn" {
  description = "ARN of the MWAA Airflow environment"
  value       = aws_mwaa_environment.main.arn
}

output "mwaa_webserver_url" {
  description = "URL of the Airflow web UI"
  value       = aws_mwaa_environment.main.webserver_url
}