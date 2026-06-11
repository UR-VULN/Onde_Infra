# RDS security group
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "RDS security group allowing access from backend EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow backend EC2 access to MariaDB"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ec2.id]
  }

  ingress {
    description     = "Allow Windows backend EC2 access to MariaDB"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.windows_ec2.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# 1. RDS가 배치될 서브넷 그룹 정의 (2개 이상의 AZ에 걸친 DB 서브넷 사용)
resource "aws_db_subnet_group" "database" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id # aws_subnet.database는 aws_subnet 리소스의 리스트로 가정

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. RDS MariaDB Option Group 생성 (감사 로그 활성화)
resource "aws_db_option_group" "mariadb_audit" {
  name                     = "${var.project_name}-mariadb1011-audit-og"
  option_group_description = "Option group with MariaDB Audit Plugin"
  engine_name              = "mariadb"
  major_engine_version     = "10.11"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT,QUERY"
    }

    option_settings {
      name  = "SERVER_AUDIT_EXCL_USERS"
      value = "rdsadmin"
    }
  }

  tags = {
    Name    = "${var.project_name}-mariadb1011-audit-og"
    Project = var.project_name
  }
}

# 3. RDS MariaDB 인스턴스 생성
resource "aws_db_instance" "main" {
  allocated_storage     = 20
  max_allocated_storage = 100 # 스토리지 오토스케일링
  engine                = "mariadb"
  engine_version        = "10.11"
  instance_class        = var.db_instance_class
  apply_immediately     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password # sensitive 변수 사용

  parameter_group_name   = "default.mariadb10.11"
  option_group_name      = aws_db_option_group.mariadb_audit.name
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true  # 프로젝트 종료 후 삭제 편의를 위함
  multi_az            = false # 비용 절감을 위해 단일 AZ (운영 시 true 권장)
  publicly_accessible = false # 외부 접근 차단 (보안 핵심)

  # 자동 백업 설정 (7일 보관)
  backup_retention_period = 7
  backup_window           = "17:00-18:00" # KST 오전 2시 - 3시 (UTC 17:00-18:00)
  maintenance_window      = "Sun:18:00-Sun:19:00" # KST 일요일 오전 3시 - 4시 (UTC 18:00-19:00)

  # CloudWatch로 감사(Audit) 및 에러 로그 자동 연동
  enabled_cloudwatch_logs_exports = ["audit", "error"]

  # Storage encryption uses the AWS managed/default key.
  storage_encrypted = true

  tags = {
    Name = "${var.project_name}-rds"
  }
}
