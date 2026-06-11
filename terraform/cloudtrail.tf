#cloudwatch 로그 그룹
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/onde"
  retention_in_days = 90

  tags = {
    Name    = "onde-cloudtrail-logs"
    Project = "onde"
  }
}

#IAM Role (CloudTrail → CloudWatch 연동용)
resource "aws_iam_role" "cloudtrail_role" {
  name = "onde-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_policy" {
  name = "onde-cloudtrail-policy"
  role = aws_iam_role.cloudtrail_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

#cloudtrail 생성
resource "aws_cloudtrail" "onde_trail" {
  name                          = "onde-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  # CloudWatch Logs 연동
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn

  # S3 데이터 이벤트 로그 수집 (이미지 버킷 및 배포 버킷 모니터링)
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.travel_image.arn}/",
        "${aws_s3_bucket.deploy.arn}/"
      ]
    }
  }

  tags = {
    Name    = "onde-cloudtrail"
    Project = "onde"
  }
  # S3 버킷 정책 및 IAM 롤 정책이 먼저 정상 반영된 후 CloudTrail이 생성되도록 강제
  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_iam_role_policy.cloudtrail_policy
  ]
}