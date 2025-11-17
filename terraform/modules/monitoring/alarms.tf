# CloudWatch Alarms for Monitoring

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.cluster_name}-alerts"
  
  tags = {
    Name        = "${var.cluster_name}-alerts"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarm: EKS Cluster Failed Nodes
resource "aws_cloudwatch_metric_alarm" "cluster_failed_nodes" {
  alarm_name          = "${var.cluster_name}-failed-nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when EKS cluster has failed nodes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name        = "${var.cluster_name}-failed-nodes-alarm"
    Environment = var.environment
  }
}

# Alarm: Pod Failures (via log metric filter)
resource "aws_cloudwatch_log_metric_filter" "pod_failures" {
  name           = "${var.cluster_name}-pod-failures"
  log_group_name = aws_cloudwatch_log_group.cluster.name
  pattern        = "[time, stream, level=ERROR*, msg=\"*pod*failed*\" || msg=\"*CrashLoopBackOff*\"]"

  metric_transformation {
    name      = "PodFailures"
    namespace = "EKS/CustomMetrics"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "pod_failures" {
  alarm_name          = "${var.cluster_name}-pod-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "PodFailures"
  namespace           = "EKS/CustomMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alert when pods are failing repeatedly"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.cluster_name}-pod-failures-alarm"
    Environment = var.environment
  }
}

# Alarm: High CPU Usage on Nodes
resource "aws_cloudwatch_metric_alarm" "high_node_cpu" {
  alarm_name          = "${var.cluster_name}-high-node-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when node CPU usage exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name        = "${var.cluster_name}-high-cpu-alarm"
    Environment = var.environment
  }
}

# Alarm: High Memory Usage on Nodes
resource "aws_cloudwatch_metric_alarm" "high_node_memory" {
  alarm_name          = "${var.cluster_name}-high-node-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when node memory usage exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name        = "${var.cluster_name}-high-memory-alarm"
    Environment = var.environment
  }
}

# Alarm: DynamoDB Read Throttling
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "${var.cluster_name}-dynamodb-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when DynamoDB reads are being throttled"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = "${var.cluster_name}-employees"
  }

  tags = {
    Name        = "${var.cluster_name}-dynamodb-throttle-alarm"
    Environment = var.environment
  }
}

# Alarm: DynamoDB Write Throttling
resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "${var.cluster_name}-dynamodb-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when DynamoDB writes are being throttled"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = "${var.cluster_name}-employees"
  }

  tags = {
    Name        = "${var.cluster_name}-dynamodb-write-throttle-alarm"
    Environment = var.environment
  }
}

# Alarm: API High Error Rate (via log metric filter)
resource "aws_cloudwatch_log_metric_filter" "api_errors" {
  name           = "${var.cluster_name}-api-errors"
  log_group_name = aws_cloudwatch_log_group.cluster.name
  pattern        = "[time, stream, level=ERROR*, ...]"

  metric_transformation {
    name      = "APIErrors"
    namespace = "EKS/CustomMetrics"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_api_error_rate" {
  alarm_name          = "${var.cluster_name}-high-api-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "APIErrors"
  namespace           = "EKS/CustomMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "Alert when API error rate is high (>50 errors in 5 minutes)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.cluster_name}-api-errors-alarm"
    Environment = var.environment
  }
}

# Alarm: Workspace Provisioning Failures
resource "aws_cloudwatch_log_metric_filter" "workspace_failures" {
  name           = "${var.cluster_name}-workspace-failures"
  log_group_name = aws_cloudwatch_log_group.cluster.name
  pattern        = "[time, stream, level=ERROR*, msg=\"*Failed to provision workspace*\"]"

  metric_transformation {
    name      = "WorkspaceProvisioningFailures"
    namespace = "EKS/CustomMetrics"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "workspace_provisioning_failures" {
  alarm_name          = "${var.cluster_name}-workspace-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WorkspaceProvisioningFailures"
  namespace           = "EKS/CustomMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alert when workspace provisioning fails repeatedly"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.cluster_name}-workspace-failures-alarm"
    Environment = var.environment
  }
}

# Enhanced Dashboard with Application Metrics
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", { stat = "Average", label = "Failed Nodes" }],
            [".", "cluster_node_count", { stat = "Average", label = "Total Nodes" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS Cluster Health"
          yAxis = { left = { min = 0 } }
        }
        width  = 12
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", { stat = "Average" }],
            [".", "node_memory_utilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Node Resource Utilization"
          yAxis = { left = { min = 0, max = 100 } }
        }
        width  = 12
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Capacity"
        }
        width  = 12
        height = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["EKS/CustomMetrics", "PodFailures", { stat = "Sum", label = "Pod Failures" }],
            [".", "APIErrors", { stat = "Sum", label = "API Errors" }],
            [".", "WorkspaceProvisioningFailures", { stat = "Sum", label = "Workspace Failures" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Application Errors"
          yAxis = { left = { min = 0 } }
        }
        width  = 12
        height = 6
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.cluster.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Error Logs"
        }
        width  = 24
        height = 6
      }
    ]
  })
}
