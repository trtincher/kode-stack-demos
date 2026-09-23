output "ecr_repository_url" {
  description = "docker tag/push target."
  value       = module.app.ecr_repository_url
}

output "deploy_role_arn" {
  description = "Set as the GitHub repo variable AWS_DEPLOY_ROLE_ARN."
  value       = module.cicd.deploy_role_arn
}

output "service_url" {
  description = "Public URL of the app (null until create_service = true)."
  value       = module.app.service_url
}

output "secret_parameter_names" {
  description = "SSM parameters App Runner injects."
  value       = module.data.secret_parameter_names
}

output "database_endpoint" {
  description = "RDS endpoint (private)."
  value       = module.data.database_endpoint
}
