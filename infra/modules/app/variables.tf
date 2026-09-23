variable "name" {
  description = "Name prefix for every resource (also the ECS cluster and service name)."
  type        = string
}

variable "image_tag" {
  description = "ECR image tag the task definition runs."
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units (512 = 0.5 vCPU)."
  type        = number
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
}

variable "desired_count" {
  description = "Number of running tasks."
  type        = number
}

variable "domain_name" {
  description = "Public hostname for the app."
  type        = string
}

variable "hosted_zone_name" {
  description = "Route 53 public hosted zone that holds domain_name."
  type        = string
}

variable "vpc_id" {
  description = "VPC for the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the ALB and the ECS tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group for the ALB."
  type        = string
}

variable "app_security_group_id" {
  description = "Security group for the ECS tasks."
  type        = string
}

variable "secret_parameter_arns" {
  description = "SSM parameter ARNs keyed by env var name."
  type        = map(string)
}
