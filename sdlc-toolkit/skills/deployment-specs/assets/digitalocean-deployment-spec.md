# DigitalOcean Deployment Specification: [Project Name]

**Version:** 1.0
**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Status:** Draft / In Review / Approved
**Cloud:** DigitalOcean
**Region:** [e.g., nyc3]
**App Type:** [React SPA / Golang Microservice / Full-Stack]

**Important:** DigitalOcean no tiene una herramienta de IaC nativa equivalente a Bicep o CloudFormation. Terraform es el estándar recomendado por DO.

---

## 1. DigitalOcean Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│              DIGITALOCEAN APP PLATFORM                   │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │       Container Image Registry (DOCR)              │ │
│  │  registry.digitalocean.com/[project]/[service]     │ │
│  └──────────────────────┬─────────────────────────────┘ │
│                         │                                │
│        ┌────────────────▼────────────────┐               │
│        │   Web Service (Golang)          │               │
│        │   CPU: 1 vCPU / RAM: 512 MB     │               │
│        │   Auto-scaling via HTTP metrics │               │
│        └────────────┬─────────────────────┘              │
│                     │                                    │
│  ┌──────────────────┼──────────────────┐                │
│  │                  │                  │                │
│  │         ┌────────▼────────┐   ┌─────▼──────────┐    │
│  │         │ Managed Postgres │   │ Static Site    │    │
│  │         │ Database         │   │ (React SPA)    │    │
│  │         │ db-s-1vcpu-1gb   │   │                │    │
│  │         └──────────────────┘   └─────────────────┘   │
│  │                                                        │
│  │   Environment: [project]-prod                         │
│  │   Region: nyc3                                        │
│  └──────────────────────────────────────────────────────┘
│                                                          │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  DigitalOcean Spaces (S3-compatible)                 │ │
│  │  Terraform State Backend                             │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Servicios DigitalOcean Utilizados

| Servicio | Propósito | Plan | Costo Estimado |
|---------|----------|------|----------------|
| Container Registry (DOCR) | Almacenamiento de imágenes Docker | Basic | $5/mes |
| App Platform | Runtime para Golang + React | Basic/Professional | $12-60/mes |
| Managed PostgreSQL | Base de datos relacional | db-s-1vcpu-1gb | $15/mes |
| Spaces | Terraform state backend (S3-compatible) | 250GB | $5/mes |
| Project | Agrupación de recursos | Free | No costo |

---

## 2. IaC: Terraform (Multi-cloud Standard)

### 2.1 Backend Configuration

```hcl
# terraform/backend.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
  }

  # Backend S3-compatible en DigitalOcean Spaces
  backend "s3" {
    endpoint = "https://nyc3.digitaloceanspaces.com"
    region   = "us-east-1"  # Requerido pero no aplica a DO
    bucket   = "[project-name]-tfstate"
    key      = "[project-name].terraform.tfstate"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true

    # Credenciales via env vars: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
    # (son los Spaces credentials de DO, no de AWS)
  }
}

provider "digitalocean" {
  token = var.do_token
}
```

### 2.2 Variables

```hcl
# terraform/variables.tf
variable "do_token" {
  description = "DigitalOcean API Token. Pasar via TF_VAR_do_token o -var."
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Environment: dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment debe ser dev, staging, o prod."
  }
}

variable "region" {
  description = "Región de DigitalOcean"
  type        = string
  default     = "nyc3"
}

variable "container_image" {
  description = "Imagen Docker: registry.digitalocean.com/[registry]/[image]:[tag]"
  type        = string
}

variable "db_password" {
  description = "Password de PostgreSQL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}
```

### 2.3 Modulo Principal

