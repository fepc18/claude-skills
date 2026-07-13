# AWS Deployment Specification: [Project Name]

**Version:** 1.0
**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Status:** Draft / In Review / Approved
**Cloud:** Amazon Web Services
**Region:** [e.g., us-east-1]
**App Type:** [React SPA / Golang Microservice / Full-Stack]

---

## 1. AWS Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                       AWS CLOUD                                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │       Amazon Elastic Container Registry (ECR)            │  │
│  │    [account-id].dkr.ecr.us-east-1.amazonaws.com/         │  │
│  │    [service-name]:sha-abc123def                          │  │
│  └──────────────────────────┬───────────────────────────────┘  │
│                             │                                   │
│                  ┌──────────▼───────────┐                       │
│                  │   AWS ECS Fargate    │                       │
│                  │ (Golang Microserv)   │                       │
│                  │ 512 CPU, 1024 Memory │                       │
│                  │ Auto Scaling via ALB │                       │
│                  └─────────┬────────────┘                       │
│                            │                                    │
│         ┌──────────────────┼──────────────────┐                │
│         │                  │                  │                │
│    ┌────▼──────┐  ┌────────▼────────┐  ┌─────▼──────────┐     │
│    │  Secrets   │  │   CloudWatch    │  │  AWS RDS      │     │
│    │  Manager   │  │   Logs          │  │  PostgreSQL   │     │
│    │JWT, DB URL │  │                 │  │   db.t3.small │     │
│    └────────────┘  └─────────────────┘  └───────────────┘     │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐  │
│  │   Application Load Balancer (ALB)                       │  │
│  │   HTTPS termination, Health checks                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐  │
│  │   S3 Bucket + CloudFront (React SPA)                    │  │
│  │   d123456.cloudfront.net (SPA Routing)                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Servicios AWS Utilizados

| Servicio | Propósito | Tier | Costo Est. |
|---------|----------|------|----------|
| Amazon ECR | Almacenamiento de imágenes Docker | Standard | $0.10/GB almacenado |
| AWS ECS Fargate | Runtime del microservicio Golang (serverless) | Fargate | ~$30-50/mes |
| Application Load Balancer | Ingress, HTTPS termination, health checks | Standard | ~$15/mes + request charges |
| Amazon RDS PostgreSQL | Base de datos relacional | db.t3.small | ~$25-50/mes |
| AWS Secrets Manager | Gestión de secretos | Standard | $0.40/secret/mes |
| Amazon CloudWatch | Observabilidad | Pay-per-use | ~$20-40/mes |
| Amazon S3 + CloudFront | Hosting frontend React | Standard | ~$5-15/mes |
| AWS VPC | Networking privado | Standard | No costo |

---

## 2. IaC: Terraform (Multi-cloud Standard)

### 2.1 Backend Configuration

```hcl
# terraform/backend.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }

  backend "s3" {
    bucket         = "[project-tfstate-account-id]"
    key            = "[project-name]/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "[project-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project     = var.project_name
      environment = var.environment
      managed-by  = "terraform"
      owner       = "[team-name]"
    }
  }
}
```

### 2.2 Variables

```hcl
# terraform/variables.tf
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment debe ser dev, staging o prod."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "container_image" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}
```

### 2.3 Modulo Principal

```hcl
# terraform/main.tf
locals {
  prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# ECR Repository
resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}/${var.environment}/[service-name]"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle_policy {
    policy = jsonencode({
      rules = [{
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }]
    })
  }

  tags = {
    Name = "${local.prefix}-ecr"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.prefix}-cluster"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.prefix}-api"
  retention_in_days = var.environment == "prod" ? 90 : 30
}

# ECS Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.prefix}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "[service-name]"
    image = var.container_image

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    environment = [
      { name = "LOG_LEVEL", value = "info" },
      { name = "PORT", value = "8080" }
    ]

    secrets = [
      {
        name      = "DATABASE_URL"
        valueFrom = "${aws_secretsmanager_secret.db_url.arn}"
      },
      {
        name      = "JWT_SECRET"
        valueFrom = "${aws_secretsmanager_secret.jwt_secret.arn}"
      }
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 15
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "api" {
  name            = "${local.prefix}-api-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.environment == "prod" ? 2 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "[service-name]"
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

# S3 Bucket para React SPA
resource "aws_s3_bucket" "frontend" {
  bucket = "${local.prefix}-frontend-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"
  }

  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Secrets Manager
resource "aws_secretsmanager_secret" "db_url" {
  name        = "${local.prefix}/db-url"
  description = "PostgreSQL connection string"
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = var.db_password
    host     = aws_db_instance.main.address
    dbname   = aws_db_instance.main.db_name
    port     = 5432
  })
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "${local.prefix}/jwt-secret"
  description = "JWT signing secret"
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.jwt_secret
}

# RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier        = "${local.prefix}-postgres"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = var.environment == "prod" ? "db.t3.small" : "db.t3.micro"
  allocated_storage = var.environment == "prod" ? 100 : 20
  storage_encrypted = true
  storage_type      = "gp3"

  db_name  = replace(var.project_name, "-", "_")
  username = "dbadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.environment == "prod" ? 30 : 7
  skip_final_snapshot     = var.environment == "prod" ? false : true
  deletion_protection     = var.environment == "prod" ? true : false

  lifecycle {
    ignore_changes = [password]
  }
}
```

