# ────────────────────────────────────────────────────────────────────────────
<<<<<<< Updated upstream
# redis 보안 그룹
# ────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow Redis traffic from EKS nodes"

#   # 이 안에 인바운드 규칙을 바로 넣는 것이 관리하기 편합니다
#   ingress {
#     from_port       = 6379
#     to_port         = 6379
#     protocol        = "tcp"
#     security_groups = ["sg-0b5a7d2c4ba3cc669"] # 백엔드 워커 노드 sg
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# ────────────────────────────────────────────────────────────────────────────
=======
>>>>>>> Stashed changes
# redis 서브넷
# ────────────────────────────────────────────────────────────────────────────
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = aws_subnet.redis[*].id

#   tags = {
#     Name = "${var.project_name}-redis-subnet-group"
#   }
# }

# # ────────────────────────────────────────────────────────────────────────────
# # redis main
# # ────────────────────────────────────────────────────────────────────────────
# resource "aws_elasticache_cluster" "main" {
#   cluster_id           = "${var.project_name}-redis"
#   engine               = "redis"
#   node_type            = "cache.t3.micro" # 프로젝트용 저사양 선택
#   num_cache_nodes      = 1
#   parameter_group_name = "default.redis7" # 엔진 버전 확인
#   port                 = 6379
#   subnet_group_name    = aws_elasticache_subnet_group.main.name
#   security_group_ids   = [aws_security_group.redis.id]

#   tags = {
#     Name = "${var.project_name}-redis"
#   }
# }