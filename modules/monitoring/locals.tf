locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "monitoring"
  })

  alarms = {
    eks_cpu_high = {
      alarm_name = "${var.project_name}-${var.environment}-eks-cpu-high" 
      metric_name = "CPUUtilization"
      namespace = "AWS/EKS"
      threshold = var.cpu_alarm_threshold
      dimensions = {
        ClusterName = var.eks_cluster_name
      }  
    }
    mwaa_heartbeat = {
      alarm_name = "${var.project_name}-${var.environment}-mwaa-heartbeat"
      metric_name = "SchedulerHeartbeat"
      namespace   = "AmazonMWAA"
      threshold = 1
      dimensions = {
        Environment = var.mwaa_environment_name
      }
    }
    dags_bucket_errors = {
      alarm_name = "${var.project_name}-${var.environment}-dags-bucket-4xx"
      metric_name = "4xxErrors"
      namespace = "AWS/S3"
      threshold = 10
      dimensions = {
        BucketName = var.dags_bucket_name
        FilterId = "EntireBucket"
      }
    }
    data_lake_bucket_errors = {
      alarm_name = "${var.project_name}-${var.environment}-data-lake-bucket-4xx"
      metric_name = "4xxErrors"
      namespace = "AWS/S3"
      threshold = 10
      dimensions = {
        BucketName = var.data_lake_bucket_name
        FilterId   = "EntireBucket"
      }
    }
  }
}