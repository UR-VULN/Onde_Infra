# Onde Infra

- SK쉴더스 루키즈 개발 5기 최종 프로젝트 LBS 기반 여행 예약 및 동행 커뮤니티 플랫폼 Onde 서비스를 AWS 기반으로 배포하기 위한 인프라 레포입니다. Terraform으로 AWS 리소스를 구성하고, Kubernetes manifest와 Argo CD를 통해 EC2 위에 프론트엔드/백엔드 애플리케이션을 배포하는 구조입니다.

현재 구조의 핵심은 다음과 같습니다.

Terraform: VPC, EC2, RDS, S3 기반 컨트롤러 설치
EC2: 프론트엔드, 백엔드 리소스 실행
SSM Parameter Store: DB, S3, IAM Role ARN, WAF ARN, ACM ARN 등 환경별 값을 저장
External Secrets Operator: SSM 값을 Kubernetes Secret으로 동기화
AWS Load Balancer Controller: Kubernetes Ingress를 보고 ALB 생성
Route53 + ACM: macta.store 도메인과 HTTPS 인증서 연결
통신 구조: 정적 파일은 프론트 Nginx가 서빙하고, 동적 API 호출은 ALB가 /api/v1 경로로 백엔드 서비스에 직접 전달

---

## 목차

- [프로젝트 개요](#프로젝트-개요)
- [주요 기능](#주요-기능)
- [리포지토리 구조](#리포지토리-구조)
- [로컬 개발 및 빌드](#로컬-개발-및-빌드)
- [배포 및 인프라](#배포-및-인프라)
- [환경 및 요구사항](#환경-및-요구사항)

---

## 전체 구조

---

## 프로젝트 개요

`Onde` 서비스의 인프라 관련 파일을 모아둔 저장소입니다. 여기에는 다음 항목이 포함됩니다:

- Kubernetes 매니페스트 (`manifests/`, `argocd/`)
- Docker 이미지 빌드 파일 (`docker/`)
- Terraform 인프라 코드 (`terraform/`)

이 저장소는 인프라 코드의 소스 오브젝트로서 CI/CD 파이프라인(예: Argo CD, GitHub Actions)에서 사용됩니다.

## 주요 기능

- LBS 기반 서비스 아키텍처 문서화 및 환경 구성
- ALB/Ingress, External Secrets, Service Account 등 K8s 관련 매니페스트 제공
- Terraform으로 AWS 리소스(EC2, RDS, ElastiCache, S3 등) 프로비저닝
- Dockerfile 기반 프론트엔드/백엔드 이미지 빌드

## 리포지토리 구조

- `argocd/` - Argo CD 앱 매니페스트
- `docker/` - `backend`, `frontend` Dockerfile
- `manifests/` - Kubernetes 배포/서비스 매니페스트
- `terraform/` - AWS 인프라 구성(EC2, EKS, RDS, VPC 등)
- `README.md` - 이 파일

자세한 파일 위치는 아래를 확인하세요.

---

## 로컬 개발 및 빌드

프론트엔드와 백엔드 각각 Docker를 사용해 빌드 가능합니다.

Prerequisites:

- Docker
- Terraform (인프라 작업 시)
- kubectl (클러스터 디버깅 시)

예: 프론트엔드 이미지 빌드

```bash
cd docker/frontend
docker build -t onde-frontend:local .

# 백엔드 이미지 빌드
cd ../../docker/backend
docker build -t onde-backend:local .
```

테라폼 예시(초기화 및 플랜):

```bash
cd terraform
terraform init
terraform plan
```

---

## 배포 및 인프라

- Kubernetes 매니페스트는 `manifests/`에 보관됩니다. Argo CD를 사용하면 `argocd/` 아래 앱 매니페스트로 자동 배포됩니다.
- Terraform으로 AWS 리소스를 생성한 후 EKS 클러스터에 매니페스트를 적용하세요.

간단한 배포 흐름 예:

1. Terraform으로 네트워크/클러스터/기타 리소스 프로비저닝
2. 컨테이너 이미지를 ECR에 푸시
3. Argo CD가 `argocd/` 앱을 통해 매니페스트를 동기화

---

## 환경 및 요구사항

- Node.js / npm (프론트엔드 개발)
- Java / Maven 또는 Gradle (백엔드 빌드)
- Docker
- Terraform
- AWS 계정 및 권한

---
