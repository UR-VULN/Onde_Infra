variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 이름 prefix)"
  type        = string
  default     = "onde"
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ── S3 ────────────────────────────────────────────────────────────────────
variable "s3_image_bucket_name" {
  description = "이미지 저장용 S3 버킷 이름"
  type        = string
  default     = "onde-travel-image-bucket"
}

variable "s3_eticket_bucket_name" {
  description = "E-Ticket 저장용 S3 버킷 이름"
  type        = string
  default     = "onde-eticket-bucket"
}

# ── VPC ────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록 (ALB 배치)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록 (EC2 노드 배치)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "가용 영역 목록 (서브넷 수와 일치해야 함)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"] # 가용성을 나누기 위한 
}

# ── RDS ────────────────────────────────────────────────────────────────────

variable "database_subnet_cidrs" {
  description = "데이터베이스 서브넷 CIDR 목록 (RDS)"
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.200.0/24"] # 기존 private과 겹치지 않는 대역
}

variable "db_instance_class" {
  description = "RDS 인스턴스 타입"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "초기 생성할 데이터베이스 이름"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "RDS 마스터 사용자명"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS 마스터 비밀번호 (GitHub Secrets Manager에 저장)"
  type        = string
  sensitive   = true # terraform output 및 로그에 출력되지 않음
}

# ── SNS ────────────────────────────────────────────────────────────────────
variable "operator_email" {
  description = "운영자 알림 수신 이메일 주소"
  type        = string
  default     = "your-email@example.com" # 실제 이메일로 교체 필요
}
