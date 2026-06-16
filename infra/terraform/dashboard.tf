resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          markdown = <<-EOT
# ${var.project_name} — Monitoreo EKS

| Recurso | Tipo |
|----------|------|
| Cluster | EKS — 2 nodos t3.medium |
| Logs | CloudWatch — `/aws/eks/${var.project_name}-cluster/cluster` |
| Métricas pods | `kubectl top pods` |
| Eventos | `kubectl get events` |
EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 3
        width  = 24
        height = 9
        properties = {
          region  = var.aws_region
          title   = "Logs recientes del cluster"
          query   = "SOURCE '/aws/eks/${var.project_name}-cluster/cluster' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          view    = "table"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          region  = var.aws_region
          title   = "Errores en logs"
          query   = "SOURCE '/aws/eks/${var.project_name}-cluster/cluster' | fields @timestamp, @message | filter @message like /error|fail|Error|Fail/ | sort @timestamp desc | limit 25"
          view    = "table"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          region  = var.aws_region
          title   = "Eventos por tipo"
          query   = "SOURCE '/aws/eks/${var.project_name}-cluster/cluster' | stats count() by @logStream | sort count() desc"
          view    = "table"
        }
      }
    ]
  })
}
