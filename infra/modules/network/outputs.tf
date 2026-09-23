output "vpc_id" {
  description = "VPC id."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet ids, one per AZ."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet ids, one per AZ (ALB and ECS tasks)."
  value       = aws_subnet.public[*].id
}

output "alb_security_group_id" {
  description = "Security group for the ALB."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group for the ECS tasks."
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Security group for RDS."
  value       = aws_security_group.database.id
}

output "cache_security_group_id" {
  description = "Security group for ElastiCache."
  value       = aws_security_group.cache.id
}
