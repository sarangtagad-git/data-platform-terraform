# =============================================================================
# SNS Topic for Alerts
# Central notification channel — all CloudWatch alarms send alerts here
# =============================================================================
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alerts"
  })
}

# =============================================================================
# SNS Email Subscription
# Subscribes the provided email address to receive alarm notifications
# Note: AWS sends a confirmation email — subscription is pending until confirmed
# =============================================================================
resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# =============================================================================
# CloudWatch Metric Alarms
# Creates one alarm per entry in local.alarms (defined in locals.tf):
#   - eks_cpu_high           — EKS cluster CPU utilization
#   - mwaa_heartbeat         — Airflow scheduler health
#   - dags_bucket_errors     — S3 DAGs bucket 4xx errors
#   - data_lake_errors       — S3 data lake bucket 4xx errors
# All alarms notify the SNS topic on breach
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "main" {
  for_each = local.alarms

  alarm_name          = each.value.alarm_name
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  dimensions          = each.value.dimensions
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = merge(local.common_tags, {
    Name = each.value.alarm_name
  })
}

# =============================================================================
# CloudWatch Dashboard
# Single pane of glass for all key platform metrics
# Four widgets: EKS CPU, MWAA Heartbeat, DAGs bucket errors, Data lake errors
# =============================================================================
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title   = "EKS CPU Utilization"
          metrics = [["AWS/EKS", "CPUUtilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          title   = "MWAA Scheduler Heartbeat"
          metrics = [["AWS/MWAA", "Heartbeat", "Environment", var.mwaa_environment_name]]
          period  = 300
          stat    = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          title   = "DAGs Bucket 4xx Errors"
          metrics = [["AWS/S3", "4xxErrors", "BucketName", var.dags_bucket_name, "FilterId", "EntireBucket"]]
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title   = "Data Lake Bucket 4xx Errors"
          metrics = [["AWS/S3", "4xxErrors", "BucketName", var.data_lake_bucket_name, "FilterId", "EntireBucket"]]
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}
