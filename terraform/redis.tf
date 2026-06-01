# ────────────────────────────────────────────────────────────────────────────
# redis 서브넷
# ────────────────────────────────────────────────────────────────────────────
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-database-group"
  subnet_ids = aws_subnet.database[*].id # aws_subnet.redis는 aws_subnet 리소스의 리스트로 가정

  tags = {
    Name = "${var.project_name}-database-group"
  }
}

# ────────────────────────────────────────────────────────────────────────────
# redis main
# ────────────────────────────────────────────────────────────────────────────
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis replication group for ${var.project_name}"

  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  # at_rest_encryption_enabled = true  # Provider 버전 이슈로 비활성화
  # transit_encryption_enabled = true

  tags = {
    Name = "${var.project_name}-redis"
  }
}
