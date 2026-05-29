# # ────────────────────────────────────────────────────────────────────────────
# # redis 서브넷
# # ────────────────────────────────────────────────────────────────────────────
# resource "aws_elasticache_subnet_group" "main" {
#   name       = "${var.project_name}-redis-subnet-group"
#   subnet_ids = aws_subnet.redis[*].id

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