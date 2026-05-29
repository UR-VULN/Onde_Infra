# Security Groups for EC2-based deployment
# ALB, Frontend EC2, Backend EC2, RDS, Redis

resource "aws_security_group" "alb" {       # ALB 방화벽 
  name        = "${var.project_name}-sg-alb"
  # ALB는 인터넷에서 들어오는 HTTP/HTTPS 트래픽을 허용하도록 설정
  description = "ALB security group for public HTTP/HTTPS access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from internet"
    from_port        = 80       # ALB는 80번 포트로 인터넷에서 들어오는 트래픽을 허용
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # 인터넷에서 모든 IPv4 주소 허용
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from internet"
    from_port        = 443  # ALB는 443번 포트로 인터넷에서 들어오는 트래픽을 허용
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # 인터넷에서 모든 IPv4 주소 허용
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all outbound traffic" # ALB에서 나가는 트래픽은 모두 허용 (예: 프론트엔드 EC2로의 트래픽)
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "frontend_ec2" { # 프론트엔드 EC2 방화벽
  name        = "${var.project_name}-sg-frontend"
  # 프론트엔드 EC2는 ALB에서 들어오는 HTTP/HTTPS 트래픽만 허용하도록 설정
  description = "Frontend EC2 security group for Nginx and ALB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description              = "Allow ALB to connect to frontend HTTP"
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
  }

  ingress {
    description              = "Allow ALB to connect to frontend HTTPS"
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic" # 프론트엔드 EC2에서 나가는 트래픽은 모두 허용 (예: 백엔드 EC2로의 트래픽)
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
  # 백엔드 EC2는 프론트엔드 EC2에서 들어오는 트래픽과 RDS/Redis로 나가는 트래픽을 허용하도록 설정
  description = "Backend EC2 security group for API servers and database/cache access"
  vpc_id      = aws_vpc.main.id

  ingress { # 백엔드 EC2는 프론트엔드 EC2에서 8080번 포트로 들어오는 트래픽을 허용하도록 설정 (예: Spring Boot API 서버)
    description     = "Allow frontend EC2 to connect to backend API"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_ec2.id] # 프론트엔드 EC2의 보안 그룹을 참조하여 허용
  }

  egress {
    description = "Allow all outbound traffic" # 백엔드 EC2에서 나가는 트래픽은 모두 허용 (예: RDS/Redis로의 트래픽)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

resource "aws_security_group" "rds" { # RDS 방화벽
  name        = "${var.project_name}-sg-rds"
  description = "RDS security group allowing access from backend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow backend EC2 access to MySQL" # RDS는 3306번 포트로 백엔드 EC2에서 들어오는 트래픽을 허용하도록 설정
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ec2.id] # 백엔드 EC2의 보안 그룹을 참조하여 허용
  }

  egress {
    description = "Allow all outbound traffic" # RDS에서 나가는 트래픽은 모두 허용 (예: 백엔드 EC2로의 트래픽)
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-sg-redis"
  description = "Redis security group allowing access from backend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow backend EC2 access to Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ec2.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}
