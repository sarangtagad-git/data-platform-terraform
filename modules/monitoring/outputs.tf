output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard in AWS console"
  value       = "https://${data.aws_caller_identity.current.id}.console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "cloudwatch_alarms" {
  description = "Map of CloudWatch alarm names keyed by alarm identifier"
  value       = { for k, v in aws_cloudwatch_metric_alarm.main : k => v.alarm_name }
}