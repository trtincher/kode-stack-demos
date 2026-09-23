variable "name" {
  description = "Name prefix for every resource."
  type        = string
}

variable "create_service" {
  description = "Create the App Runner service. False on the first apply, before an image exists in ECR."
  type        = bool
}

variable "image_tag" {
  description = "ECR image tag App Runner deploys."
  type        = string
}

variable "cpu" {
  description = "App Runner vCPU allocation."
  type        = string
}

variable "memory" {
  description = "App Runner memory allocation."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets for the VPC connector."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group for the VPC connector ENIs."
  type        = string
}

variable "secret_parameter_arns" {
  description = "SSM parameter ARNs keyed by env var name."
  type        = map(string)
}
