# Cloud Monitoring Dashboard for Infrastructure Health

resource "google_monitoring_dashboard" "infrastructure_health" {
  dashboard_json = jsonencode({
    displayName = "CS3 - Infrastructure Health"
    mosaicLayout = {
      columns = 12
      tiles = [
        # Cloud SQL CPU Utilization
        {
          width  = 6
          height = 4
          widget = {
            title = "Cloud SQL CPU Utilization (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "CPU %"
                scale = "LINEAR"
              }
            }
          }
        },
        # Cloud SQL Memory Usage
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Cloud SQL Memory Usage (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Memory %"
                scale = "LINEAR"
              }
            }
          }
        },
        # Cloud SQL Active Connections
        {
          width  = 6
          height = 4
          yPos   = 4
          widget = {
            title = "Cloud SQL Active Connections"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/postgresql/num_backends\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Connections"
                scale = "LINEAR"
              }
            }
          }
        },
        # Cloud SQL Disk Usage
        {
          width  = 6
          height = 4
          xPos   = 6
          yPos   = 4
          widget = {
            title = "Cloud SQL Disk Usage (GB)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/disk/bytes_used\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Disk GB"
                scale = "LINEAR"
              }
            }
          }
        },
        # VPC Firewall Allowed Traffic
        {
          width  = 6
          height = 4
          yPos   = 8
          widget = {
            title = "VPC Firewall - Allowed Traffic"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_subnetwork\" AND metric.type=\"compute.googleapis.com/firewall/dropped_packets_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.subnetwork_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Packets/sec"
                scale = "LINEAR"
              }
            }
          }
        },
        # Cloud SQL Replication Lag (for HA)
        {
          width  = 6
          height = 4
          xPos   = 6
          yPos   = 8
          widget = {
            title = "Cloud SQL Replication Lag (seconds)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/replication/replica_lag\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Lag (s)"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}

# Alert policy for high CPU utilization
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "Cloud SQL High CPU Utilization"
  combiner     = "OR"
  conditions {
    display_name = "CPU utilization above 80%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = []

  documentation {
    content   = "Cloud SQL instance CPU utilization is above 80% for 5 minutes. Consider scaling up the instance."
    mime_type = "text/markdown"
  }
}

# Alert policy for high memory utilization
resource "google_monitoring_alert_policy" "high_memory" {
  display_name = "Cloud SQL High Memory Utilization"
  combiner     = "OR"
  conditions {
    display_name = "Memory utilization above 90%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = []

  documentation {
    content   = "Cloud SQL instance memory utilization is above 90% for 5 minutes. Consider scaling up the instance."
    mime_type = "text/markdown"
  }
}

# Alert policy for disk usage
resource "google_monitoring_alert_policy" "high_disk_usage" {
  display_name = "Cloud SQL High Disk Usage"
  combiner     = "OR"
  conditions {
    display_name = "Disk usage above 85%"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = []

  documentation {
    content   = "Cloud SQL instance disk usage is above 85%. Disk autoresize should trigger, but monitor for issues."
    mime_type = "text/markdown"
  }
}
