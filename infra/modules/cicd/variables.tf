variable "name" {
  description = "Name prefix for every resource."
  type        = string
}

variable "github_repository" {
  description = "owner/repo allowed to assume the deploy role."
  type        = string
}

variable "github_branch" {
  description = "Branch whose workflow runs may assume the deploy role."
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider, or look up the account's existing one."
  type        = bool
}

variable "ecr_repository_arn" {
  description = "ECR repository the deploy role may push to."
  type        = string
}
