# 1. RDS가 배치될 서브넷 그룹 정의 (2개 이상의 AZ에 걸친 DB 서브넷 사용)
resource "aws_db_subnet_group" "database" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id # aws_subnet.database는 aws_subnet 리소스의 리스트로 가정

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. RDS MySQL 인스턴스 생성
resource "aws_db_instance" "main" {
  allocated_storage      = 20
  max_allocated_storage  = 100 # 스토리지 오토스케일링
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class 
  apply_immediately      = true
  
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password # sensitive 변수 사용

  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  skip_final_snapshot    = true # 프로젝트 종료 후 삭제 편의를 위함
  multi_az               = false # 비용 절감을 위해 단일 AZ (운영 시 true 권장)
  publicly_accessible    = false # 외부 접근 차단 (보안 핵심) 나중에 false로 수정

  tags = {
    Name = "${var.project_name}-rds"
  }
}