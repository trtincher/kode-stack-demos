# ECR + App Runner. App Runner pulls the image from ECR, injects the three SSM
# secrets as env vars, and reaches RDS and Valkey through a VPC connector.
#
# Two-phase apply: App Runner refuses to create a service whose image does not
# exist yet, so the first apply runs with create_service = false (ECR, roles,
# connector only), CI or the operator pushes an image, and the second apply
# flips create_service = true.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "MUTABLE" # :latest is re-pushed on every deploy
  force_delete         = true      # throwaway demo stack

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# Lets the App Runner service pull from ECR.
resource "aws_iam_role" "access" {
  name = "${var.name}-apprunner-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "access_ecr" {
  role       = aws_iam_role.access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# The running container's role: read exactly the three SSM secrets.
resource "aws_iam_role" "instance" {
  name = "${var.name}-apprunner-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "tasks.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "instance_ssm" {
  name = "read-app-secrets"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = values(var.secret_parameter_arns)
      },
      {
        # SecureString parameters use the AWS-managed SSM key.
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "arn:aws:kms:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
      }
    ]
  })
}

resource "aws_apprunner_vpc_connector" "this" {
  vpc_connector_name = var.name
  subnets            = var.private_subnet_ids
  security_groups    = [var.app_security_group_id]
}

resource "aws_apprunner_auto_scaling_configuration_version" "this" {
  auto_scaling_configuration_name = var.name
  min_size                        = 1
  max_size                        = 1 # one box: the Sidekiq worker rides inside it
  max_concurrency                 = 100
}

resource "aws_apprunner_service" "this" {
  count = var.create_service ? 1 : 0

  service_name                   = var.name
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.this.arn

  source_configuration {
    # A push of :latest to ECR redeploys; CI only has to push.
    auto_deployments_enabled = true

    authentication_configuration {
      access_role_arn = aws_iam_role.access.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
      image_repository_type = "ECR"

      image_configuration {
        port = "8080"

        runtime_environment_variables = {
          RAILS_ENV       = "production"
          RUN_SIDEKIQ     = "1"
          RAILS_LOG_LEVEL = "info"
        }

        runtime_environment_secrets = var.secret_parameter_arns
      }
    }
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.instance.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.this.arn
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/up"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  depends_on = [
    aws_iam_role_policy_attachment.access_ecr,
    aws_iam_role_policy.instance_ssm,
  ]
}
