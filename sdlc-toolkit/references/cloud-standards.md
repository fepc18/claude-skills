# Cloud & Infrastructure Standards

Este documento establece convenciones vinculantes para todos los deployment specs y configuraciones de infraestructura en Azure, AWS y DigitalOcean.

**Requisito:** Todos los skills de deployment y engineers de infraestructura deben revisar y adherirse a estos estándares antes de desplegar.

---

## 1. Secrets Management (Regla Universal)

**Regla de Oro:** NUNCA hardcodear secretos en IaC, CI/CD workflows, o code. Gestión centralizada en los vaults de cada cloud.

### Por Cloud

#### Azure: Azure Key Vault
- **Ubicación:** Un Key Vault por proyecto y environment
- **Acceso:** Managed Identity para servicios, Workload Identity Federation para CI/CD
- **Nombramiento:** `kv-{project}-{environment}-001`
- **Propiedades obligatorias:**
  - `soft_delete_retention_days = 7`
  - `purge_protection_enabled = true` (en prod)
  - Network ACLs: `default_action = "Deny"`, excepción: `"AzureServices"`
- **Referencias en código:** Via `@Microsoft.KeyVault` en Bicep o `azurerm_key_vault_secret` en Terraform con Managed Identity

#### AWS: AWS Secrets Manager o Parameter Store
- **Ubicación:** Secrets Manager para secretos rotables (passwords, API keys), Parameter Store (SecureString type) para config
- **Nombramiento:** `/{project}/{environment}/{secret-name}` (ej: `/myapp/prod/db-password`)
- **Acceso:** IAM roles con política least-privilege `secretsmanager:GetSecretValue`
- **Referencias en código:** Via `valueFrom` en ECS Task Definition o `aws_secretsmanager_secret` en Terraform
- **CI/CD:** AWS Secrets Manager no se referencia directamente; se inyecta via IAM Task Role

#### DigitalOcean: App Platform Environment Secrets
- **Ubicación:** Definidos en el App Spec o App Platform Dashboard
- **Tipo:** Variable de entorno con `type: SECRET` en el app.yaml
- **Nombramiento:** `UPPERCASE_WITH_UNDERSCORES`
- **Acceso:** Almacenados encriptados por DO; injected en tiempo de deploy
- **CI/CD:** Gestionados como GitHub Secrets o variables de Azure DevOps, passed via `doctl app update`

### GitHub Actions Secrets (CI/CD)

**Estrategia OIDC (No Token de Larga Vida):**
- Azure: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (nunca passwords)
  - Usar: `azure/login@v2` con OIDC
  - Federated Credentials: App Registration → Credentials → Federated Credentials → Agregar GitHub
- AWS: `AWS_ROLE_ARN` (nunca access keys)
  - Usar: `aws-actions/configure-aws-credentials@v4` con OIDC
  - OIDC Provider: Crear en AWS IAM → Identity Providers
- DigitalOcean: `DO_API_TOKEN` (token de aplicación)
  - Usar: `digitalocean/action-doctl@v2` con el token
  - Regenerar cada 90 días mínimo

### Azure DevOps Variable Groups

- **No-Sensibles:** Variable Group vinculado a Key Vault
  - Usar: `group: '[project]-[env]-secrets'` en el pipeline
  - Configurar Service Connection con Workload Identity Federation
- **Sensibles:** Marcadas como `secret` en el Variable Group UI
  - En YAML: usar `$(SecretVariableName)` (output masked automáticamente)

---

## 2. Resource Naming Convention

**Patrón Universal:** `{project}-{environment}-{resource-type}` (separados por guiones, lowercase)

### Ejemplos Válidos

```
myapp-prod-aks           (Azure Kubernetes Service)
myapp-staging-aca        (Azure Container Apps)
myapp-prod-storage       (Azure Storage Account)
myapp-prod-psql          (PostgreSQL Database)
myapp-dev-rds            (AWS RDS)
myapp-prod-alb           (AWS Application Load Balancer)
myapp-staging-s3         (AWS S3 Bucket)
myapp-prod-droplet       (DigitalOcean App Platform)
myapp-prod-db-postgres   (DigitalOcean Managed PostgreSQL)
```

### Componentes

