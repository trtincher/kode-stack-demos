# PostgreSQL and Valkey, plus the three SSM parameters ECS injects as
# secrets. Terraform generates the credentials, so the operator sets nothing by
# hand: the database password and SECRET_KEY_BASE never leave state and SSM.

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
}

resource "random_password" "database" {
  length  = 32
  special = false # keeps the value safe to drop straight into a URL
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  db_name  = "kode_stack_demos_production"
  username = "kode_stack_demos"
  password = random_password.database.result

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  multi_az               = false

  # Demo posture: cheap, disposable, no surprises at destroy time.
  backup_retention_period     = 1
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  deletion_protection         = false
  skip_final_snapshot         = true
  apply_immediately           = true
}

# One Valkey 8 node (cache.t4g.micro, ~$11.70/month). Not ElastiCache
# Serverless: serverless runs in cluster mode and Sidekiq does not support
# Redis Cluster (multi-key MULTI blocks fail with CROSSSLOT). TLS stays on,
# hence the rediss:// scheme below.
resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.name
  description          = "${var.name} Sidekiq + Action Cable"
  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 1
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.cache_security_group_id]

  automatic_failover_enabled = false
  multi_az_enabled           = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  apply_immediately          = true
  snapshot_retention_limit   = 0
}

resource "random_password" "secret_key_base" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.name}/DATABASE_URL"
  type  = "SecureString"
  value = "postgres://${aws_db_instance.this.username}:${random_password.database.result}@${aws_db_instance.this.endpoint}/${aws_db_instance.this.db_name}"
}

resource "aws_ssm_parameter" "redis_url" {
  name  = "/${var.name}/REDIS_URL"
  type  = "SecureString"
  value = "rediss://${aws_elasticache_replication_group.this.primary_endpoint_address}:${aws_elasticache_replication_group.this.port}"
}

resource "aws_ssm_parameter" "secret_key_base" {
  name  = "/${var.name}/SECRET_KEY_BASE"
  type  = "SecureString"
  value = random_password.secret_key_base.result
}
