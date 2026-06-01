# ────────────────────────────────────────────────────────────────────────────
# CloudWatch 알람 & 대시보드
# 모니터링 대상: EC2(Frontend/Backend), RDS, Redis, ALB
# ────────────────────────────────────────────────────────────────────────────

# ── SNS 토픽 (알람 수신용) ───────────────────────────────────────────────────

resource "aws_sns_topic" "alarm" {
  name = "${var.project_name}-alarm-topic"

  tags = {
    Name    = "${var.project_name}-alarm-topic"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 알람 — Frontend
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "frontend_cpu" {
  alarm_name          = "${var.project_name}-frontend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 # 2분
  statistic           = "Average"
  threshold           = 80 # CPU 80% 초과 시 알람
  alarm_description   = "Frontend EC2 CPU 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  ok_actions          = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  tags = {
    Name    = "${var.project_name}-frontend-cpu-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 알람 — Backend #1
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "backend1_cpu" {
  alarm_name          = "${var.project_name}-backend1-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Backend-1 EC2 CPU 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  ok_actions          = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId = aws_instance.backend_1.id
  }

  tags = {
    Name    = "${var.project_name}-backend1-cpu-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 알람 — Backend #2
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "backend2_cpu" {
  alarm_name          = "${var.project_name}-backend2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Backend-2 EC2 CPU 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  ok_actions          = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId = aws_instance.backend_2.id
  }

  tags = {
    Name    = "${var.project_name}-backend2-cpu-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 알람 — Windows Backend
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "windows_cpu" {
  alarm_name          = "${var.project_name}-windows-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Windows Backend EC2 CPU 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  ok_actions          = [aws_sns_topic.alarm.arn]

  dimensions = {
    InstanceId = aws_instance.backend_windows.id
  }

  tags = {
    Name    = "${var.project_name}-windows-cpu-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# RDS 알람
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  ok_actions          = [aws_sns_topic.alarm.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name    = "${var.project_name}-rds-cpu-alarm"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300 # 5분
  statistic           = "Average"
  threshold           = 5368709120 # 5GB (bytes 단위)
  alarm_description   = "RDS 여유 스토리지가 5GB 미만입니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name    = "${var.project_name}-rds-storage-alarm"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 100 # 연결 수 100 초과 시 알람
  alarm_description   = "RDS 데이터베이스 연결 수가 100을 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name    = "${var.project_name}-rds-connections-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# Redis (ElastiCache) 알람
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis CPU 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

  tags = {
    Name    = "${var.project_name}-redis-cpu-alarm"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.project_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 120
  statistic           = "Average"
  threshold           = 80 # 메모리 80% 초과 시 알람
  alarm_description   = "Redis 메모리 사용률이 80%를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
  tags = {
    Name    = "${var.project_name}-redis-memory-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# ALB 알람
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10 # 1분 내 5XX 에러 10회 초과 시 알람
  alarm_description   = "ALB 5XX 오류가 분당 10회를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  treat_missing_data  = "notBreaching" # 데이터 없으면 정상으로 간주

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name    = "${var.project_name}-alb-5xx-alarm"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${var.project_name}-alb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 3 # 응답 시간 3초 초과 시 알람
  alarm_description   = "ALB 평균 응답 시간이 3초를 초과했습니다."
  alarm_actions       = [aws_sns_topic.alarm.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name    = "${var.project_name}-alb-latency-alarm"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# CloudWatch 대시보드
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ── EC2 CPU ──────────────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU 사용률"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.frontend.id, { label = "Frontend" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.backend_1.id, { label = "Backend-1" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.backend_2.id, { label = "Backend-2" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.backend_windows.id, { label = "Backend-Windows" }]
          ]
          period = 120
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      # ── RDS ──────────────────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "RDS 모니터링"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.id, { label = "CPU%" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main.id, { label = "연결 수", yAxis = "right" }]
          ]
          period = 120
          stat   = "Average"
        }
      },
      # ── Redis ─────────────────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Redis 모니터링"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", aws_elasticache_replication_group.main.id, { label = "CPU%" }],
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", aws_elasticache_replication_group.main.id, { label = "메모리%", yAxis = "right" }]
          ]
          period = 120
          stat   = "Average"
        }
      },
      # ── ALB ──────────────────────────────────────────────────────────────
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ALB 요청/오류"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { label = "요청 수" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix, { label = "5XX 오류", yAxis = "right" }]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}

# ── Outputs ─────────────────────────────────────────────────────────────────

output "sns_alarm_topic_arn" {
  description = "알람 SNS 토픽 ARN (이메일 구독 설정 시 사용)"
  value       = aws_sns_topic.alarm.arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch 대시보드 URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-dashboard"
}
