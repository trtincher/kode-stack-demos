variable "name" {
  description = "Name prefix for every resource."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets for the database and cache."
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Security group to attach to RDS."
  type        = string
}

variable "cache_security_group_id" {
  description = "Security group to attach to ElastiCache."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS storage in GB."
  type        = number
}
