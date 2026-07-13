# Azure Deployment Specification: [Project Name]

**Version:** 1.0
**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Status:** Draft / In Review / Approved
**Cloud:** Microsoft Azure
**Region:** [e.g., eastus2]
**App Type:** [React SPA / Golang Microservice / Full-Stack]

---

## 1. Azure Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AZURE CLOUD                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Azure Container Registry (ACR)              │  │
│  │  [project].azurecr.io/[service]:sha-abc123def            │  │
│  └───────────────────────────┬──────────────────────────────┘  │
│                              │                                  │
│                    ┌─────────▼─────────┐                        │
│                    │   Container Apps  │                        │
│                    │ (Golang Microserv)│                        │
│                    │ 0.5 vCPU, 1 GB    │                        │
│                    │ HTTP Auto-scaling │                        │
│                    └────────┬──────────┘                        │
│                             │                                   │
│         ┌───────────────────┼───────────────────┐               │
│         │                   │                   │               │
│    ┌────▼─────┐   ┌────────▼────────┐   ┌─────▼──────┐         │
│    │ Key Vault│   │ Log Analytics   │   │ PostgreSQL │         │
│    │ Secrets  │   │ Workspace       │   │ Flexible   │         │
│    │JWT,DB URL│   │                 │   │            │         │
│    └──────────┘   └─────────────────┘   └────────────┘         │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          Static Web App (React SPA frontend)             │  │
│  │     stapp-[project]-[env]-001.azurestaticapps.net        │  │
│  │     Auto HTTPS, Custom Domain, SPA Routing              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Servicios Azure Utilizados

| Servicio | Propósito | SKU/Tier | Costo Estimado |
|---------|----------|----------|----------------|
| Azure Container Registry | Almacenamiento de imágenes Docker | Standard | $10/mes |
| Azure Container Apps | Runtime del microservicio Golang | Consumption plan | ~$40/mes (prod) |
| Azure Static Web Apps | Hosting del frontend React | Standard | $10/mes |
| Azure Database for PostgreSQL | Base de datos relacional | Flexible Server, Burstable B1ms | $15-30/mes |
| Azure Key Vault | Gestión centralizada de secretos | Standard | $0.30/secreto/mes |
| Azure Monitor + Log Analytics | Observabilidad y alertas | Pay-per-use | ~$20-50/mes |
| Azure Virtual Network | Networking privado | Standard | No costo |

---

## 2. IaC: Terraform (Multi-cloud Standard)

### 2.1 Backend Configuration

```hcl
# terraform/backend.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "stterraformstate[project]"
    container_name       = "tfstate"
    key                  = "[project-name].terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
```

### 2.2 Variables

```hcl
# terraform/variables.tf
variable "project_name" {
  description = "Nombre del proyecto. Usado como prefijo en todos los recursos."
  type        = string
}

variable "environment" {
  description = "Nombre del environment: dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment debe ser dev, staging o prod."
  }
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus2"
}

variable "container_image" {
  description = "Imagen Docker completa con tag: registry.azurecr.io/[app]:[tag]"
  type        = string
}

variable "db_admin_password" {
  description = "Password del admin de PostgreSQL. Obtenido desde Azure Key Vault en CI/CD."
  type        = string
  sensitive   = true
}
```

### 2.3 Modulo Principal

```hcl
# terraform/main.tf

locals {
  tags = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
    owner       = "[team-name]"
  }
  prefix = "${var.project_name}-${var.environment}"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(local.prefix, "-", "")}001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false  # Usar Managed Identity, nunca admin
  tags                = local.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "kv-${local.prefix}-001"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = var.environment == "prod" ? true : false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
  }

  tags = local.tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.prefix}-001"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
}

# Container App (Golang microservice)
resource "azurerm_container_app" "api" {
  name                         = "ca-${local.prefix}-api-001"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type = "SystemAssigned"
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = "System"
  }

  template {
    container {
      name   = "[service-name]"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "db-url"
      }

      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }

      env {
        name  = "LOG_LEVEL"
        value = "info"
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 8080
        initial_delay    = 15
        period_seconds   = 20
        failure_count_threshold = 3
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/ready"
        port      = 8080
        initial_delay    = 5
        period_seconds   = 10
      }
    }

    min_replicas = var.environment == "prod" ? 2 : 1
    max_replicas = 10

    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = "100"
    }
  }

  secret {
    name                = "db-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_url.id
    identity            = "System"
  }

  secret {
    name                = "jwt-secret"
    key_vault_secret_id = azurerm_key_vault_secret.jwt_secret.id
    identity            = "System"
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Static Web App (React SPA)
resource "azurerm_static_web_app" "frontend" {
  name                = "stapp-${local.prefix}-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2"
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = local.tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.prefix}-001"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = "psqladmin"
  administrator_password = var.db_admin_password
  zone                   = "1"

  storage_mb   = 32768
  sku_name     = var.environment == "prod" ? "B_Standard_B2s" : "B_Standard_B1ms"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false

  tags = local.tags

  lifecycle {
    ignore_changes = [administrator_password]
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.prefix}-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  tags                = local.tags
}

# Data source para el contexto actual
data "azurerm_client_config" "current" {}

# Secrets en Key Vault
resource "azurerm_key_vault_secret" "db_url" {
  name            = "db-url"
  value           = "postgresql://psqladmin:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/[database-name]?sslmode=require"
  key_vault_id    = azurerm_key_vault.main.id
  expiration_date = timeadd(timestamp(), "8760h")  # Expiración en 1 año
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = var.jwt_secret  # Pasado via CI/CD
  key_vault_id = azurerm_key_vault.main.id
}
```

