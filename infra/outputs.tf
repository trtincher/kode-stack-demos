output "ecr_repository_url" {
  description = "docker tag/push target."
  value       = module.app.ecr_repository_url
}

output "deploy_role_arn" {
  description = "Set as the GitHub repo variable AWS_DEPLOY_ROLE_ARN."
  value       = module.cicd.deploy_role_arn
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.app.cluster_name
}

output "service_name" {
  description = "ECS service name."
  value       = module.app.service_name
}

output "alb_dns_name" {
  description = "ALB DNS name (the domain aliases to it)."
  value       = module.app.alb_dns_name
}

output "service_url" {
  description = "Public URL of the app."
  value       = module.app.service_url
}

output "database_endpoint" {
  description = "RDS endpoint (private)."
  value       = module.data.database_endpoint
}

output "cache_endpoint" {
  description = "Valkey primary endpoint (private)."
  value       = module.data.cache_endpoint
}
