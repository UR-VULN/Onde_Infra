# ────────────────────────────────────────────────────────────────────────────
# S3 버킷
# 1. 이미지용 버킷
# 2. E-ticket/PDF용 버킷
# ────────────────────────────────────────────────────────────────────────────

# ── 업로드 버킷 ────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${var.environment}-files-${data.aws_caller_identity.current.account_id}"
  # account_id를 suffix로 붙여 전 세계 고유 버킷 이름 보장

  tags = {
    Name = "${var.project_name}-files"
  }
}

# 퍼블릭 액세스 완전 차단 (서명된 URL로만 접근)
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# 현재 AWS 계정 ID 조회 (버킷 이름 suffix용)
# data "aws_caller_identity" "current" {}

# 서버 사이드 암호화 (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 버전 관리 활성화 (실수로 삭제된 파일 복구 가능)
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# 오래된 버전 자동 삭제 (30일 이후 비현재 버전 만료)
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# CORS 설정 (브라우저에서 Presigned URL로 직접 업로드 시 필요)
resource "aws_s3_bucket_cors_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    # 운영 환경에서는 실제 도메인으로 제한: ["https://yourdomain.com"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
