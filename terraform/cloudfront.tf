# ────────────────────────────────────────────────────────────────────────────
# CloudFront Distribution for S3 Image Bucket
# ────────────────────────────────────────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "travel_image" {
  name                              = "${var.project_name}-travel-image-oac"
  description                       = "OAC for travel image S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "travel_image" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""
  price_class         = "PriceClass_100" # 북미, 유럽, 아시아 등에 배포 (가장 저렴)

  origin {
    domain_name              = aws_s3_bucket.travel_image.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.travel_image.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.travel_image.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.travel_image.id}"

    # 최신 AWS 권장 방식: 캐시 정책과 원본 요청 정책 사용 가능하지만, 
    # 간단한 구성으로 forwarded_values 활용
    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1일
    max_ttl                = 31536000 # 365일
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 커스텀 도메인이 없으므로 기본 CloudFront 인증서 사용
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "${var.project_name}-cf-travel-image"
    Project = var.project_name
  }
}

# ────────────────────────────────────────────────────────────────────────────
# S3 버킷 정책: CloudFront OAC를 통해서만 접근 허용
# ────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_policy" "travel_image_cf" {
  bucket = aws_s3_bucket.travel_image.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.travel_image.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.travel_image.arn
          }
        }
      }
    ]
  })
}
