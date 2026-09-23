output "deploy_role_arn" {
  description = "Role ARN for aws-actions/configure-aws-credentials (repo variable AWS_DEPLOY_ROLE_ARN)."
  value       = aws_iam_role.deploy.arn
}
