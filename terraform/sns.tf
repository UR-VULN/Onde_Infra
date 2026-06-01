# ────────────────────────────────────────────────────────────────────────────
# SNS (Simple Notification Service)
# 예약 완료·취소·동행 매칭 알림 발송용 토픽
# ────────────────────────────────────────────────────────────────────────────

# ── 사용자 알림 토픽 (예약 확인, 동행 매칭 등) ─────────────────────────────

resource "aws_sns_topic" "notification" {
  name = "${var.project_name}-notification-topic"

  tags = {
    Name    = "${var.project_name}-notification-topic"
    Project = var.project_name
  }
}

# ── 이메일 구독 (운영자 알림 수신용) ───────────────────────────────────────
# 주의: 구독 확인 이메일을 수동으로 승인해야 활성화됨

resource "aws_sns_topic_subscription" "operator_email" {
  topic_arn = aws_sns_topic.notification.arn
  protocol  = "email"
  endpoint  = var.operator_email # variables.tf에 추가 필요
}

# ── SNS 토픽 정책 (Lambda가 Publish할 수 있도록 허용) ──────────────────────

resource "aws_sns_topic_policy" "notification" {
  arn = aws_sns_topic.notification.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_exec.arn
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.notification.arn
      },
      {
        Sid    = "AllowEC2Publish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_ssm_role.arn
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.notification.arn
      }
    ]
  })
}

# ── IAM 정책: EC2 역할에 SNS Publish 권한 추가 ─────────────────────────────

resource "aws_iam_role_policy" "ec2_sns_policy" {
  name = "${var.project_name}-ec2-sns-policy"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowSNSPublish"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.notification.arn
      }
    ]
  })
}

# ── Outputs ─────────────────────────────────────────────────────────────────

output "sns_notification_topic_arn" {
  description = "사용자 알림 SNS 토픽 ARN (Spring Boot application.yml에서 참조)"
  value       = aws_sns_topic.notification.arn
}
