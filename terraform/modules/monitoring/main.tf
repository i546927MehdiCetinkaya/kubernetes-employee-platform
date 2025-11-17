# CloudWatch Monitoring and Logging

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.cluster_name}-logs"
    Environment = var.environment
  }
}

# Note: Dashboard and alarms are defined in alarms.tf