| Componente | Validación | Notas |
|-----------|-----------|-------|
| `{project}` | 3-20 caracteres, lowercase, sin guiones al inicio/final | Ej: `myapp`, `invoice-service` |
| `{environment}` | `dev` \| `staging` \| `prod` | Nunca abreviaciones aleatorias |
| `{resource-type}` | Tipo de recurso cloudprovider (ej: `aks`, `rds`, `s3`) | Debe ser reconocible |

**Restricciones por Cloud:**

- **Azure:** Max 24 caracteres (algunos recursos como Storage Accounts). Usar sufijo `001` para múltiples instancias del mismo tipo.
- **AWS:** Max 63 caracteres. Guiones permitidos pero no al inicio/final.
- **DigitalOcean:** Max 63 caracteres. Sin caracteres especiales.

---

## 3. Tagging/Labeling (Obligatorio en TODOS los recursos)

Todos los recursos de infraestructura deben tener los siguientes tags:

| Tag | Tipo | Valores | Obligatorio |
|-----|------|--------|------------|
| `project` | String | nombre del proyecto | ✅ |
| `environment` | String | `dev` / `staging` / `prod` | ✅ |
| `managed-by` | String | `terraform` \| `bicep` \| `cloudformation` | ✅ |
| `owner` | String | team name o email | ✅ |
| `cost-center` | String | código de cost center (si aplica) | ○ |
| `app` | String | nombre de la aplicación | ○ |

### Implementación por Cloud

#### Azure (Tags nativos)
```hcl
# Terraform
locals {
  tags = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
    owner       = "platform-team"
  }
}

resource "azurerm_resource_group" "main" {
  tags = local.tags
}
```

#### AWS (Tags nativos)
```hcl
# Terraform
provider "aws" {
  default_tags {
    tags = {
      project     = var.project_name
      environment = var.environment
      managed-by  = "terraform"
      owner       = "platform-team"
    }
  }
}
```

#### DigitalOcean (Resources y Project tags)
```hcl
# Terraform
resource "digitalocean_app" "main" {
  spec {
    name = local.prefix
  }
}

# Manual via `doctl resource tag create` después de crear recursos
```

---

## 4. Terraform Conventions

### Backend Remoto (Siempre)

**Nunca** usar `terraform.tfstate` local. Backend remoto es obligatorio.

#### Azure: Blob Storage Backend
```hcl
backend "azurerm" {
  resource_group_name  = "rg-tfstate-prod"
  storage_account_name = "stterraform[project]"  # Max 24 chars, lowercase, alphanumeric
  container_name       = "tfstate"
  key                  = "[project-name].terraform.tfstate"
}
```

#### AWS: S3 + DynamoDB Backend
```hcl
backend "s3" {
  bucket         = "[project-tfstate-account-id]"
  key            = "[project-name]/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "[project-tfstate-lock"
  encrypt        = true
}
```

#### DigitalOcean: S3-Compatible Spaces Backend
```hcl
backend "s3" {
  endpoint = "https://nyc3.digitaloceanspaces.com"
  bucket   = "[project]-tfstate"
  key      = "[project-name].terraform.tfstate"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  force_path_style            = true
  # Credenciales via env vars: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
}
```

### Variables Sensibles

```hcl
variable "db_password" {
  type        = string
  description = "Database admin password"
  sensitive   = true  # Output masking automático
}

output "db_connection_string" {
  value       = "postgresql://user:pass@${azurerm_postgresql_flexible_server.main.fqdn}:5432/db"
  sensitive   = true  # No mostrar en logs ni stdout
  description = "Hide DB credentials from Terraform output"
}
```