```hcl
# terraform/main.tf

locals {
  prefix = "${var.project_name}-${var.environment}"
  tags   = [var.project_name, var.environment, "terraform"]
}

# DigitalOcean Project
resource "digitalocean_project" "main" {
  name        = local.prefix
  description = "[Project description] - ${var.environment} environment"
  purpose     = "Web Application"
  environment = var.environment == "prod" ? "Production" : "Staging"
}

# Container Registry
resource "digitalocean_container_registry" "main" {
  name                   = var.project_name
  subscription_tier_slug = "basic"
  region                 = var.region
}

# Managed PostgreSQL Database Cluster
resource "digitalocean_database_cluster" "main" {
  name       = "${local.prefix}-postgres"
  engine     = "pg"
  version    = "15"
  size       = var.environment == "prod" ? "db-s-2vcpu-4gb" : "db-s-1vcpu-1gb"
  region     = var.region
  node_count = var.environment == "prod" ? 3 : 1

  tags = local.tags
}

# Database User (no usar el default user)
resource "digitalocean_database_user" "app" {
  cluster_id = digitalocean_database_cluster.main.id
  name       = "${replace(var.project_name, "-", "_")}_app"
}

# Database
resource "digitalocean_database_db" "main" {
  cluster_id = digitalocean_database_cluster.main.id
  name       = replace(var.project_name, "-", "_")
}

# App Platform: App Spec
resource "digitalocean_app" "main" {
  spec {
    name   = local.prefix
    region = var.region

    # Service: Golang Backend
    service {
      name               = "api"
      instance_count     = var.environment == "prod" ? 2 : 1
      instance_size_slug = var.environment == "prod" ? "professional-xs" : "basic-xxs"

      image {
        registry_type = "DOCR"
        repository    = "[service-name]"
        tag           = "latest"
      }

      http_port     = 8080
      internal_port = 8080

      health_check {
        http_path             = "/health"
        initial_delay_seconds = 15
        period_seconds        = 20
        failure_threshold     = 3
        success_threshold     = 1
      }

      env {
        key   = "LOG_LEVEL"
        value = "info"
        type  = "GENERAL"
      }

      env {
        key   = "DATABASE_URL"
        value = digitalocean_database_cluster.main.uri
        type  = "SECRET"
      }

      env {
        key   = "JWT_SECRET"
        value = var.jwt_secret
        type  = "SECRET"
      }

      run_command = "./app"
    }

    # Static Site: React SPA
    static_site {
      name = "frontend"

      github {
        repo           = "[org]/[repo-name]"
        branch         = "main"
        deploy_on_push = true
      }

      build_command  = "npm ci && npm run build"
      output_dir     = "/dist"
      index_document = "index.html"
      error_document = "index.html"  # SPA routing: 404 → index.html

      env {
        key   = "VITE_API_URL"
        value = "https://${local.prefix}.ondigitalocean.app/api"
        type  = "GENERAL"
      }
    }

    # Domain (opcional: custom domain)
    domain {
      name = "[custom-domain.com]"
      type = "PRIMARY"
    }
  }

  tags = local.tags

  # Asignar al DO Project
  project_id = digitalocean_project.main.id
}

# Database Firewall: Solo permite conexiones del App
resource "digitalocean_database_firewall" "main" {
  cluster_id = digitalocean_database_cluster.main.id

  rule {
    type  = "app"
    value = digitalocean_app.main.id
  }
}

# Asignar recursos al Project
resource "digitalocean_project_resources" "main" {
  project = digitalocean_project.main.id
  resources = [
    digitalocean_database_cluster.main.urn,
    digitalocean_app.main.urn,
    digitalocean_container_registry.main.urn,
  ]
}
```

### 2.4 Outputs

```hcl
# terraform/outputs.tf
output "app_url" {
  description = "URL de la app en DigitalOcean"
  value       = "https://${digitalocean_app.main.default_ingress}"
}

output "registry_url" {
  description = "URL del container registry"
  value       = digitalocean_container_registry.main.server_url
}

output "database_host" {
  description = "Host del database cluster"
  value       = digitalocean_database_cluster.main.host
}
```

---

## 3. App Spec YAML Alternativo (sin Terraform)

Alternativa para desplegar directamente sin Terraform vía `doctl`:

