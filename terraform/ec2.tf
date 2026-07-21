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
resource "aws_iam_role_policy" "ec2_secretsmanager_policy" {
  name = "${var.project_name}-ec2-secretsmanager-policy"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadBackendSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:onde-project/backend-*"
      }
    ]
  })
}

# S3 버킷 접근 권한 (이미지 업로드 / e-ticket 생성)
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_image_bucket_name}/*"
        ]
      }
    ]
  })
}
#윈도우용 버킷
resource "aws_iam_role_policy" "ec2_deploy_s3_policy" {
  name = "${var.project_name}-ec2-deploy-s3-policy"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.project_name}-deploy-artifacts/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 security groups
# ────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "frontend_ec2" {
  name        = "${var.project_name}-sg-frontend"
  description = "Frontend EC2 security group for Nginx and ALB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ALB to connect to frontend HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow ALB to connect to frontend HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}

resource "aws_security_group" "backend_ec2" {
  name        = "${var.project_name}-sg-backend"
  description = "Backend EC2 security group for API servers and database/cache access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow frontend EC2 to connect to backend API"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_ec2.id]
  }

  ingress {
    description     = "Allow ALB to connect to backend API"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

# ────────────────────────────────────────────────────────────────────────────
# EC2 Instances (Frontend & Backend)
# ────────────────────────────────────────────────────────────────────────────

# 1. Frontend EC2 (Nginx) - 퍼블릭 서브넷 배치, ALB를 통해서만 접근
resource "aws_instance" "frontend" {
  ami                    = var.ubuntu_ami_id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public[0].id # 첫 번째 퍼블릭 서브넷
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.frontend_ec2.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg awscli

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker

    # SSM Agent 설치 및 활성화 보장
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    EOF
  tags = {
    Name = "${var.project_name}-frontend"
  }
}

# 2. Backend EC2 #1 (Spring Boot) - 첫 번째 프라이빗 서브넷
resource "aws_instance" "backend_1" {
  ami                    = var.ubuntu_ami_id
  instance_type          = "t3.small"               # Java 애플리케이션 권장 사양
  subnet_id              = aws_subnet.private[0].id # 첫 번째 프라이빗 서브넷
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]

  user_data = <<-EOF
  #!/bin/bash
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg awscli

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker

  # SSM Agent 설치 및 활성화 보장
  snap install amazon-ssm-agent --classic
  systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
  systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF
  tags = {
    Name = "${var.project_name}-backend-1"
  }
}

# 3. Backend EC2 #2 (Spring Boot) - 두 번째 프라이빗 서브넷 (HA 분산)
# resource "aws_instance" "backend_2" {
#   ami                    = var.ubuntu_ami_id
#   instance_type          = "t3.small"
#   subnet_id              = aws_subnet.private[1].id # 두 번째 프라이빗 서브넷
#   iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
#   vpc_security_group_ids = [aws_security_group.backend_ec2.id]

#   user_data = <<-EOF
#   #!/bin/bash
#   apt-get update -y
#   apt-get install -y ca-certificates curl gnupg awscli

#   install -m 0755 -d /etc/apt/keyrings
#   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#   chmod a+r /etc/apt/keyrings/docker.gpg
#   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
#   https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
#   | tee /etc/apt/sources.list.d/docker.list > /dev/null

#   apt-get update -y
#   apt-get install -y docker-ce docker-ce-cli containerd.io
#   systemctl enable docker
#   systemctl start docker

#   # SSM Agent 설치 및 활성화 보장
#   snap install amazon-ssm-agent --classic
#   systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
#   systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
#   EOF
#   tags = {
#     Name = "${var.project_name}-backend-2"
#   }
# }

# 4. Backend EC2 (Window 서버)

# Windows Server용 보안 그룹 (RDP 접속 및 백엔드 API 연동 허용)
resource "aws_security_group" "windows_ec2" {
  name        = "${var.project_name}-sg-windows"
  description = "Security group for Windows Backend EC2 allowing RDP and backend API access"
  vpc_id      = aws_vpc.main.id


  # 프론트엔드 EC2가 백엔드 8081 포트로 접속하는 것 허용
  ingress {
    description     = "Allow frontend EC2 access to backend"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_ec2.id]
  }

  # ALB가 백엔드 8081 포트로 접속하는 것 허용
  ingress {
    description     = "Allow ALB to connect to backend admin"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # 아웃바운드 전체 허용
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-windows-sg"
  }
}

# Windows Server 2019 인스턴스 생성
resource "aws_instance" "backend_windows" {
  ami                    = var.windows_ami_id
  instance_type          = "t3.medium" # Windows Server 구동을 위한 최소 권장 스펙
  subnet_id              = aws_subnet.private[0].id # 👈 아키텍처 다이어그램에 따라 프라이빗 서브넷에 배치
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.windows_ec2.id]


  user_data = <<-EOF
    <powershell>
    # Java 17 설치 (Amazon Corretto)
    Invoke-WebRequest `
      -Uri "https://corretto.aws/downloads/latest/amazon-corretto-17-x64-windows-jdk.zip" `
      -OutFile "$env:TEMP\jdk17.zip"
    Expand-Archive "$env:TEMP\jdk17.zip" -DestinationPath "C:\Program Files\Java" -Force
    $extracted = Get-ChildItem "C:\Program Files\Java" | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    Rename-Item -Path $extracted.FullName -NewName "jdk-17" -Force

    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "Machine")
    [System.Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\Program Files\Java\jdk-17\bin", "Machine")

    # 앱 디렉토리 생성
    New-Item -ItemType Directory -Force -Path C:\app

    # SSM Agent 활성화 및 시작 보장
    Set-Service -Name "AmazonSSMAgent" -StartupType Automatic
    Start-Service -Name "AmazonSSMAgent"
    </powershell>
    EOF
  tags = {
    Name = "${var.project_name}-backend-windows"
  }
}

