# ────────────────────────────────────────────────────────────────────────────
# Application Load Balancer (ALB)
# ────────────────────────────────────────────────────────────────────────────

# ALB security group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "ALB security group for public HTTP/HTTPS access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 1. ALB 본체 생성 (Public Subnet에 배치하여 외부 인터넷 노출)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id # 모든 퍼블릭 서브넷에 가용성 확보

  enable_deletion_protection = false # 테스트 환경이므로 삭제 보호 비활성화

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. 프론트엔드 타겟 그룹 (Nginx 서버 묶음)
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-frontend-tg"
  }
}

# 3. 백엔드 타겟 그룹 (Spring Boot 서버 묶음) - [추가]
resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-backend-tg"
  port     = 8080 # Spring Boot 기본 포트
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/v1/health" # 백엔드 API 헬스 체크 경로
    port                = "8080"
    protocol            = "HTTP"
    matcher             = "200,401"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# 4. Windows 백엔드 타겟 그룹 (Spring Boot on Windows) ── [추가]
resource "aws_lb_target_group" "backend_windows" {
  name     = "${var.project_name}-backend-win-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/v1/admin/health/readiness" # 어드민 모듈 헬스 체크 경로
    port                = "8081"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10 # Windows는 응답이 상대적으로 느릴 수 있어 timeout 여유 확보
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-backend-windows-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ────────────────────────────────────────────────────────────────────────────
# 타겟 그룹 인스턴스 연결
# ────────────────────────────────────────────────────────────────────────────

# 5-1. 프론트엔드 연결
resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.frontend.id
  port             = 80
}

# 5-2. Linux 백엔드 #1 연결
resource "aws_lb_target_group_attachment" "backend_1" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.backend_1.id
  port             = 8080
}

# 5-3. Linux 백엔드 #2 연결
resource "aws_lb_target_group_attachment" "backend_2" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.backend_2.id
  port             = 8080
}

# 5-4. Windows 백엔드 연결 ── [추가]
resource "aws_lb_target_group_attachment" "backend_windows" {
  target_group_arn = aws_lb_target_group.backend_windows.arn
  target_id        = aws_instance.backend_windows.id
  port             = 8081
}

# ────────────────────────────────────────────────────────────────────────────
# 리스너 및 라우팅 규칙
# ────────────────────────────────────────────────────────────────────────────

# 6. HTTP(80) 리스너 — 모든 HTTP 요청을 HTTPS(443)로 자동 리다이렉트
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 6-1. HTTPS(443) 리스너 — ACM 인증서 적용 및 기본 프론트엔드 전달
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  certificate_arn   = "arn:aws:acm:ap-northeast-2:802314158104:certificate/10c13f73-4bf5-4620-ae28-3e7cd6bb66eb"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# 6-2. Linux 백엔드 라우팅 규칙 (Path-based Routing): /api/* 요청은 백엔드로 전달
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn # HTTPS 리스너 ARN 참조
  priority     = 10                        # 기본 규칙보다 높은 우선순위로 설정

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/oauth2/authorization/*", "/login/oauth2/*"]
    }
  }
}

# 6-3. Windows 관리자 API 라우팅: /admin/* → Windows 백엔드 TG (priority 20)
resource "aws_lb_listener_rule" "admin_api" {
  listener_arn = aws_lb_listener.https.arn # HTTPS 리스너 ARN 참조
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_windows.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/admin/*"]
    }
  }
}

# 6-4. rookies.onde.click 도메인의 루트(/) 접속 시 /admin/login으로 리다이렉트
resource "aws_lb_listener_rule" "admin_root_redirect" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 3

  action {
    type = "redirect"

    redirect {
      path        = "/admin/login"
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = "443"
    }
  }

  condition {
    host_header {
      values = ["rookies.onde.click"]
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