```yaml
# .do/app.yaml
name: [project]-[environment]
region: nyc3

services:
  - name: api
    image:
      registry_type: DOCR
      repository: [service-name]
      tag: latest
    instance_count: 1
    instance_size_slug: basic-xxs
    http_port: 8080
    health_check:
      http_path: /health
      initial_delay_seconds: 15
      period_seconds: 20
      failure_threshold: 3
    envs:
      - key: LOG_LEVEL
        value: info
      - key: DATABASE_URL
        scope: RUN_AND_BUILD_TIME
        value: ${[project]-[env]-postgres.DATABASE_URL}
        type: SECRET
      - key: JWT_SECRET
        scope: RUN_AND_BUILD_TIME
        value: "[SET_VIA_DOCTL_OR_UI]"
        type: SECRET
    run_command: ./app

static_sites:
  - name: frontend
    source_dir: dist
    github:
      repo: [org]/[repo]
      branch: main
      deploy_on_push: true
    build_command: npm ci && npm run build
    output_dir: /dist
    index_document: index.html
    error_document: index.html
    envs:
      - key: VITE_API_URL
        value: https://[project]-[env].ondigitalocean.app/api

databases:
  - name: [project]-[env]-postgres
    engine: PG
    version: "15"
    production: false  # true en prod para HA

# Desplegar con:
# doctl apps create --spec .do/app.yaml
# o: doctl apps update [APP_ID] --spec .do/app.yaml
```

---

## 4. CI/CD: GitHub Actions

```yaml
# .github/workflows/deploy-do.yml
name: Deploy to DigitalOcean

on:
  push:
    branches: [main]

env:
  REGISTRY: registry.digitalocean.com
  IMAGE_NAME: [project-name]/[service-name]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'
          cache: true

      - run: go test ./... -race
      - run: go vet ./...

  build-image:
    runs-on: ubuntu-latest
    needs: build-and-test
    steps:
      - uses: actions/checkout@v4

      - name: Install doctl
        uses: digitalocean/action-doctl@v2
        with:
          token: ${{ secrets.DO_API_TOKEN }}

      - name: Login to DOCR
        run: doctl registry login --expiry-seconds 1200

      - name: Build and push Docker image
        env:
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build \
            -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:$IMAGE_TAG \
            -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest \
            .
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:$IMAGE_TAG
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

  deploy:
    runs-on: ubuntu-latest
    needs: build-image
    environment: production
    env:
      # DO Spaces credentials (S3-compatible) para Terraform backend
      AWS_ACCESS_KEY_ID: ${{ secrets.DO_SPACES_ACCESS_KEY }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.DO_SPACES_SECRET_KEY }}
      TF_VAR_do_token: ${{ secrets.DO_API_TOKEN }}
      TF_VAR_jwt_secret: ${{ secrets.JWT_SECRET }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Plan
        run: |
          terraform plan \
            -var="project_name=[project-name]" \
            -var="environment=prod" \
            -var="container_image=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}" \
            -out=tfplan
        working-directory: ./terraform

      - name: Terraform Apply
        run: terraform apply tfplan
        working-directory: ./terraform

  smoke-tests:
    runs-on: ubuntu-latest
    needs: deploy
    steps:
      - name: Health check
        run: |
          APP_URL="https://[project]-prod.ondigitalocean.app"
          curl --fail "${APP_URL}/api/health" || exit 1
          echo "✅ Deployment verified successfully"
```

---

## 5. CI/CD: Azure DevOps

```yaml
# azure-pipelines-do.yml
trigger:
  branches:
    include: [main]

pool:
  vmImage: ubuntu-latest

variables:
  registryName: registry.digitalocean.com/[project-name]
  imageName: '[service-name]'

stages:
  - stage: Build
    jobs:
      - job: Test
        steps:
          - task: GoTool@0
            inputs:
              version: '1.23'
          - script: go test ./... -race
            displayName: 'Run Tests'

  - stage: BuildImage
    dependsOn: Build
    jobs:
      - job: Docker
        steps:
          - script: |
              # Install doctl
              cd ~
              wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
              tar xf ~/doctl-1.104.0-linux-amd64.tar.gz
              sudo mv ~/doctl /usr/local/bin
              doctl auth init --access-token $(DO_API_TOKEN)
              doctl registry login
              docker build -t $(registryName)/$(imageName):$(Build.SourceVersion) .
              docker push $(registryName)/$(imageName):$(Build.SourceVersion)
            displayName: 'Build and Push to DOCR'
            env:
              DO_API_TOKEN: $(DO_API_TOKEN)

  - stage: DeployProduction
    dependsOn: BuildImage
    jobs:
      - deployment: Deploy
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - script: |
                    # Install Terraform
                    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
                    unzip terraform_1.6.0_linux_amd64.zip
                    sudo mv terraform /usr/local/bin
                  displayName: 'Install Terraform'
                - script: |
                    cd terraform
                    export AWS_ACCESS_KEY_ID=$(DO_SPACES_ACCESS_KEY)
                    export AWS_SECRET_ACCESS_KEY=$(DO_SPACES_SECRET_KEY)
                    export TF_VAR_do_token=$(DO_API_TOKEN)
                    export TF_VAR_jwt_secret=$(JWT_SECRET)
                    terraform init
                    terraform apply \
                      -var="project_name=[project-name]" \
                      -var="environment=prod" \
                      -var="container_image=$(registryName)/$(imageName):$(Build.SourceVersion)" \
                      -auto-approve
                  displayName: 'Terraform Apply'
```

