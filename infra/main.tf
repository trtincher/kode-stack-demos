module "network" {
  source = "./modules/network"

  name = var.name
}

module "data" {
  source = "./modules/data"

  name                       = var.name
  private_subnet_ids         = module.network.private_subnet_ids
  database_security_group_id = module.network.database_security_group_id
  cache_security_group_id    = module.network.cache_security_group_id
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
}

module "app" {
  source = "./modules/app"

  name                  = var.name
  create_service        = var.create_service
  image_tag             = var.image_tag
  cpu                   = var.app_runner_cpu
  memory                = var.app_runner_memory
  private_subnet_ids    = module.network.private_subnet_ids
  app_security_group_id = module.network.app_security_group_id
  secret_parameter_arns = module.data.secret_parameter_arns
}

module "cicd" {
  source = "./modules/cicd"

  name                        = var.name
  github_repository           = var.github_repository
  github_branch               = var.github_branch
  create_github_oidc_provider = var.create_github_oidc_provider
  ecr_repository_arn          = module.app.ecr_repository_arn
}