### Workspaces por Environment

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Select antes de plan/apply
terraform workspace select prod
terraform plan -var-file="environments/prod.tfvars"
```

### Pre-Commit Checks (CI/CD obligatorio)

```bash
# Antes de cualquier merge/push:
terraform fmt -check -recursive
terraform validate
```

---

## 5. GitHub Actions Secrets Strategy

### Estructura de Secrets por Cloud

#### Azure
```
AZURE_CLIENT_ID         (de App Registration)
AZURE_TENANT_ID         (de Azure AD)
AZURE_SUBSCRIPTION_ID   (de Azure account)
```

#### AWS
```
AWS_ROLE_ARN            (ARN del IAM role para asumir via OIDC)
AWS_REGION              (ej: us-east-1)
```

#### DigitalOcean
```
DO_API_TOKEN            (personal access token, regenerar cada 90 días)
DO_SPACES_ACCESS_KEY    (para Terraform backend)
DO_SPACES_SECRET_KEY    (para Terraform backend)
```

### Convención de Nombrado

- Ambiente-agnostic: `AZURE_CLIENT_ID`, `AWS_ROLE_ARN`
- Proyecto-específico: `JWT_SECRET_PROD`, `DB_PASSWORD_STAGING`
- Nunca incluir el valor en el nombre: `DATABASE_URL=postgresql://...` ✅, `DB_PASS_abc123=xxx` ❌

---

## 6. Azure DevOps Variable Groups

### Patrón de creación

```yaml
# Azure DevOps UI o via `az devops variable-group create`
- Group name: `[project]-[environment]-secrets`
- Link to Azure Key Vault: Sí (si el proyecto usa Key Vault)
- Service Connection: [Workload Identity Federation Service Connection]

# Variables en el grupo:
- JWT_SECRET (link a Key Vault: kv-[project]-[env]/jwt-secret)
- API_URL (secreto: no, value: https://api.example.com)
```

### Uso en Pipeline

```yaml
variables:
  - group: '[project]-prod-secrets'  # Automáticamente loaded

stages:
  - stage: Deploy
    jobs:
      - deployment: DeployProd
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo $(JWT_SECRET)  # Automáticamente masked
```

---

## 7. Rollback Strategy (Universal)

### Nivel 1: Infraestructura (Terraform State)

**Procedimiento:**
1. Identificar el estado anterior: `terraform state list` o versión anterior de tfstate en backup
2. Restaurar el estado anterior desde el backend remoto (Azure Blob, S3, o DO Spaces)
3. Ejecutar `terraform apply` con el estado anterior

```bash
# Azure: Descargar tfstate anterior desde Blob Storage
az storage blob download \
  --container-name tfstate \
  --name [project].terraform.tfstate.backup \
  --account-name stterraformstate[project] \
  --file previous.tfstate

# AWS: Listar versiones del bucket S3
aws s3api list-object-versions \
  --bucket [project-tfstate] \
  --prefix [project-name].terraform.tfstate
```

### Nivel 2: Aplicación (Blue/Green o Deployment Revert)

**Azure Container Apps:**
```bash
# Listar revisiones disponibles
az containerapp revision list \
  --name ca-[project]-prod-api \
  --resource-group rg-[project]-prod \
  --query "[].name"

# Revertir a revision anterior (100% traffic)
az containerapp ingress traffic set \
  --name ca-[project]-prod-api \
  --resource-group rg-[project]-prod \
  --revision ca-[project]-prod-api--[previous-revision-number] \
  --traffic-weight 100
```

**AWS ECS:**
```bash
# Revertir a task definition anterior
aws ecs update-service \
  --cluster [cluster-name] \
  --service [service-name] \
  --task-definition [task-definition-family]:[PREVIOUS_REVISION]
```

**DigitalOcean App Platform:**
```bash
# Listar deployments
doctl apps list-deployments [APP_ID]

# Crear deployment basado en revisión anterior (via spec YAML)
doctl apps update [APP_ID] --spec .do/app.yaml  # Cambiar image tag a version anterior
```

### Nivel 3: Base de Datos

**Regla Crítica:** Las migraciones son FORWARD-ONLY. No se permite rollback de migraciones en base de datos en producción.

**Estrategia:**
1. Si una migración causa problemas: **primero rollback de la aplicación** (nivel 2)
2. Crear una **nueva migración** que corrija el problema (ej: `002_fix_schema.up.sql`)
3. Desplegar la nueva migración como hotfix
4. NO intentar deshacer la migración anterior

```sql
-- Ejemplo: si 001_create_users_table.up.sql causó problema
-- NO hacer: DROP TABLE users; (está prohibido)
-- SÍ hacer: crear 002_fix_users_table.up.sql
ALTER TABLE users ADD COLUMN fixed_column VARCHAR(255);
-- Luego desplegar la app con nueva migración
```

---

