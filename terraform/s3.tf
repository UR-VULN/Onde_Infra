# ────────────────────────────────────────────────────────────────────────────
# S3 버킷
# 1. 이미지용 버킷
# 2. E-ticket/PDF용 버킷
# ────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────
# 이미지용 S3 버킷
# ────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "travel_image" {
  bucket = var.s3_image_bucket_name

  tags = {
    Name    = var.s3_image_bucket_name
    Project = var.project_name
  }
}
resource "aws_s3_bucket" "deploy" {
  bucket = "${var.project_name}-deploy-artifacts"

  tags = {
    Name = "${var.project_name}-deploy-artifacts"
  }
}

# 퍼블릭 접근 차단
resource "aws_s3_bucket_public_access_block" "travel_image" {
  bucket = aws_s3_bucket.travel_image.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 버킷 암호화 (KMS 연동 전 기본 AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "travel_image" {
  bucket = aws_s3_bucket.travel_image.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}



# 버전 관리 활성화 (실수로 삭제된 파일 복구 가능)
resource "aws_s3_bucket_versioning" "travel_image" {
  bucket = aws_s3_bucket.travel_image.id

  versioning_configuration {
    status = "Enabled"
  }
}



# # 오래된 버전 자동 삭제 (30일 이후 비현재 버전 만료)
# resource "aws_s3_bucket_lifecycle_configuration" "app" {
#   bucket = aws_s3_bucket.app.id

#   rule {
#     id     = "expire-old-versions"
#     status = "Enabled"

#     filter {}

#     noncurrent_version_expiration {
#       noncurrent_days = 30
#     }
#   }
# }

# # CORS 설정 (브라우저에서 Presigned URL로 직접 업로드 시 필요)
# resource "aws_s3_bucket_cors_configuration" "travel_image" {
#   bucket = aws_s3_bucket.travel_image.id

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "PUT", "POST"]
#     allowed_origins = ["https://온데-도메인.com"]
#     max_age_seconds = 3000
#   }
# }

#────────────────────────────────────────────────────────────────────────────
# CloudTrail 전용 로그 버킷
#────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "onde-cloudtrail-logs-bucket"

  tags = {
    Name    = "onde-cloudtrail-logs"
    Project = "onde"
  }
}

# 퍼블릭 접근 차단
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail이 S3에 로그 쓸 수 있도록 버킷 정책 설정
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
