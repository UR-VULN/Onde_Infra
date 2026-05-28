# Onde Infra

- LBS 기반 여행 예약 및 동행 커뮤니티 플랫폼의 인프라 코드, 매니페스트, 도커 파일, 테라폼 구성 등을 모아둔 저장소입니다.

---

## 목차

- [프로젝트 개요](#프로젝트-개요)
- [주요 기능](#주요-기능)
- [리포지토리 구조](#리포지토리-구조)
- [로컬 개발 및 빌드](#로컬-개발-및-빌드)
- [배포 및 인프라](#배포-및-인프라)
- [환경 및 요구사항](#환경-및-요구사항)

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
- Terraform으로 AWS 리소스(EC2, EKS, RDS, ElastiCache, S3, ECR 등) 프로비저닝
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
