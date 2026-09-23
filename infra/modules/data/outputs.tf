output "secret_parameter_arns" {
  description = "SSM parameter ARNs keyed by the env var App Runner injects them as."
  value = {
    DATABASE_URL    = aws_ssm_parameter.database_url.arn
    REDIS_URL       = aws_ssm_parameter.redis_url.arn
    SECRET_KEY_BASE = aws_ssm_parameter.secret_key_base.arn
  }
}

output "secret_parameter_names" {
  description = "SSM parameter names, for the README and for eyeballing in the console."
  value = [
    aws_ssm_parameter.database_url.name,
    aws_ssm_parameter.redis_url.name,
    aws_ssm_parameter.secret_key_base.name,
  ]
}

output "database_endpoint" {
  description = "RDS endpoint (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "cache_endpoint" {
  description = "ElastiCache Serverless endpoint."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}
