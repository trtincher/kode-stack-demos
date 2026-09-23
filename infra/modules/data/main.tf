# PostgreSQL and Valkey, plus the three SSM parameters App Runner injects as
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

# ElastiCache Serverless Valkey: ~$6-9/month at the 100 MB floor, against
# ~$11.70/month for a cache.t4g.micro node that also needs patching. Serverless
# requires TLS, hence the rediss:// scheme below.
resource "aws_elasticache_serverless_cache" "this" {
  name                 = var.name
  engine               = "valkey"
  major_engine_version = "8"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.cache_security_group_id]

  cache_usage_limits {
    data_storage {
      maximum = 1
      unit    = "GB"
    }

    ecpu_per_second {
      maximum = 5000
    }
  }
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
  value = "rediss://${aws_elasticache_serverless_cache.this.endpoint[0].address}:${aws_elasticache_serverless_cache.this.endpoint[0].port}"
}

resource "aws_ssm_parameter" "secret_key_base" {
  name  = "/${var.name}/SECRET_KEY_BASE"
  type  = "SecureString"
  value = random_password.secret_key_base.result
}