## 8. CI/CD Pipeline Stages (Orden Canónico)

Todos los pipelines (GitHub Actions + Azure DevOps) siguen este orden de stages:

```
1. Lint + Test (Unit)
   └─ Go linter, React linter, Unit tests
   └─ Fail fast: si falla, no continuar

2. Build (Artifact generation)
   └─ Docker image o JavaScript bundle
   └─ Generar versión reproducible (tag = git sha)

3. Security Scan
   └─ Trivy (container image), npm audit (JS dependencies)
   └─ SonarQube (code quality) - opcional pero recomendado
   └─ Fail en CRITICAL/HIGH

4. Terraform Plan (Dry-run de infra)
   └─ Mostrar qué cambiará en la infra
   └─ Reviewer puede aprobar o rechazar antes de apply

5. Deploy Staging
   └─ terraform apply + app deployment
   └─ Sin approval gate (ambiente desechable)

6. Integration Tests (Staging)
   └─ Tests contra staging environment
   └─ Smoke tests: health checks, rutas básicas
   └─ Fail → rollback automático de staging

7. Deploy Production
   └─ REQUIRE: Manual approval gate
   └─ REQUIRE: Approval de equipo en Azure DevOps / GitHub Environments
   └─ terraform apply + app deployment

8. Smoke Tests (Production)
   └─ Verificación básica: endpoints responden, no errores 500
   └─ Si falla: rollback automático de la app (NO de la infra)

9. Rollback Automático
   └─ Si smoke tests en prod fallan
   └─ Revertir app a versión anterior
   └─ Mantener infra (para debugging)
```

---

## 9. Security Best Practices (Cloud Deployment)

### Networking

- **VPC/VNet Privada:** Todos los recursos (DB, app) en subnets privadas. No public IP en base de datos.
- **Security Groups / Network Security Groups:** Whitelist explícito de acceso (deny by default)
- **WAF (Web Application Firewall):** Recomendado en production. Configurable en ALB (AWS) o Application Gateway (Azure)

### Authentication & Authorization

- **API Authentication:** JWT tokens (claims: iss, aud, exp, iat)
- **Token Storage:** HttpOnly cookies (no localStorage)
- **Secrets Rotation:** Automática cada 30-90 días (si el cloud lo soporta)
- **RBAC:** Role-based access control en todos los servicios

### Data at Rest & in Transit

- **Encryption:** TLS 1.2+ (HTTPS todo el trafico)
- **Database Encryption:** Habilitada por defecto en RDS, ACA, DO
- **Backup Encryption:** Automática en managed services

### Logging & Monitoring

- **Structured Logging:** JSON format con timestamp, user_id, action, ip
- **PII Protection:** Cero PII en logs (nunca email, passwords, tokens)
- **Retention:** 30-90 días según complianza
- **Alertas:** Configuradas en CloudWatch / Azure Monitor para errores y latencia

---

## 10. Compliance & Audit

### Checklist Pre-Deployment

- [ ] Ningún secreto hardcodeado (grep -r "password\|secret\|token")
- [ ] Terraform state encriptado en backend remoto
- [ ] HTTPS/TLS habilitado
- [ ] Backups automáticos configurados y testeados
- [ ] Alertas de uptime y errores configuradas
- [ ] Logs centralizados y persistidos
- [ ] Network policies / security groups restrictivos
- [ ] IAM roles con least-privilege
- [ ] Auditoría habilitada en Key Vault / Secrets Manager

### Documentación Requerida

- [ ] Runbook de deployment (como desplegar)
- [ ] Runbook de rollback (como revertir)
- [ ] Runbook de disaster recovery (como recuperarse de fallo crítico)
- [ ] Architecture diagram (visualmente)
- [ ] Security model document

---

## Referencias por Cloud

- **Azure:** [Azure Security Baseline](https://learn.microsoft.com/en-us/security/benchmark/azure/security-baseline-overview)
- **AWS:** [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- **DigitalOcean:** [DO App Platform Security](https://docs.digitalocean.com/products/app-platform/how-to/secure-apps/)

---

**Document Owner:** Platform/Infrastructure Team
**Last Updated:** 2026-07-12
**Review Cycle:** Quarterly
**Compliance:** Binding for all cloud deployments
