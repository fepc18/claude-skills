---
name: deployment-specs
description: Genera especificaciones de deployment completas para Azure, AWS y DigitalOcean. Incluye Terraform HCL, IaC nativo por cloud (Bicep/CloudFormation), pipelines de CI/CD (GitHub Actions + Azure DevOps), gestión de secretos, y estrategias de rollback. Compatible con apps React frontend y microservicios Golang backend.
model_invoked: true
triggers:
  - deployment specs
  - specs de deployment
  - especificacion de deployment
  - infraestructura como codigo
  - infrastructure as code
  - desplegar en azure
  - deploy to azure
  - desplegar en aws
  - deploy to aws
  - desplegar en digital ocean
  - deploy to digitalocean
  - pipeline de ci/cd
  - ci/cd pipeline
  - github actions
  - azure devops pipeline
  - terraform
  - bicep
  - cloudformation
  - deploy spec
  - cloud deployment
  - como desplegar
  - how to deploy
  - deployment checklist
---

# Deployment Specs Skill

## Purpose

Generar especificaciones completas de deployment en cloud que cierren la brecha entre especificaciones técnicas (Stage 6) e implementación real. Este skill produce:

- **Terraform HCL** — IaC multi-cloud (funciona en Azure, AWS, DigitalOcean)
- **IaC Nativa por cloud** — Bicep (Azure), CloudFormation (AWS); Terraform para DO
- **CI/CD Pipelines** — GitHub Actions + Azure DevOps workflows
- **Gestión de Secretos** — Azure Key Vault, AWS Secrets Manager, DO App Platform
- **Estrategias de Rollback** — Por infraestructura, aplicación, y base de datos
- **Checklists de Deployment** — Pre, durante, y post deployment

## Critical: Reference Standards

**SIEMPRE revisar ANTES de generar specs:**

1. `../../references/cloud-standards.md` — Convenciones de naming, tagging, secrets, rollback, CI/CD pipeline canonical
2. `../../references/security-rules.md` — Auth, input validation, error handling, secrets security

Todos los deployment specs **DEBEN cumplir** con estos estándares.

## Workflow

### 1. Cloud Target Selection

Preguntar al usuario:

**"¿Para qué cloud(s) necesitas las deployment specs?"**

Opciones:
- A) Azure únicamente
- B) AWS únicamente
- C) DigitalOcean únicamente
- D) Multi-cloud (2 o 3 clouds)

Si responde D, generar los specs correspondientes en un único documento (secciones separadas por cloud).

### 2. Application Type

Preguntar:

**"¿Qué tipo de aplicación vas a desplegar?"**

Opciones:
- A) React SPA (frontend estático)
- B) Golang Microservicio (API backend)
- C) Full-Stack (React frontend + Golang API + PostgreSQL)

La respuesta determina:
- Qué servicios de cada cloud se incluyen
- Si es un deployment simple (React: Static Web Apps/S3, Golang: Container Apps/ECS Fargate)
- Si hay base de datos adjunta

### 3. Environment Scope

Preguntar:

**"¿Cuántos environments necesitas?"**

Opciones:
- A) Solo Producción
- B) Staging + Producción
- C) Dev + Staging + Producción

Esto determina:
- Número de workspaces Terraform
- Número de environment approval gates en CI/CD
- Complejidad del pipeline

### 4. Specification Generation

Con las respuestas anteriores:
1. Seleccionar el template correspondiente de `assets/`
2. Completar los placeholders:
   - `[project-name]` → nombre del proyecto
   - `[service-name]` → nombre del servicio (para Golang)
   - `[region]` → región seleccionada
   - `[environment]` → prod / staging / dev
3. Para full-stack, combinar bloques del frontend y backend en un solo documento

### 5. File Output

Guardar en: `/sessions/[session-id]/mnt/outputs/`

Nombre: `[project-name]-[cloud]-deployment-spec.md`

Ejemplos:
- `userservice-azure-deployment-spec.md` (Azure únicamente)
- `frontend-aws-deployment-spec.md` (AWS únicamente)
- `invoiceapp-digitalocean-deployment-spec.md` (DO únicamente)
- `myapp-multicloud-deployment-spec.md` (Multi-cloud en un doc)

### 6. Validation & Checklist

Antes de entregar:
- Mostrar el checklist de deployment pre-poblado de la sección "Deployment Checklist"
- Preguntar: "¿Esta spec cubre todos tus requisitos de deployment? ¿Necesitas ajustar algo?"
- Ofrecer: "¿Quieres que genere también el archivo `.env.example`?"
- Ofrecer: "¿Quieres un runbook de rollback más detallado?"

