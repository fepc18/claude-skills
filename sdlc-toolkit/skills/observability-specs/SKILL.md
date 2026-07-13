---
name: observability-specs
description: Genera estrategias completas de observabilidad incluyendo logging estructurado (zerolog), métricas (Prometheus/CloudWatch/Azure Monitor), alertas con thresholds, dashboards (Grafana/Azure), SLO/SLI targets, health checks y distributed tracing con OpenTelemetry. Zero PII en logs.
model_invoked: true
triggers:
  - observability
  - observabilidad
  - monitoring
  - monitoreo
  - alertas
  - alerts
  - logging strategy
  - estrategia de logging
  - dashboards
  - métricas
  - metrics
  - slo
  - sli
  - distributed tracing
  - grafana
  - prometheus
  - datadog
  - azure monitor
  - cloudwatch
  - application insights
  - health checks
  - error tracking
  - rastreo distribuido
---

# Observability Specs Skill

## Purpose

Generate comprehensive observability strategies covering structured logging, metrics collection, distributed tracing, alerting rules, SLO/SLI definitions, and cloud-platform-specific dashboard setup. This skill produces:
- Structured logging configuration (zerolog for Golang, console for React)
- Metrics strategy (Prometheus counters, histograms, custom business metrics)
- Health check endpoints and readiness probes
- Alert rules with thresholds (error rate, latency p99, pod restarts)
- SLO/SLI targets (uptime, latency, error rate)
- Cloud-specific configuration (Azure Application Insights / AWS CloudWatch / DigitalOcean Prometheus+Grafana)
- Distributed tracing setup (OpenTelemetry)
- Grafana dashboards (JSON exportable)
- Log retention & compliance policy
- CI/CD integration for observability

This bridges the gap between deployment infrastructure and production visibility.

## Workflow

### 1. Technology Stack

Ask the user:
- "Which stack are you generating observability specs for?" (Golang backend / React frontend / Full-Stack)

### 2. Cloud Platform

Ask the user:
- "Which cloud platform are you deploying to?" (Azure / AWS / DigitalOcean / Multi-cloud)
- This determines:
  - Azure → Application Insights + Azure Monitor + Log Analytics
  - AWS → CloudWatch + X-Ray + EventBridge
  - DigitalOcean → Prometheus + Grafana + DigitalOcean Managed Databases

### 3. Compliance Requirements

Ask the user:
- "Do you have compliance requirements?" (GDPR / HIPAA / SOC2 / PCI-DSS / None)
- This affects:
  - Log retention period (30-90 days)
  - PII handling (zero-PII rule per security-rules.md)
  - Audit logging requirements
  - Data residency constraints

### 4. SLO Targets

Ask the user:
- "What are your reliability targets?"
  - Uptime: default 99.9% (allow ~43 minutes/month downtime)
  - API Latency p99: default <200ms
  - Error Rate: default <1%
  - Page Load Time (React): default <2s
  - Core Web Vitals (React): LCP <2.5s, INP <200ms, CLS <0.1

### 5. Generate & Deployment Bridge

Generate complete observability spec with:
- Logging configuration and examples
- Metrics to collect (list of counters, histograms, gauges)
- Health check code stubs
- Alert rule definitions
- SLO/SLI documentation
- Cloud-specific setup steps
- Dashboard JSON for Grafana/Azure
- Log retention policy
- CI/CD integration checklist

Then ask:
"Ready to integrate this into your deployment pipeline? I can also update deployment-specs with observability monitoring hooks if needed."

## Template Structure

### `assets/golang-observability-spec.md`

Sections:
1. **Observability Architecture** — 4 pillars (Logging → Metrics → Tracing → Alerting)
2. **Structured Logging** — zerolog config, required fields, JSON format examples, PII checklist
3. **Prometheus Metrics** — counter/histogram/gauge definitions, business metrics, target scrape config
4. **Health Check Endpoints** — `/health` (liveness on port 8081) and `/ready` (readiness) with Go code
5. **Cloud-Specific Config** — Azure App Insights / AWS CloudWatch / DigitalOcean Prometheus
6. **Distributed Tracing** — OpenTelemetry SDK setup (jaeger exporter)
7. **Alert Rules** — thresholds for error rate >1%, p99 >500ms, pod restarts >3
8. **Grafana Dashboard** — JSON exportable with panels for request rate, error rate, latency p50/p99, throughput
9. **SLO/SLI Definitions** — Uptime, latency, error rate with error budgets
10. **Log Retention & Compliance** — 30-90 days retention, GDPR/HIPAA requirements
11. **CI/CD Integration** — how to configure observability in GitHub Actions or Azure DevOps
12. **Observability Checklist** — verification points before going to production

