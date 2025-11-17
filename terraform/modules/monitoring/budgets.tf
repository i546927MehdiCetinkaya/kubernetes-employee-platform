# AWS Budgets for Cost Management

resource "aws_budgets_budget" "monthly_cost" {
  name              = "${var.cluster_name}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }

  tags = {
    Name        = "${var.cluster_name}-budget"
    Environment = var.environment
  }
}

# Budget for EKS-specific costs
resource "aws_budgets_budget" "eks_cost" {
  name              = "${var.cluster_name}-eks-budget"
  budget_type       = "COST"
  limit_amount      = var.eks_budget_limit
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  tags = {
    Name        = "${var.cluster_name}-eks-budget"
    Environment = var.environment
  }
}

# Budget for DynamoDB costs
resource "aws_budgets_budget" "dynamodb_cost" {
  name              = "${var.cluster_name}-dynamodb-budget"
  budget_type       = "COST"
  limit_amount      = var.dynamodb_budget_limit
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  tags = {
    Name        = "${var.cluster_name}-dynamodb-budget"
    Environment = var.environment
  }
}

# Cost Anomaly Detection
resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "${var.cluster_name}-service-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = {
    Name        = "${var.cluster_name}-anomaly-monitor"
    Environment = var.environment
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_alerts" {
  count = length(var.budget_alert_emails) > 0 ? 1 : 0

  name      = "${var.cluster_name}-anomaly-subscription"
  frequency = "DAILY"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "EMAIL"
    address = var.budget_alert_emails[0]
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["100"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = {
    Name        = "${var.cluster_name}-anomaly-alerts"
    Environment = var.environment
  }
}
