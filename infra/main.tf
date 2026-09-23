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
  image_tag             = var.image_tag
  cpu                   = 512  # 0.5 vCPU
  memory                = 1024 # 1 GB: Puma + Sidekiq in one task
  desired_count         = var.desired_count
  domain_name           = var.domain_name
  hosted_zone_name      = var.hosted_zone_name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  app_security_group_id = module.network.app_security_group_id
  secret_parameter_arns = merge(
    module.data.secret_parameter_arns,
    var.anthropic_key_in_ssm ? { ANTHROPIC_API_KEY = data.aws_ssm_parameter.anthropic_api_key[0].arn } : {},
  )
}

module "cicd" {
  source = "./modules/cicd"

  name                        = var.name
  github_repository           = var.github_repository
  github_branch               = var.github_branch
  create_github_oidc_provider = var.create_github_oidc_provider
  ecr_repository_arn          = module.app.ecr_repository_arn
  ecs_service_arn             = module.app.service_arn
  ecs_task_role_arns          = module.app.task_role_arns
}

# The assistant demo's model key. Put out-of-band so it never touches state:
#   aws ssm put-parameter --name /kode-stack-demos/ANTHROPIC_API_KEY --type SecureString --value ...
# then apply with -var anthropic_key_in_ssm=true. with_decryption=false keeps
# the ciphertext (not the key) in state; ECS only needs the ARN.
data "aws_ssm_parameter" "anthropic_api_key" {
  count           = var.anthropic_key_in_ssm ? 1 : 0
  name            = "/${var.name}/ANTHROPIC_API_KEY"
  with_decryption = false
}
