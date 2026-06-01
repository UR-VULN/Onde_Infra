# ────────────────────────────────────────────────────────────────────────────
# Lambda
# SQS 메시지를 소비하여 예약 확인/알림 이메일 등을 처리하는 함수
# ────────────────────────────────────────────────────────────────────────────

# ── Lambda 실행 IAM 역할 ────────────────────────────────────────────────────

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-lambda-exec-role"
    Project = var.project_name
  }
}

# 기본 Lambda 실행 권한 (CloudWatch Logs 쓰기)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SQS 읽기 권한 (이벤트 소스 매핑용)
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "${var.project_name}-lambda-sqs-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSConsume"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = aws_sns_topic.notification.arn # sns.tf에 정의
      },
      {
        Sid    = "AllowS3ETicketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.eticket.arn}",
          "${aws_s3_bucket.eticket.arn}/*"
        ]
      }
    ]
  })
}

# ── Lambda 함수 배포용 더미 zip ──────────────────────────────────────────────
# 실제 배포 시 CI/CD에서 빌드된 zip으로 교체 예정

data "archive_file" "lambda_dummy" {
  type        = "zip"
  output_path = "${path.module}/lambda_dummy.zip"

  source {
    content  = <<-EOF
      def handler(event, context):
          print("Lambda placeholder — replace with actual deployment package")
          return {"statusCode": 200}
    EOF
    filename = "index.py"
  }
}

# ── Lambda 함수 본체 ────────────────────────────────────────────────────────

resource "aws_lambda_function" "notification" {
  function_name = "${var.project_name}-notification"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_dummy.output_path
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256

  timeout     = 30  # 최대 실행 시간 30초
  memory_size = 128 # 메모리 128MB (프리티어 범위 내)

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.notification.arn
      PROJECT_NAME  = var.project_name
    }
  }

  tags = {
    Name    = "${var.project_name}-notification-lambda"
    Project = var.project_name
  }
}

# ── SQS → Lambda 이벤트 소스 매핑 ─────────────────────────────────────────

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.notification.arn
  batch_size       = 10 # 한 번에 처리할 SQS 메시지 최대 수
  enabled          = true
}

# ── Outputs ─────────────────────────────────────────────────────────────────

output "lambda_function_name" {
  description = "Lambda 함수 이름"
  value       = aws_lambda_function.notification.function_name
}

output "lambda_function_arn" {
  description = "Lambda 함수 ARN"
  value       = aws_lambda_function.notification.arn
}
