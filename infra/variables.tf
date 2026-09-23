variable "region" {
  description = "AWS region for the whole stack."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for every resource."
  type        = string
  default     = "kode-stack-demos"
}

variable "github_repository" {
  description = "owner/repo allowed to assume the CI role."
  type        = string
  default     = "trtincher/kode-stack-demos"
}

variable "github_branch" {
  description = "Branch whose workflow runs may assume the CI role."
  type        = string
  default     = "main"
}

variable "create_github_oidc_provider" {
  description = <<-EOT
    Create the GitHub OIDC provider. Set to false if the account already has one
    (check with: aws iam list-open-id-connect-providers) — a duplicate fails apply.
  EOT
  type        = bool
  default     = true
}

variable "image_tag" {
  description = "ECR image tag the ECS task definition runs."
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Number of running ECS tasks."
  type        = number
  default     = 1
}

variable "domain_name" {
  description = "Public hostname for the app (gets an ACM cert and an A alias to the ALB)."
  type        = string
  default     = "demos.travis-tincher.com"
}

variable "hosted_zone_name" {
  description = "Route 53 public hosted zone that holds domain_name."
  type        = string
  default     = "travis-tincher.com"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB (gp3 minimum is 20)."
  type        = number
  default     = 20
}

variable "anthropic_key_in_ssm" {
  description = "Set true once /<name>/ANTHROPIC_API_KEY exists in SSM; wires it into the task as a secret."
  type        = bool
  default     = false
}