---

## 6. Gestión de Secretos

### GitHub Secrets Requeridos

| Secret | Descripción |
|--------|------------|
| `DO_API_TOKEN` | DigitalOcean API Token (regenerar cada 90 días) |
| `DO_SPACES_ACCESS_KEY` | Spaces access key para Terraform backend |
| `DO_SPACES_SECRET_KEY` | Spaces secret key para Terraform backend |
| `JWT_SECRET` | JWT signing secret (min 256 bits) |

**Nota:** La `DATABASE_URL` se inyecta automáticamente desde el managed cluster en el App Spec.

### Azure DevOps Variables

```yaml
variables:
  - group: '[project]-prod-secrets'
  - name: DO_API_TOKEN
    value: $(DO_API_TOKEN)  # from group
  - name: DO_SPACES_ACCESS_KEY
    value: $(DO_SPACES_ACCESS_KEY)
  - name: DO_SPACES_SECRET_KEY
    value: $(DO_SPACES_SECRET_KEY)
  - name: JWT_SECRET
    value: $(JWT_SECRET)
```

---

## 7. Deployment Checklist

### Pre-Deployment

- [ ] DigitalOcean API Token generado con permisos de escritura
- [ ] DO Spaces creado y configurado para Terraform backend
- [ ] DOCR creado y push credentials gestionadas
- [ ] Managed PostgreSQL cluster creado
- [ ] DO App creado (vía UI o app.yaml)
- [ ] GitHub secrets poblados (DO_API_TOKEN, DO_SPACES keys, JWT_SECRET)

### Durante Deployment

- [ ] Docker image construida y pusheada a DOCR
- [ ] `terraform plan` revisado y aprobado
- [ ] `terraform apply` ejecutado sin errores
- [ ] App Platform health check pasa (GET /api/health)
- [ ] Frontend React buildea correctamente
- [ ] Custom domain configurado (si aplica)

### Post-Deployment

- [ ] App accesible en [project]-prod.ondigitalocean.app
- [ ] React SPA router funciona al hacer refresh directo
- [ ] PostgreSQL backup automático habilitado
- [ ] Monitoring/alertas configuradas

---

## 8. Rollback DigitalOcean

### Rollback App Platform

```bash
# Listar deployments disponibles
doctl apps list-deployments [APP_ID]

# Ver el deployment anterior
doctl apps get-deployment [APP_ID] [DEPLOYMENT_ID]

# Opción 1: Crear nuevo deployment con imagen anterior
# Editar image tag en app.yaml y ejecutar:
doctl apps update [APP_ID] --spec .do/app.yaml

# Opción 2: Via DO UI Dashboard → Apps → [app] → Deployments → Rollback
```

### Rollback Terraform

```bash
# Listar versiones del tfstate en Spaces
aws s3 ls s3://[project]-tfstate/ --endpoint https://nyc3.digitaloceanspaces.com

# Aplicar estado anterior
terraform apply [previous-state-file]
```

---

**Document Owner:** [Infrastructure Lead]
**Last Updated:** [YYYY-MM-DD]
**Ref:** `../../references/cloud-standards.md` + `../../references/security-rules.md`
