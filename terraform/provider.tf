terraform {
<<<<<<< Updated upstream
  required_version = ">= 1.3.0"

  required_providers {
=======
  required_version = ">= 1.3.0"       # Terraform 실행 버전 최소값 지정 

  required_providers {      #  사용할 provider 이름과 버전 범위
>>>>>>> Stashed changes
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
<<<<<<< Updated upstream
    tls = {
=======
    tls = {           # tls provider
>>>>>>> Stashed changes
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

<<<<<<< Updated upstream
provider "aws" {
  region = var.aws_region

  default_tags {
=======
provider "aws" {  # AWS와 통신하기 위한 설정 
  region = var.aws_region   # 리전 설정 - variables.tf에서 변수 설정 

  default_tags {    # Terraform으로 만든느 모든 AWS 자원에 자동 태그 붙여줌 
>>>>>>> Stashed changes
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
<<<<<<< Updated upstream
}
