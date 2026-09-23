# kode-stack-demos

Three small demos of a medical-coding workflow on one Rails app.

**Stack:** Ruby 3.4 · Rails 8.1 · Hotwire (Turbo + Stimulus) · importmap · Tailwind · PostgreSQL 16 · Sidekiq 8 on Valkey · Action Cable on Redis · Minitest + Capybara · AWS ECS Fargate + ALB + RDS + ElastiCache Valkey (Terraform)

> **Synthetic data only.** Every chart, encounter note, and code in this app is made up. Nothing here comes from, or should resemble, real patient data.

## The demos

| Demo | Path | What it shows |
|---|---|---|
| Chart queue | `/queue` | Coders claim synthetic charts from a shared queue. Turbo Streams over Action Cable keep every tab live, claims use `SELECT … FOR UPDATE SKIP LOCKED` so two workers never get the same chart, and a Sidekiq job releases claims that miss their SLA. |
| Review workflow | `/review` | A coded chart moves draft → in review → returned → approved (aasm). Inline Turbo Frame edits, a PaperTrail audit timeline, and Stimulus keyboard shortcuts. |
| Coding assistant + evals | `/assistant` | A Sidekiq job sends a synthetic encounter note to a model adapter (Claude by default, a fake adapter in tests) and streams suggested codes back with confidence. An Evals tab runs a golden set. |

The registry lives in `config/initializers/demos.rb` (`DEMOS`); the home page, nav, seeds, and `ResetDemoDataJob` all read it. Each demo owns its own route namespace and its own `db/seeds/<key>.rb`.

## Run it locally

```sh
docker compose up -d          # Postgres 16 on :5432, Valkey 8 on :6379
mise install                  # Ruby 3.4.10 (mise.toml)
mise exec -- bin/setup        # bundle, db:prepare, then starts bin/dev
```

`bin/dev` runs the web server, the Tailwind watcher, and a Sidekiq worker (`Procfile.dev`). Open http://localhost:3000. The Sidekiq dashboard is at `/sidekiq` in development only.

Working in several checkouts at once? Set `DB_SUFFIX` to give each its own databases, e.g. `DB_SUFFIX=queue` uses `kode_stack_demos_development_queue`. Reset every demo's data with `bin/rails db:seed` (or enqueue `ResetDemoDataJob`).

## Test

```sh
mise exec -- bin/rails test          # unit + integration
mise exec -- bin/rails test:system   # headless Chrome
mise exec -- bundle exec brakeman -q
```

CI (`.github/workflows/ci.yml`) runs the same against Postgres 16 and Valkey 8 service containers.

## Deploy

Terraform in `infra/` builds a VPC (public subnets for the ALB and the app, private subnets for data, no NAT), RDS Postgres, one ElastiCache Valkey node, ECR, an ECS Fargate service behind an ALB, and a GitHub OIDC role that only `main` can assume. The app serves at **https://demos.travis-tincher.com** (ACM certificate, DNS-validated in the `travis-tincher.com` Route 53 zone). State is local.

One Fargate task (0.5 vCPU / 1 GB) runs Thruster + Puma on 8080 with the Sidekiq worker alongside (`RUN_SIDEKIQ=1`). The ALB idle timeout is an hour so Action Cable WebSockets stay open. ECS rather than App Runner: App Runner doesn't proxy WebSockets, and it stopped taking new customers on 2026-04-30.

```sh
# 1. Infrastructure (the service starts, then waits for an image)
terraform -chdir=infra init
terraform -chdir=infra apply -var create_github_oidc_provider=false   # false if the account already has the GitHub provider

# 2. Push an image (the task definition is linux/amd64)
ECR="$(terraform -chdir=infra output -raw ecr_repository_url)"
aws ecr get-login-password | docker login --username AWS --password-stdin "${ECR%%/*}"
docker buildx build --platform linux/amd64 -t "$ECR:latest" --push .

# 3. Roll the service onto it
aws ecs update-service --cluster kode-stack-demos --service kode-stack-demos --force-new-deployment
aws ecs wait services-stable --cluster kode-stack-demos --services kode-stack-demos
terraform -chdir=infra output service_url
```

On a brand-new stack the service's first tasks can't pull `:latest` until step 2 lands, and the deployment circuit breaker marks that first deployment failed; step 3 starts a fresh one. (If ECR already exists, push the image before applying.) Later deploys are steps 2 and 3. Logs are in CloudWatch under `/ecs/kode-stack-demos`.

Cost is roughly $70/month: the ALB (~$17), the Fargate task (~$18), RDS db.t4g.micro + 20 GB (~$14), the Valkey node (~$12) and three public IPv4 addresses (~$11). Tear it all down with:

```sh
terraform -chdir=infra destroy -var create_github_oidc_provider=false
```

The deploy role (`terraform -chdir=infra output deploy_role_arn`) can push to this ECR repository, register task definitions, update this ECS service and pass its two task roles, so a GitHub Actions deploy workflow on `main` can run steps 2 and 3 with no long-lived keys.
