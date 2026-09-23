output "ecr_repository_arn" {
  description = "ECR repository ARN (CI pushes here)."
  value       = aws_ecr_repository.this.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL, for docker tag/push."
  value       = aws_ecr_repository.this.repository_url
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ECS service ARN."
  value       = aws_ecs_service.this.id
}

output "task_role_arns" {
  description = "Execution + task role ARNs (the deploy role may pass these)."
  value       = [aws_iam_role.execution.arn, aws_iam_role.task.arn]
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.this.dns_name
}

output "service_url" {
  description = "Public URL of the app."
  value       = "https://${var.domain_name}"
}
