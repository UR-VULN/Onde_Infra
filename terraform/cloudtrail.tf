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

  # KMS 암호화 적용
  kms_key_id = aws_kms_key.s3_key.arn

  # CloudWatch Logs 연동
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn

  tags = {
    Name    = "onde-cloudtrail"
    Project = "onde"
  }
}