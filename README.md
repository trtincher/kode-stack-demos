# kode-stack-demos

Three small demos of a medical-coding workflow on one Rails app.

**Stack:** Ruby 3.4 · Rails 8.1 · Hotwire (Turbo + Stimulus) · importmap · Tailwind · PostgreSQL 16 · Sidekiq 8 on Valkey · Action Cable on Redis · Minitest + Capybara · AWS App Runner + RDS + ElastiCache Serverless (Terraform)

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

Terraform in `infra/` builds a private VPC (no NAT), RDS Postgres, ElastiCache Serverless Valkey, ECR, an App Runner service with a VPC connector, and a GitHub OIDC role that only `main` can assume. Roughly $26/month. State is local.

App Runner can't create a service before its image exists, so the first apply is in two phases:

```sh
# 1. Everything except the App Runner service
terraform -chdir=infra init
terraform -chdir=infra apply -var create_github_oidc_provider=false   # false if the account already has the GitHub provider

# 2. Push a first image (App Runner is linux/amd64 only)
aws ecr get-login-password | docker login --username AWS --password-stdin "$(terraform -chdir=infra output -raw ecr_repository_url | cut -d/ -f1)"
docker build --platform linux/amd64 -t "$(terraform -chdir=infra output -raw ecr_repository_url):latest" .
docker push "$(terraform -chdir=infra output -raw ecr_repository_url):latest"

# 3. Create the service
terraform -chdir=infra apply -var create_github_oidc_provider=false -var create_service=true
terraform -chdir=infra output service_url

# Keep create_service=true on every later apply, or Terraform destroys the service.
```

After that, set the repo variables `AWS_DEPLOY_ROLE_ARN` and `ECR_REPOSITORY_URL` from the Terraform outputs. Every push to `main` then builds and pushes `:latest` (`.github/workflows/deploy.yml`) and App Runner redeploys itself.
