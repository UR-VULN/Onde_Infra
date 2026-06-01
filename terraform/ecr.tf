# ────────────────────────────────────────────────────────────────────────────
# ECR (Elastic Container Registry)
# 프론트엔드 / 사용자 백엔드 / 판매자 백엔드 도커 이미지 저장소
# 관리자 백엔드(Windows)는 jar 직접 실행으로 ECR 미사용
# ────────────────────────────────────────────────────────────────────────────

# ── 프론트엔드 ECR 리포지토리 ────────────────────────────────────────────────

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}/frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-frontend-ecr"
    Project = var.project_name
  }
}

# ── 사용자 API 백엔드 ECR 리포지토리 (Backend-1 Linux) ───────────────────────

resource "aws_ecr_repository" "backend_user" {
  name                 = "${var.project_name}/backend-user"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-backend-user-ecr"
    Project = var.project_name
  }
}

# ── 판매자 API 백엔드 ECR 리포지토리 (Backend-2 Linux) ───────────────────────

resource "aws_ecr_repository" "backend_seller" {
  name                 = "${var.project_name}/backend-seller"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-backend-seller-ecr"
    Project = var.project_name
  }
}

# ── 오래된 이미지 자동 삭제 정책 (최신 10개만 유지) ──────────────────────────

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "최신 10개 이미지만 유지"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "backend_user" {
  repository = aws_ecr_repository.backend_user.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "최신 10개 이미지만 유지"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "backend_seller" {
  repository = aws_ecr_repository.backend_seller.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "최신 10개 이미지만 유지"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# ── EC2가 ECR에 접근할 수 있도록 IAM 정책 추가 ───────────────────────────────

resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "${var.project_name}-ec2-ecr-policy"
  role = aws_iam_role.ec2_ssm_role.id # ec2.tf의 SSM 역할에 ECR 권한 추가

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECRAccess"
        Effect = "Allow"
        Action = [
        "ecr:GetAuthorizationToken",        # 로그인
        "ecr:BatchCheckLayerAvailability",  # 다운로드용
        "ecr:GetDownloadUrlForLayer",       # 다운로드용
        "ecr:BatchGetImage"                 # 다운로드용
        ]

        Resource = "*"
      }
    ]
  })
}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "ecr_frontend_repository_url" {
  description = "프론트엔드 ECR 리포지토리 URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_user_repository_url" {
  description = "사용자 API 백엔드 ECR 리포지토리 URL"
  value       = aws_ecr_repository.backend_user.repository_url
}

output "ecr_backend_seller_repository_url" {
  description = "판매자 API 백엔드 ECR 리포지토리 URL"
  value       = aws_ecr_repository.backend_seller.repository_url
}

output "ecr_login_command" {
  description = "ECR 도커 로그인 명령어"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.backend_user.repository_url}"
}
