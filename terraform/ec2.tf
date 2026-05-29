# ────────────────────────────────────────────────────────────────────────────
# IAM Role & Instance Profile for SSM (Keyless Access)
# ────────────────────────────────────────────────────────────────────────────

# EC2 인스턴스가 SSM 서비스를 사용할 수 있도록 허용하는 역할
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

# AWS 관리형 정책 연결: SSM Session Manager 접속에 필수적인 권한
resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # SSM 세션 매니저를 통한 인스턴스 관리 권한
}

# EC2 인스턴스에 부착할 프로파일
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ────────────────────────────────────────────────────────────────────────────
# AMI Data Source (최신 Amazon Linux 2023 자동 조회)
# ────────────────────────────────────────────────────────────────────────────

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 Instances (Frontend & Backend)
# ────────────────────────────────────────────────────────────────────────────

# 1. Frontend EC2 (Nginx) - 프라이빗 서브넷 배치, ALB를 통해서만 접근
resource "aws_instance" "frontend" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public[0].id # 첫 번째 퍼블릭 서브넷
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.frontend_ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable --now nginx
              EOF

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

# 2. Backend EC2 #1 (Spring Boot) - 첫 번째 프라이빗 서브넷
resource "aws_instance" "backend_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"               # Java 애플리케이션 권장 사양
  subnet_id              = aws_subnet.private[0].id # 첫 번째 프라이빗 서브넷
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y openjdk-17-jdk
              EOF

  tags = {
    Name = "${var.project_name}-backend-1"
  }
}

# 3. Backend EC2 #2 (Spring Boot) - 두 번째 프라이빗 서브넷 (HA 분산)
resource "aws_instance" "backend_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private[1].id # 두 번째 프라이빗 서브넷
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y java-17-amazon-corretto-devel
              EOF

  tags = {
    Name = "${var.project_name}-backend-2"
  }
}
