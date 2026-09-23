output "ecr_repository_arn" {
  description = "ECR repository ARN (CI pushes here)."
  value       = aws_ecr_repository.this.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL, for docker tag/push."
  value       = aws_ecr_repository.this.repository_url
}

output "service_url" {
  description = "Public App Runner URL (null until the second apply)."
  value       = var.create_service ? "https://${aws_apprunner_service.this[0].service_url}" : null
}

output "service_arn" {
  description = "App Runner service ARN (null until the second apply)."
  value       = var.create_service ? aws_apprunner_service.this[0].arn : null
}