### 2.4 IAM Roles

```hcl
# ECS Task Execution Role (ECR + CloudWatch Logs + Secrets Manager)
resource "aws_iam_role" "ecs_execution" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  role = aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.db_url.arn,
        aws_secretsmanager_secret.jwt_secret.arn
      ]
    }]
  })
}

# ECS Task Role (para la app, permisos mínimos)
resource "aws_iam_role" "ecs_task" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}
```

---

## 3. IaC: CloudFormation (Alternativa Nativa AWS)

```yaml
# cloudformation/template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: '[Project Name] - [Environment] Deployment'

Parameters:
  ProjectName:
    Type: String
  Environment:
    Type: String
    AllowedValues: [dev, staging, prod]
  ContainerImage:
    Type: String
  DBPassword:
    Type: String
    NoEcho: true

Resources:
  # ECR Repository
  ECRRepository:
    Type: AWS::ECR::Repository
    Properties:
      RepositoryName: !Sub '${ProjectName}/${Environment}/[service-name]'
      ImageScanningConfiguration:
        ScanOnPush: true
      LifecyclePolicy:
        LifecyclePolicyText: |
          {"rules":[{"rulePriority":1,"description":"Keep last 10 images",
          "selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":10},
          "action":{"type":"expire"}}]}

  # ECS Cluster
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub '${ProjectName}-${Environment}-cluster'
      ClusterSettings:
        - Name: containerInsights
          Value: enabled

  # RDS PostgreSQL
  RDSInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: !Sub '${ProjectName}-${Environment}-postgres'
      Engine: postgres
      EngineVersion: '15.4'
      DBInstanceClass: !If [IsProd, 'db.t3.small', 'db.t3.micro']
      AllocatedStorage: !If [IsProd, '100', '20']
      StorageEncrypted: true
      MasterUsername: dbadmin
      MasterUserPassword: !Ref DBPassword
      DBName: !Sub '${ProjectName}'
      BackupRetentionPeriod: !If [IsProd, 30, 7]
      DeletionProtection: !If [IsProd, true, false]

Conditions:
  IsProd: !Equals [!Ref Environment, 'prod']

Outputs:
  ECRRepositoryUri:
    Value: !GetAtt ECRRepository.RepositoryUri
  ECSClusterName:
    Value: !Ref ECSCluster
  RDSEndpoint:
    Value: !GetAtt RDSInstance.Endpoint.Address
```

---

## 4. CI/CD: GitHub Actions

```yaml
# .github/workflows/deploy-aws.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: [project-name]/[environment]

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

      - run: go test ./... -race

  build-image:
    runs-on: ubuntu-latest
    needs: build-and-test
    outputs:
      image-uri: ${{ steps.build.outputs.image-uri }}
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image
        id: build
        env:
          ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image-uri=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

  deploy:
    runs-on: ubuntu-latest
    needs: build-image
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Apply
        run: |
          cd terraform
          terraform init
          terraform apply \
            -var="project_name=[project-name]" \
            -var="environment=prod" \
            -var="container_image=${{ needs.build-image.outputs.image-uri }}" \
            -auto-approve
```

---

## 5. Deployment Checklist

### Pre-Deployment

- [ ] S3 bucket para Terraform state creado con versionado
- [ ] DynamoDB table para state locking creado
- [ ] ECR repository creado
- [ ] RDS DB subnet group creado
- [ ] RDS parameter group creado (con max_connections configurado)
- [ ] Secrets Manager entries creado (db connection, jwt secret)
- [ ] IAM roles y policies creados
- [ ] OIDC provider en AWS IAM creado para GitHub

### During Deployment

- [ ] `terraform plan` ejecutado y revisado sin errores
- [ ] Container image construida y pusheada a ECR
- [ ] `terraform apply` ejecutado sin errores
- [ ] ECS service en estado "RUNNING"
- [ ] ALB health checks pasando (target group: healthy)
- [ ] CloudWatch logs mostrando output de la app
- [ ] Health check `GET /health` responde 200

### Post-Deployment

- [ ] CloudWatch alarms configuradas (uptime, error rate, DB connections)
- [ ] Auto Scaling tested con carga simulada
- [ ] Database backups verificados
- [ ] S3 frontend deployado (si es full-stack)
- [ ] CloudFront cache cleared

---

## 6. Rollback Strategy

### Rollback ECS Fargate

```bash
# Actualizar ECS service con task definition anterior
aws ecs update-service \
  --cluster [cluster-name] \
  --service [service-name] \
  --task-definition [task-definition-family]:[PREVIOUS_REVISION] \
  --region us-east-1
```

### Rollback S3/CloudFront (React)

```bash
# Restaurar desde versión anterior
aws s3 sync s3://[backup-bucket]/[previous-version]/ \
  s3://[project-name]-[env]-frontend-[account-id]/

# Invalidar CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id [DIST_ID] \
  --paths "/*"
```

---

**Document Owner:** [Infrastructure Lead]
**Last Updated:** [YYYY-MM-DD]
**Ref:** `../../references/cloud-standards.md` + `../../references/security-rules.md`