### `assets/react-observability-spec.md`

Sections:
1. **Frontend Observability Strategy** — challenges, pillars (Errors → Metrics → Tracing → Analytics)
2. **Error Boundary Implementation** — React component code with error reporting integration
3. **React Query Error Handling** — retry strategies, error callbacks
4. **Core Web Vitals** — LCP <2.5s, INP <200ms, CLS <0.1 with web-vitals library
5. **Error Reporting** — Sentry / Azure App Insights / DataDog integration snippets
6. **User Analytics** — anonymous event tracking (no PII), key funnels to track
7. **Console Log Management** — dev vs prod, structured error logging
8. **Frontend SLO** — page load time <2s, error rate <0.1%, interaction responsiveness
9. **Real User Monitoring (RUM)** — Azure App Insights RUM setup, custom events
10. **CI/CD Integration** — Lighthouse CI, bundle size alerts, performance budgets
11. **Frontend Observability Checklist** — verification before deployment

## Reference Standards Integration

### Golang

- ✅ Structured logging with zerolog (JSON format)
- ✅ Health endpoints on port 8081 (`/health` liveness, `/ready` readiness)
- ✅ Zero PII in logs (no emails, passwords, tokens, user IDs)
- ✅ Context propagation for distributed tracing (trace IDs in logs)
- ✅ Metrics per golang-standards.md conventions
- ✅ Alert rules with actionable thresholds
- ✅ OpenTelemetry for distributed tracing across services

### React

- ✅ Error Boundary for unhandled errors
- ✅ Core Web Vitals tracking (LCP, INP, CLS)
- ✅ Error reporting integration (Sentry, App Insights, or DataDog)
- ✅ User analytics without PII (anonymous IDs, device type, browser)
- ✅ React Query error callbacks
- ✅ Console logging disabled in production
- ✅ Page load monitoring via performance API
- ✅ RUM setup for real user monitoring

### Cloud & Compliance

- ✅ Logging: JSON structured, indexed for querying
- ✅ Retention: Compliant with GDPR (30+ days), HIPAA (7 years), SOC2 (1 year+)
- ✅ Data Residency: Cloud-specific (Azure = EU, AWS = region-specific, DO = regional)
- ✅ Alerting: PagerDuty/Slack/Email integration ready
- ✅ Dashboards: Searchable, time-series enabled, exportable

## Quality Checklist

Before returning the observability spec to the user:

**Golang:**
- ✅ zerolog config provided with JSON format
- ✅ Health check handlers implemented (200 OK logic shown)
- ✅ Readiness probe checks DB connectivity
- ✅ Metrics defined: request_duration_seconds, requests_total, errors_total, active_connections
- ✅ Alert rules have actionable thresholds (not too strict, not too loose)
- ✅ Error budget calculation shown (e.g., 99.9% = 43 minutes/month)
- ✅ Log retention policy documented with compliance rationale
- ✅ OpenTelemetry SDK setup with jaeger exporter shown
- ✅ Cloud-specific examples (env vars, SDK init) provided
- ✅ PII checklist included (no emails, passwords, tokens logged)

**React:**
- ✅ Error Boundary TSX code provided
- ✅ Core Web Vitals collection with web-vitals library
- ✅ Error reporting integration snippet (Sentry or App Insights)
- ✅ Analytics events defined (page_view, feature_click, error_reported)
- ✅ RUM configuration shown
- ✅ Lighthouse CI config example
- ✅ Performance budget defined (initial JS <200kb, CSS <100kb)
- ✅ Console logging disabled in production (process.env.NODE_ENV check)

**Both:**
- ✅ SLO/SLI targets are realistic and measurable
- ✅ All code examples are production-ready (not pseudocode)
- ✅ Alert rules reference actual metrics defined in spec
- ✅ Dashboard panels align with SLOs
- ✅ Compliance requirements are explicitly addressed

## Interaction Examples

### Example 1: Golang Backend — AWS Deployment

**User:** "I need observability for my Golang microservice on AWS"