## Reference Standards Integration

### cloud-standards.md (Compliance)

✅ **Secrets Management:** Ningún secreto hardcodeado. Todas las referencias via Key Vault (Azure), Secrets Manager (AWS), o App Platform env (DO).

✅ **Resource Naming:** Patrón `{project}-{environment}-{resource-type}` en todos los recursos.

✅ **Tagging:** Todos los recursos tienen tags `project`, `environment`, `managed-by`, `owner`.

✅ **Terraform:** Backend remoto siempre (nunca local state). Workspaces por environment.

✅ **GitHub Actions:** OIDC para Azure/AWS (no tokens de larga vida). DO_API_TOKEN para DigitalOcean.

✅ **Rollback:** Estrategias por nivel (infra, app, DB) documentadas con comandos específicos.

### security-rules.md (Security)

✅ **Auth:** JWT claims `iss/aud/exp/iat`. Rotation cada 15min access / 7 days refresh.

✅ **Secrets:** No hardcodeados. Variables de entorno únicamente. Base de datos passwords rotados automáticamente.

✅ **HTTPS:** Forzado en todos los endpoints. Redirección de HTTP a HTTPS.

✅ **CORS:** Configurado para specific origins. Nunca `*`.

✅ **Rate Limiting:** Endpoints sensibles con 5 req/min + exponential backoff.

✅ **Logging:** Structured JSON. Cero PII. Timestamps + user_id + action + ip.

## Template Structure

Cada deployment spec (Azure, AWS, DO) sigue esta estructura:

```markdown
# [Cloud] Deployment Specification: [Project Name]

1. [Cloud] Architecture Overview
   - ASCII diagram
   - Tabla de servicios utilizados

2. IaC: Terraform (Multi-cloud Standard)
   - Backend configuration
   - Variables con `sensitive = true`
   - Modulo principal con todos los recursos
   - Outputs

3. IaC: [Nativa por Cloud] (Alternativa opcional)
   - Bicep (Azure) o CloudFormation (AWS)
   - Equivalente al Terraform de la seccion 2

4. CI/CD: GitHub Actions
   - Jobs: build → lint → security scan → terraform plan → deploy staging → integration tests → deploy prod → smoke tests

5. CI/CD: Azure DevOps (opcional si el usuario usa DevOps)
   - Stages paralelos a GitHub Actions

6. Variables de Entorno y Secretos
   - Tabla de secretos por cloud
   - `.tfvars` por environment

7. Deployment Checklist
   - Pre-Deployment
   - During Deployment
   - Post-Deployment

8. Rollback Strategy
   - Terraform state rollback
   - App rollback (Blue/Green, Container Apps revisions, etc)
   - Database rollback (forward-only migrations)
```

## Interaction Examples

### Example 1: Golang Microservicio en Azure

**User:** "Necesito deployment specs para mi Golang API en Azure production"

**Skill:**
1. Pregunta: "¿Multi-cloud o solo Azure?"
   → Respuesta: "Solo Azure"
2. Pregunta: "¿Microservicio o frontend?"
   → Respuesta: "Golang backend"
3. Pregunta: "¿Envs?"
   → Respuesta: "Staging + Production"
4. Genera: `[api-service]-azure-deployment-spec.md`
   - Azure Container Apps para el Golang
   - Azure PostgreSQL Database
   - Azure Key Vault para JWT_SECRET
   - GitHub Actions workflow con OIDC
   - Terraform + Bicep equivalentes
   - Deployment checklist Azure-specific
   - Rollback procedure vía `az containerapp`

### Example 2: React SPA Multi-Cloud (Azure + AWS)

**User:** "Quiero el mismo frontend en Azure y AWS. Damelas specs."

**Skill:**
1. Pregunta: "¿Cloud?"
   → Respuesta: "Azure + AWS"
2. Pregunta: "¿Tipo?"
   → Respuesta: "React frontend"
3. Genera: `[frontend]-multicloud-deployment-spec.md`
   - Sección Azure: Static Web Apps + CloudFront
   - Sección AWS: S3 + CloudFront
   - GitHub Actions con matriz de jobs para ambos clouds
   - Terraform (multi-cloud) + Bicep + CloudFormation
   - Checklists para ambos

### Example 3: Full-Stack en DigitalOcean

**User:** "Full-stack en DigitalOcean: React + Golang + PostgreSQL"

**Skill:**
1. Pregunta: "¿Cloud?"
   → Respuesta: "DigitalOcean"
