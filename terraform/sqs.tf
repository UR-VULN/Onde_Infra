# ────────────────────────────────────────────────────────────────────────────
# SQS (Simple Queue Service)
# 여행 예약 및 알림 비동기 처리용 메시지 큐
# ────────────────────────────────────────────────────────────────────────────

# ── Dead Letter Queue (처리 실패 메시지 보관용) ─────────────────────────────

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600 # 최대 보관 기간: 14일

  tags = {
    Name    = "${var.project_name}-dlq"
    Project = var.project_name
  }
}

# ── 메인 표준 큐 ────────────────────────────────────────────────────────────

resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-queue"
  delay_seconds              = 0    # 메시지 전송 즉시 소비 가능
  max_message_size           = 262144 # 최대 메시지 크기: 256KB
  message_retention_seconds  = 345600 # 메시지 보관 기간: 4일
  receive_wait_time_seconds  = 10   # Long Polling 설정 (불필요한 API 호출 감소)
  visibility_timeout_seconds = 30   # 메시지 처리 제한 시간 (Spring Boot 처리 시간 고려)

  # Dead Letter Queue 연결 (3회 처리 실패 시 DLQ로 이동)
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name    = "${var.project_name}-queue"
    Project = var.project_name
  }
}

# ── SQS 접근 정책 (백엔드 EC2 → SQS 메시지 송수신 허용) ────────────────────

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBackendEC2Access"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_ssm_role.arn # ec2.tf에 정의된 SSM IAM 역할 재사용
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}

# ── IAM 정책: EC2 역할에 SQS 권한 추가 ─────────────────────────────────────

resource "aws_iam_role_policy" "ec2_sqs_policy" {
  name = "${var.project_name}-ec2-sqs-policy"
  role = aws_iam_role.ec2_ssm_role.id # ec2.tf의 SSM 역할에 정책 추가

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.main.arn,
          aws_sqs_queue.dlq.arn
        ]
      }
    ]
  })
}