**Stack:** Golang
**Cloud:** AWS
**Compliance:** SOC2 (1-year retention)
**SLOs:** 99.9% uptime, p99 latency <300ms, error rate <0.5%

**Spec Generated Includes:**
1. zerolog config with JSON formatter
2. Prometheus metrics: request_duration_seconds (histogram), requests_total (counter), errors_total (counter)
3. Health check: GET /health returns {"status":"ok"} on 200
4. Readiness check: GET /ready checks DB connection, cache connection
5. AWS CloudWatch setup: Logs group, metrics namespace, custom metrics via SDK
6. OpenTelemetry with AWS X-Ray exporter (traces all requests)
7. CloudWatch Alarms:
   - ErrorRate > 0.5% for 5 minutes → SNS → PagerDuty
   - Latency p99 > 300ms for 10 minutes → SNS → Slack
   - Pod restarts > 3 in 1 hour → SNS → Email
8. CloudWatch Dashboard: 4 panels (request rate, error rate, latency histogram, throughput)
9. SLO tracking: 99.9% uptime = 43 minutes/month error budget
10. Logs in CloudWatch: /aws/[service-name]/ with 1-year retention (SOC2)

### Example 2: React Frontend — Azure Deployment

**User:** "I need observability for my React SPA on Azure"

**Stack:** React
**Cloud:** Azure
**Compliance:** GDPR (30-day retention)
**SLOs:** Page load <2s, error rate <0.1%, CLS <0.1

**Spec Generated Includes:**
1. Error Boundary component with Azure App Insights integration
2. Core Web Vitals tracking (LCP, INP, CLS) via web-vitals library
3. React Query error callbacks → App Insights trackException
4. Azure App Insights RUM setup: connectionString, trackPageView on route change
5. Analytics events:
   - page_load: timestamp, URL, referrer (no user ID)
   - feature_interact: feature_name, component_name
   - error: error_message, stack_trace (no PII)
6. Lighthouse CI config: budget.json with JS <200kb, CSS <100kb, LCP <2.5s
7. Azure Dashboard: 4 panels (page load time, error rate, Core Web Vitals, unique users)
8. SLO tracking: Page load <2s means 95%+ requests complete in time
9. Logs in Azure: 30-day retention (GDPR compliant)

### Example 3: Full-Stack — DigitalOcean

**User:** "Full-stack app on DigitalOcean with Prometheus monitoring"

**Stack:** Full-Stack (Golang + React)
**Cloud:** DigitalOcean
**Compliance:** None (30-day default)
**SLOs:** Uptime 99.5%, API p99 <250ms, Frontend load <2.5s

**Spec Generated Includes:**

**Backend (Golang):**
- zerolog setup with JSON format
- Prometheus metrics exposed on :8080/metrics
- Health endpoints: /health (port 8081), /ready (port 8081)
- Prometheus scrape config: every 15 seconds
- Alert rules: error_rate > 0.5%, latency_p99 > 250ms

**Frontend (React):**
- Error Boundary with Grafana Loki integration
- Core Web Vitals tracking
- Loki log integration (using pino-transport-loki)
- Lighthouse CI on deployments

**Observability Stack (DigitalOcean App Platform):**
- Prometheus instance: scrapes backend metrics on :8080/metrics
- Grafana: visualizes Prometheus data
- Loki: aggregates frontend + backend logs
- AlertManager: fires alerts to Slack on threshold breach
- Dashboard: unified view across backend + frontend

## Refinement Workflow

If the user asks for adjustments:
- "Which part would you like to refine?" (logging strategy, metrics definitions, alerting rules, SLO targets, cloud setup)
- Edit and re-display affected sections
- Ask: "Better? Ready to integrate into your deployment pipeline?"
- Offer to add additional dashboards, custom metrics, or compliance audits

## Dependencies & Context

**Used by:** After deployment-specs (Stage 8), as optional Stage 8.5 for production visibility
**Feeds into:** Monitoring dashboards, alerting system, SLO tracking in production
**References:**
- `../../references/cloud-standards.md` (health endpoints port 8081, zero PII in logs)
- `../../references/security-rules.md` (PII handling, audit logging)
- `../../references/golang-standards.md` (logging patterns, middleware)
- `../../references/react-standards.md` (error boundaries, hooks for metrics)

**Output location:** `/sessions/[session-id]/mnt/outputs/[project-name]-observability-specs.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with configuration examples, alert rules, dashboard JSON, and checklist
