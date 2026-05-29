# ────────────────────────────────────────────────────────────────────────────
# Application Load Balancer (ALB)
# ────────────────────────────────────────────────────────────────────────────

# 1. ALB 본체 생성 (Public Subnet에 배치하여 외부 인터넷 노출)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # Internet-facing # 외부에서 접근 가능하도록 설정
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id # 모든 퍼블릭 서브넷에 가용성 확보

  enable_deletion_protection = false # 테스트 환경이므로 삭제 보호 비활성화 # prod 환경에서는 true 권장

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. 프론트엔드 타겟 그룹 (Nginx 서버 묶음)
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-frontend-tg"
  port     = 80 # Nginx 기본 HTTP 포트
  protocol = "HTTP" # ALB → Nginx 간 통신은 HTTP로 설정 (HTTPS는 ALB에서 Terminate 예정)
  vpc_id   = aws_vpc.main.id # 타겟 그룹은 VPC에 종속적이므로 VPC ID 필요 # frontend / backend 

  # 헬스 체크 설정: Nginx의 루트(/) 경로 응답 확인
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

# 3. 타겟 그룹에 프론트엔드 인스턴스 연결 (ec2.tf의 frontend 인스턴스)
resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.frontend.arn # 타겟 그룹 ARN 참조 
  target_id        = aws_instance.frontend.id # 프론트엔드 EC2 인스턴스 ID 참조
  port             = 80
}

# 4. HTTP(80) 리스너: 현재 테스트를 위해 직접 포워딩 설정
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  /* 
  # [고도화 단계] 나중에 HTTPS(443) 인증서가 준비되면 아래 리다이렉트 코드로 교체하세요.
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  */
}

/*
# ────────────────────────────────────────────────────────────────────────────
# [미래 대비] HTTPS(443) 리스너 - ACM 인증서 준비 시 주석 해제 후 사용
# ────────────────────────────────────────────────────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "<ACM_CERTIFICATE_ARN_입력>" # 여기에 ACM ARN 주입

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
*/
