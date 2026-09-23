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
  description = "ECR image tag App Runner deploys."
  type        = string
  default     = "latest"
}

variable "app_runner_cpu" {
  description = "App Runner vCPU allocation."
  type        = string
  default     = "0.25 vCPU"
}

variable "app_runner_memory" {
  description = "App Runner memory allocation."
  type        = string
  default     = "0.5 GB"
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