### 2.4 Outputs

```hcl
# terraform/outputs.tf
output "container_app_url" {
  description = "URL del Container App (Golang API)"
  value       = "https://${azurerm_container_app.api.latest_revision_fqdn}"
}

output "static_web_app_url" {
  description = "URL del frontend React"
  value       = azurerm_static_web_app.frontend.default_host_name
}

output "acr_login_server" {
  description = "Login server del Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "postgresql_fqdn" {
  description = "FQDN del servidor PostgreSQL"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}
```

---

## 3. IaC: Bicep (Alternativa Nativa Azure)

```bicep
// bicep/main.bicep
targetScope = 'resourceGroup'

@description('Nombre del proyecto')
param projectName string

@description('Nombre del environment: dev, staging, prod')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Región de Azure')
param location string = resourceGroup().location

@description('Imagen Docker del microservicio')
param containerImage string

var prefix = '${projectName}-${environment}'
var tags = {
  project: projectName
  environment: environment
  'managed-by': 'bicep'
  owner: '[team-name]'
}

// Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'acr${replace(prefix, '-', '')}001'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${prefix}-001'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: environment == 'prod'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${prefix}-001'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

// Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: 'cae-${prefix}-001'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: 'ca-${prefix}-api-001'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: 'system'
        }
      ]
      secrets: [
        {
          name: 'db-url'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/db-url'
          identity: 'system'
        }
        {
          name: 'jwt-secret'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/jwt-secret'
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: '[service-name]'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'DATABASE_URL'
              secretRef: 'db-url'
            }
            {
              name: 'JWT_SECRET'
              secretRef: 'jwt-secret'
            }
            {
              name: 'LOG_LEVEL'
              value: 'info'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8080
              }
              initialDelaySeconds: 15
              periodSeconds: 20
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/ready'
                port: 8080
              }
              initialDelaySeconds: 5
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: environment == 'prod' ? 2 : 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

// Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: 'stapp-${prefix}-001'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output acrLoginServer string = acr.properties.loginServer
```

---

## 4. CI/CD: GitHub Actions

```yaml
# .github/workflows/deploy-azure.yml
name: Deploy to Azure

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: deploy-azure-${{ github.ref }}
  cancel-in-progress: false

env:
  AZURE_CONTAINER_REGISTRY: acr[projectname]001.azurecr.io
  CONTAINER_APP_NAME: ca-[project]-[env]-api-001
  RESOURCE_GROUP: rg-[project]-[env]

permissions:
  id-token: write
  contents: read

jobs:
  build-and-test:
    name: Build & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'
          cache: true

      - name: Run tests
        run: go test ./... -race -coverprofile=coverage.out

      - name: Run linter
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: build-and-test
    steps:
      - uses: actions/checkout@v4

      - name: Scan with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

  build-image:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: security-scan
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (OIDC - no secrets)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Login to ACR
        run: az acr login --name ${{ env.AZURE_CONTAINER_REGISTRY }}

      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.AZURE_CONTAINER_REGISTRY }}/[service-name]
          tags: |
            type=sha,prefix=,suffix=,format=short

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build-image
    environment:
      name: production
      url: https://ca-[project]-prod-api-001.[region].azurecontainerapps.io
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'

      - name: Terraform Init & Apply (Production)
        run: |
          cd terraform
          terraform init
          terraform apply \
            -var="project_name=[project-name]" \
            -var="environment=prod" \
            -var="container_image=${{ needs.build-image.outputs.image-tag }}" \
            -auto-approve
```

---

## 5. CI/CD: Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: '[project]-[env]-secrets'
  - name: containerRegistry
    value: 'acr[projectname][env]001.azurecr.io'
  - name: imageName
    value: '[service-name]'