2. Pregunta: "¿Tipo?"
   → Respuesta: "Full-stack"
3. Genera: `[app]-digitalocean-deployment-spec.md`
   - DO App Platform con Web Service (Golang) + Static Site (React)
   - DO Managed PostgreSQL
   - DO Spaces como backend de Terraform
   - GitHub Actions con `doctl`
   - App Spec YAML (alternativa a Terraform)
   - Deployment checklist DO-specific

## Quality Checklist

Antes de retornar el spec al usuario, verificar:

### Para TODO cloud target:

- ✅ NINGÚN secreto hardcodeado en los bloques HCL/YAML (grep por "password", "secret", "token")
- ✅ Variables de entorno separadas por environment (dev.tfvars, staging.tfvars, prod.tfvars)
- ✅ Health checks (`/health`, `/ready`) definidos en la app
- ✅ Rollback strategy documentada con comandos específicos del cloud
- ✅ Resource naming sigue convención de cloud-standards.md
- ✅ Tags/labels en TODOS los recursos (project, environment, managed-by, owner)
- ✅ Backend de Terraform remoto (no local state)

### Para Azure específicamente:

- ✅ Azure Key Vault referenciado para todos los secretos (sin `@Microsoft.KeyVault(...)` incompleto)
- ✅ OIDC configurado en GitHub Actions (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID; no service principal passwords)
- ✅ Bicep y Terraform generan los mismos recursos (equivalencia verificada)
- ✅ Managed Identity habilitada en Container Apps para acceso a Key Vault
- ✅ Deployment Slots configurados si es App Service (no si es Container Apps)

### Para AWS específicamente:

- ✅ IAM roles con permisos minimos (least privilege; no `*` en actions/resources)
- ✅ Secrets Manager o Parameter Store para secretos (no hardcoded en environment variables)
- ✅ OIDC configurado con AssumeRoleWithWebIdentity (no access keys en CI/CD)
- ✅ CloudFormation y Terraform cubriendo los mismos recursos (equivalencia)
- ✅ S3 bucket con public access block (no public read)

### Para DigitalOcean específicamente:

- ✅ DO API Token gestionado como GitHub Secret (no hardcodeado)
- ✅ App Spec generado con `image.registry_type: DOCR` y servicios correc configurados
- ✅ Database firewall restringido a la App ID (no open to internet)
- ✅ Solo Terraform (DO no tiene alternativa nativa equivalente)
- ✅ Spaces backend configurado con flags `skip_credentials_validation`, `force_path_style`

### Para GitHub Actions:

- ✅ Concurrency group configurado (evita deployments paralelos)
- ✅ Environment approval gates en production
- ✅ Secrets enmascarados automáticamente en logs
- ✅ Trivy o similar en el pipeline de seguridad (scan de image)

### Para Azure DevOps:

- ✅ Variable Groups vinculados a Key Vault
- ✅ Service Connection via Workload Identity Federation (no Service Principal con password)
- ✅ Approval gates en production stage
- ✅ Secrets marcados como "secret" en Variable Group

## Refinement Workflow

Si el usuario solicita cambios:

1. Preguntar: "¿Qué sección quieres refinar?" (Azure config, GitHub Actions, Terraform, etc)
2. Editar esa sección específica
3. Re-mostrar la sección modificada
4. Preguntar: "¿Mejor? ¿Listo para deployment?"
5. Ofrecer: "¿Quieres generar un runbook de runbook, o una Architecture Diagram?"

Si hay cambios importantes (ej: agregar nueva región):
- Regenear el stack completo con la nueva configuración
- Mostrar diff de qué cambió

## Dependencies & Context

**Used by:**
- sdlc-orchestrator (Stage 7 - Nueva etapa)
- technical-specs skill (Stage 6 puede invocar deployment-specs automáticamente)
- Puede usarse de forma independiente si tienes specs técnicas ya hechas

**Feeds into:**
- Implementación real (engineers usan estas specs para provisionar infra y desplegar)
- Runbooks de operación (como mantener, escalar, rollback)

**References:**
- `../../references/cloud-standards.md` (naming, tagging, secrets, rollback, CI/CD stages)
- `../../references/security-rules.md` (auth, secrets, HTTPS, CORS, rate limiting, logging)

**Output location:** `/sessions/[session-id]/mnt/outputs/[project-name]-[cloud(s)]-deployment-spec.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with embedded HCL (Terraform), JSON (CloudFormation), YAML (Bicep, GitHub Actions, Azure DevOps), and shell commands for rollback