stages:
  - stage: BuildAndTest
    displayName: 'Build & Test'
    jobs:
      - job: Test
        steps:
          - task: GoTool@0
            inputs:
              version: '1.23'

          - script: go test ./... -race
            displayName: 'Run Tests'

  - stage: BuildImage
    displayName: 'Build Docker Image'
    dependsOn: BuildAndTest
    jobs:
      - job: Docker
        steps:
          - task: AzureCLI@2
            displayName: 'ACR Login'
            inputs:
              azureSubscription: 'Azure Service Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: az acr login --name $(containerRegistry)

          - task: Docker@2
            displayName: 'Build and Push'
            inputs:
              command: 'buildAndPush'
              repository: '$(containerRegistry)/$(imageName)'
              Dockerfile: 'Dockerfile'
              tags: '$(Build.SourceVersion)'

  - stage: DeployProduction
    displayName: 'Deploy to Production'
    dependsOn: BuildImage
    jobs:
      - deployment: Deploy
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@1
                  inputs:
                    terraformVersion: '1.6.0'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply Production'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
                    commandOptions: >
                      -var="project_name=[project-name]"
                      -var="environment=prod"
                      -var="container_image=$(containerRegistry)/$(imageName):$(Build.SourceVersion)"
                    environmentServiceNameAzureRM: 'Azure Service Connection'
```

---

## 6. Variables de Entorno y Secretos

### Secretos en Azure Key Vault

Crear manualmente en Azure Portal o vía CLI antes del primer deployment:

```bash
# Crear Key Vault si no existe
az keyvault create \
  --name kv-[project]-prod-001 \
  --resource-group rg-[project]-prod

# Agregar secretos
az keyvault secret set \
  --vault-name kv-[project]-prod-001 \
  --name db-url \
  --value "postgresql://psqladmin:password@psql-[project]-prod-001.postgres.database.azure.com:5432/[dbname]?sslmode=require"

az keyvault secret set \
  --vault-name kv-[project]-prod-001 \
  --name jwt-secret \
  --value "[256-bit-random-secret]"
```

### Terraform Variables por Environment

```hcl
# terraform/environments/prod.tfvars
project_name    = "[project-name]"
environment     = "prod"
location        = "eastus2"
container_image = "acr[projectname]001.azurecr.io/[service-name]:sha-abc123def"
```

---

## 7. Deployment Checklist

### Pre-Deployment

- [ ] Azure Storage Account para Terraform state creado (`stterraformstate[project]` en `rg-tfstate-prod`)
- [ ] Azure Container Registry creado (`acr[projectname]001`)
- [ ] Azure Key Vault creado y secretos poblados (`db-url`, `jwt-secret`)
- [ ] OIDC Federated Credentials configurado: App Registration → Federated Credentials → GitHub
- [ ] PostgreSQL Flexible Server creado y base de datos inicializada con migraciones
- [ ] Resource Group de producción creado (`rg-[project]-prod`)
- [ ] Azure DevOps Project creado y Service Connection configurado

### Durante Deployment

- [ ] `terraform plan` ejecutado y revisado sin errores
- [ ] Container image construida y pusheada a ACR
- [ ] `terraform apply` ejecutado sin errores
- [ ] Health check `GET /health` responde 200 OK
- [ ] Readiness check `GET /ready` responde 200 OK
- [ ] Container App en estado "Running"
- [ ] Logs aparecen en Log Analytics workspace

### Post-Deployment

- [ ] Alertas configuradas en Azure Monitor (uptime, error rate)
- [ ] Auto-scaling probado con carga simulada
- [ ] Backup de base de datos verificado
- [ ] Custom domain configurado (si aplica)
- [ ] DNS apunta al Static Web App para el frontend

---

## 8. Rollback Strategy

### Rollback de Infraestructura (Terraform)

```bash
# Listar versiones del tfstate en Azure Blob Storage
az storage blob list-deleted \
  --container-name tfstate \
  --account-name stterraformstate[project]

# Descargar tfstate anterior
az storage blob download \
  --container-name tfstate \
  --name [project-name].terraform.tfstate.backup \
  --file previous.tfstate \
  --account-name stterraformstate[project]

# Aplicar el state anterior
terraform apply previous.tfstate
```

### Rollback de Aplicación (Container Apps)

```bash
# Ver revisiones disponibles
az containerapp revision list \
  --name ca-[project]-prod-api-001 \
  --resource-group rg-[project]-prod \
  --query "[].{name:name, active:properties.active, created:properties.createdTime}" \
  --output table

# Enviar 100% del tráfico a una revisión anterior
az containerapp ingress traffic set \
  --name ca-[project]-prod-api-001 \
  --resource-group rg-[project]-prod \
  --revision-weight ca-[project]-prod-api-001--[previous-revision-number]=100
```

### Rollback de Base de Datos

**IMPORTANTE:** Las migraciones son forward-only. Si una migración falla:

1. Hacer rollback de la aplicación primero (pasos anteriores)
2. Crear una **nueva migración** que corrija el problema
3. Desplegar la nueva migración como hotfix
4. NO revertir la migración anterior (riesgo de pérdida de datos)

---

**Document Owner:** [Infrastructure Lead]
**Last Updated:** [YYYY-MM-DD]
**Review Cycle:** Por cada release mayor
**Ref:** `../../references/cloud-standards.md` + `../../references/security-rules.md`
