# Observability Specs: [ProjectName] (Golang)

## 1. Observability Architecture

Four pillars of production visibility:

```
┌─────────────────────────────────────────────────────────────┐
│                  PRODUCTION VISIBILITY PILLARS              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. LOGGING                2. METRICS                        │
│     ├─ Structured JSON        ├─ Request rate               │
│     ├─ Trace context          ├─ Latency (p50/p99)         │
│     ├─ Request/response       ├─ Error rate                │
│     └─ Zero PII               └─ Business metrics           │
│                                                               │
│  3. TRACING                4. ALERTING                       │
│     ├─ Request path           ├─ Error rate > 1%           │
│     ├─ Service boundaries     ├─ p99 latency > 500ms       │
│     ├─ Database queries       ├─ Pod restarts > 3          │
│     └─ External APIs          └─ Health check failures      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

Flow:
- Application → Structured Logs (JSON) → Log aggregation (CloudWatch/Loki)
- Application → Prometheus metrics → Metrics DB (Prometheus/CloudWatch)
- Application → Trace exports → Trace backend (Jaeger/X-Ray)
- Metrics + Rules → Alert manager → Notification (PagerDuty/Slack/Email)
- Logs + Metrics + Traces → Dashboard (Grafana/Azure Monitor)

---

## 2. Structured Logging (zerolog)

### Configuration

```go
// internal/infrastructure/logger/logger.go
package logger

import (
	"io"
	"os"
	"time"

	"github.com/rs/zerolog"
)

func NewLogger(serviceName string) zerolog.Logger {
	output := io.MultiWriter(os.Stdout)

	logger := zerolog.New(output).
		With().
		Timestamp().
		Str("service", serviceName).
		Str("environment", os.Getenv("ENVIRONMENT")).
		Logger()

	return logger
}

// Usage in main.go:
// log := logger.NewLogger("my-service")
// log.Info().Msg("service started")
```

### Required Fields (Always Include)

Every log entry MUST include:
- `timestamp` — ISO 8601 format (automatic with Timestamp())
- `level` — debug, info, warn, error, fatal
- `service` — application name
- `trace_id` — for distributed tracing (optional but recommended)
- `message` — human-readable message

### Example Log Entries

```json
{"level":"info","timestamp":"2026-07-12T14:30:45Z","service":"user-api","message":"request processed","request_id":"req-123","path":"/api/users","method":"GET","status":200,"duration_ms":45}
{"level":"error","timestamp":"2026-07-12T14:30:46Z","service":"user-api","message":"database connection failed","error":"connection timeout","retry_count":3,"duration_ms":5000}
{"level":"warn","timestamp":"2026-07-12T14:30:47Z","service":"user-api","message":"slow database query detected","query_type":"select_users","duration_ms":750}
```

### PII Checklist (ZERO PII Rule)

❌ DO NOT LOG:
- Email addresses
- Phone numbers
- Password hashes or tokens
- Social Security Numbers or Tax IDs
- Credit card numbers
- IP addresses of users
- User IDs (use hashed ID or request ID instead)
- Personal names

✅ DO LOG:
- Request IDs (generated UUIDs)
- Trace IDs (correlation across services)
- Error types and codes (not messages with PII)
- Request paths (without query params containing secrets)
- HTTP methods and status codes
- Service names and versions
- Database query types (not full query text with parameters)

### Implementation in Handlers

```go
// internal/interface/http/user_handler.go
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	requestID := r.Context().Value("request_id").(string)
	log := h.logger.With().Str("request_id", requestID).Logger()

	userID := chi.URLParam(r, "id")
	log.Debug().Str("user_id", userID).Msg("getting user")

	user, err := h.getUserUC.Execute(r.Context(), userID)
	if err != nil {
		log.Error().Err(err).Str("error_type", "user_not_found").Msg("failed to get user")
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	log.Info().Str("user_id", userID).Msg("user retrieved successfully")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}
```

---

## 3. Prometheus Metrics

### Metrics to Collect

| Metric | Type | Labels | Purpose |
|--------|------|--------|---------|
| `http_requests_total` | Counter | method, path, status | Total requests by endpoint |
| `http_request_duration_seconds` | Histogram | method, path | Request latency (p50, p95, p99) |
| `http_errors_total` | Counter | method, status | HTTP errors by type |
| `db_connection_pool_active` | Gauge | — | Active database connections |
| `db_query_duration_seconds` | Histogram | query_type | Database query latency |
| `cache_hits_total` | Counter | cache_name | Cache hits by name |
| `cache_misses_total` | Counter | cache_name | Cache misses by name |

### Implementation with go-kit/kit/metrics

```go
// internal/infrastructure/metrics/metrics.go
package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

type Metrics struct {
	HTTPRequestsTotal      prometheus.Counter
	HTTPRequestDuration    prometheus.Histogram
	HTTPErrors             prometheus.Counter
	DBConnectionPoolActive prometheus.Gauge
	DBQueryDuration        prometheus.Histogram
}

func NewMetrics() *Metrics {
	return &Metrics{
		HTTPRequestsTotal: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_requests_total",
				Help: "Total HTTP requests",
			},
			[]string{"method", "path", "status"},
		),
		HTTPRequestDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "http_request_duration_seconds",
				Help:    "HTTP request latency",
				Buckets: []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
			},
			[]string{"method", "path"},
		),
		HTTPErrors: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_errors_total",
				Help: "Total HTTP errors",
			},
			[]string{"method", "status"},
		),
		DBConnectionPoolActive: promauto.NewGauge(
			prometheus.GaugeOpts{
				Name: "db_connection_pool_active",
				Help: "Active database connections",
			},
		),
		DBQueryDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "db_query_duration_seconds",
				Help:    "Database query latency",
				Buckets: []float64{.001, .005, .01, .025, .05, .1, .25, .5, 1},
			},
			[]string{"query_type"},
		),
	}
}
```

### Prometheus Scrape Config

```yaml
# prometheus.yml
scrape_configs:
  - job_name: '[service-name]'
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: '/metrics'
    static_configs:
      - targets: ['localhost:8080']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
```

---

## 4. Health Check Endpoints

### Liveness Probe: `/health`

Returns 200 OK if service can respond to requests (do NOT check dependencies).

```go
// internal/interface/http/health_handler.go
func (h *HealthHandler) Liveness(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status": "ok",
		"timestamp": time.Now().UTC(),
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
```

### Readiness Probe: `/ready`

Returns 200 OK only if ALL dependencies (DB, cache, external APIs) are accessible.

```go
// internal/interface/http/health_handler.go
func (h *HealthHandler) Readiness(w http.ResponseWriter, r *http.Request) {
	checks := map[string]bool{
		"database": h.repo.HealthCheck(r.Context()),
		"cache":    h.cache.Ping(r.Context()),
	}

	allHealthy := true
	for _, status := range checks {
		if !status {
			allHealthy = false
			break
		}
	}

	response := map[string]interface{}{
		"ready": allHealthy,
		"checks": checks,
		"timestamp": time.Now().UTC(),
	}

	statusCode := http.StatusOK
	if !allHealthy {
		statusCode = http.StatusServiceUnavailable
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}
```

### Router Setup

```go
// internal/interface/http/router.go
func NewRouter(handlers *Handlers) *chi.Mux {
	r := chi.NewRouter()

	// Health endpoints (no middleware)
	r.Get("/health", handlers.Health.Liveness)
	r.Get("/ready", handlers.Health.Readiness)

	// Metrics endpoint
	r.Handle("/metrics", promhttp.Handler())

	// Other routes with middleware
	r.Group(func(r chi.Router) {
		r.Use(middleware.Logger(logger))
		r.Use(middleware.Recovery(logger))
		// ... API routes
	})

	return r
}
```

### Health Check Testing

```bash
# Liveness (should always return 200)
curl -s http://localhost:8081/health | jq .

# Readiness (returns 200 if all deps OK, 503 if any dep down)
curl -s http://localhost:8081/ready | jq .
```

---

## 5. Cloud-Specific Configuration

### Azure Application Insights

```go
// internal/infrastructure/observability/azure_insights.go
package observability

import (
	"github.com/microsoft/ApplicationInsights-Go/appinsights"
	"github.com/microsoft/ApplicationInsights-Go/appinsights/config"
)

func InitAzureInsights(instrumentationKey string) appinsights.TelemetryClient {
	cfg := config.NewConfig()
	cfg.InstrumentationKey = instrumentationKey

	client := appinsights.NewTelemetryClientFromConfig(cfg)
	client.Context().Tags.Common.User.ID = "anonymous" // zero PII
	return client
}

// Usage in handler:
// client.TrackRequest(r.Method, r.URL.Path, time.Now(), duration, "200", true)
// client.TrackException(err)
```

Environment variables:
```
APPLICATIONINSIGHTS_INSTRUMENTATION_KEY=xxxxx
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=xxxxx;IngestionEndpoint=https://[region].in.applicationinsights.azure.com/
```

### AWS CloudWatch

```go
// internal/infrastructure/observability/cloudwatch.go
package observability

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/aws/aws-sdk-go/service/logs"
)

func InitCloudWatchLogs(serviceName string) *logs.CloudWatchLogs {
	sess := session.Must(session.NewSession())
	client := logs.New(sess)

	// Log group already exists (created by terraform)
	logGroupName := "/aws/lambda/" + serviceName
	_ = logGroupName // use in PutLogEvents

	return client
}
```

Environment variables:
```
AWS_REGION=us-east-1
AWS_CLOUDWATCH_LOG_GROUP=/aws/[service-name]
```

### DigitalOcean Prometheus + Grafana

```yaml
# terraform/monitoring.tf
resource "digitalocean_app" "prometheus" {
  name             = "monitoring-stack"
  region           = "nyc3"

  service {
    name               = "prometheus"
    github {
      branch = "main"
      repo   = "my-org/monitoring"
    }
  }

  service {
    name               = "grafana"
    github {
      branch = "main"
      repo   = "my-org/monitoring"
    }
  }
}
```

Prometheus scrape config:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: '[service-name]'
    static_configs:
      - targets: ['app.ondigitalocean.app:8080']
```

---

## 6. Distributed Tracing (OpenTelemetry)

### Installation

```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/exporters/jaeger/jaegergrpc
go get go.opentelemetry.io/otel/sdk/trace
go get go.opentelemetry.io/otel/instrumentation/net/http/otelhttp
```

### Setup in main.go

```go
// cmd/server/main.go
import (
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/jaeger/jaegergrpc"
	"go.opentelemetry.io/otel/sdk/trace"
)

func initTracing(serviceName string) (*trace.TracerProvider, error) {
	exporter, err := jaegergrpc.New(
		context.Background(),
		jaegergrpc.WithEndpoint(os.Getenv("JAEGER_ENDPOINT")),
	)
	if err != nil {
		return nil, err
	}

	tp := trace.NewTracerProvider(
		trace.WithBatcher(exporter),
		trace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(serviceName),
			semconv.ServiceVersionKey.String("1.0.0"),
		)),
	)

	otel.SetTracerProvider(tp)
	return tp, nil
}

// In main():
tp, _ := initTracing("[service-name]")
defer tp.Shutdown(context.Background())
```

### Middleware Integration

```go
// pkg/middleware/tracing.go
func TracingMiddleware(tracer trace.Tracer) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx, span := tracer.Start(r.Context(), r.URL.Path,
				trace.WithAttributes(
					attribute.String("http.method", r.Method),
					attribute.String("http.url", r.URL.String()),
				),
			)
			defer span.End()

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
```

---

## 7. Alert Rules

Alerting logic for Prometheus or cloud-specific alerting services.

### Error Rate Alert

```yaml
# prometheus/alerts.yml
groups:
  - name: service_alerts
    rules:
      - alert: HighErrorRate
        expr: (sum(rate(http_errors_total[5m])) / sum(rate(http_requests_total[5m]))) > 0.01
        for: 5m
        annotations:
          summary: "Error rate above 1% for {{ $labels.service }}"
          description: "Error rate: {{ $value | humanizePercentage }}"
```

### Latency Alert (p99 > 500ms)

```yaml
      - alert: HighLatency
        expr: histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path)) > 0.5
        for: 10m
        annotations:
          summary: "p99 latency above 500ms for {{ $labels.path }}"
          description: "p99 latency: {{ $value }}s"
```

### Pod Restart Alert

```yaml
      - alert: PodRestarts
        expr: increase(kube_pod_container_status_restarts_total[1h]) > 3
        for: 5m
        annotations:
          summary: "Pod restarted {{ $value }} times in last hour"
```

### Database Connection Pool Alert

```yaml
      - alert: HighDBConnections
        expr: db_connection_pool_active > 80
        for: 5m
        annotations:
          summary: "Database connection pool at {{ $value }}% capacity"
```

---

## 8. Grafana Dashboard

### Dashboard JSON (for Grafana 9.x+)

```json
{
  "dashboard": {
    "title": "[ProjectName] Monitoring",
    "description": "Production metrics and health overview",
    "timezone": "UTC",
    "panels": [
      {
        "title": "Request Rate (req/s)",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (method)"
          }
        ]
      },
      {
        "title": "Error Rate (%)",
        "targets": [
          {
            "expr": "(sum(rate(http_errors_total[5m])) / sum(rate(http_requests_total[5m]))) * 100"
          }
        ]
      },
      {
        "title": "Latency p99 (ms)",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) * 1000"
          }
        ]
      },
      {
        "title": "Active Connections",
        "targets": [
          {
            "expr": "db_connection_pool_active"
          }
        ]
      }
    ]
  }
}
```

### Azure Dashboard (Azure Monitor)

```json
{
  "version": "1.0.0",
  "items": [
    {
      "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
      "settings": {
        "content": {
          "Query": "customMetrics | where name == 'http_requests_total' | summarize Count=sum(value) by tostring(customDimensions.method)"
        }
      }
    }
  ]
}
```

---

## 9. SLO/SLI Definitions

### Service Level Objectives (SLO)

| Objective | Target | Error Budget |
|-----------|--------|--------------|
| **Availability** | 99.9% uptime | 43.2 minutes/month |
| **Latency (p99)** | < 200ms | Allow 1% of requests above 200ms |
| **Error Rate** | < 1% | Allow 1 error per 100 requests |

### Service Level Indicators (SLI)

Measurable metrics that indicate SLO compliance:

```
SLI(Availability) = (Successful Requests) / (Total Requests)
                  = (requests with status 2xx, 3xx) / (all requests)

SLI(Latency) = (Requests < 200ms p99) / (Total Requests)
             = histogram_quantile(0.99, ...) < 0.2

SLI(ErrorRate) = (Requests with status 5xx) / (Total Requests)
               = (http_errors_total{status=~"5xx"}) / (http_requests_total)
```

### Error Budget Tracking

With 99.9% SLO over 30 days:
- Error budget = 0.1% × 30 days = 43.2 minutes
- Current downtime: sum(unavailable_minutes)
- Remaining budget: 43.2 - sum(unavailable_minutes)

If error budget exhausted:
1. Only critical bugs fixed
2. Feature development paused
3. Focus shifts to stability/reliability

---

## 10. Log Retention & Compliance

### Retention Policy by Compliance

| Compliance | Retention | Archival | Deletion |
|-----------|-----------|----------|----------|
| **GDPR** | 30 days | Cold storage 90 days | Auto-delete after 1 year |
| **HIPAA** | 6 years | Required | After 6 years + 6 months |
| **SOC2** | 1 year | 7 years available | After 7 years |
| **PCI-DSS** | 1 year | 3 months in hot storage | After 1 year + 3 months |

### Azure Log Analytics Retention

```terraform
# terraform/monitoring.tf
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "logs-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  retention_in_days = 30 # GDPR compliant
}
```

### AWS CloudWatch Log Retention

```terraform
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/[service-name]"
  retention_in_days = 30
}
```

### PII Removal Policy

Before any log export or archival:
1. Scan logs for PII patterns (email regex, SSN patterns, credit card patterns)
2. Redact or remove offending entries
3. Encrypt before storing in cold storage
4. Document all redactions for audit trail

---

## 11. CI/CD Integration

### GitHub Actions Observability Setup

```yaml
# .github/workflows/deploy.yml
name: Deploy with Observability

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build and Test
        run: go test ./... -v

      - name: Push Docker Image
        run: |
          docker build -t my-service:${{ github.sha }} .
          docker push my-service:${{ github.sha }}

      - name: Deploy to Azure
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
        run: terraform apply -auto-approve

      - name: Wait for Health Check
        run: |
          for i in {1..30}; do
            curl -f http://my-service.azurewebsites.net/ready && break
            sleep 10
          done

      - name: Verify Metrics Ingestion
        run: |
          curl -s http://prometheus:9090/api/v1/query?query='up{job="my-service"}'
```

### Azure DevOps Pipeline Observability

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: BuildApp
        steps:
          - task: Go@0
            inputs:
              version: '1.21'
          - script: go test ./... -v
            displayName: 'Run Tests'

  - stage: Deploy
    jobs:
      - deployment: DeployAzure
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformTaskV4@4
                  inputs:
                    command: 'apply'
                - script: |
                    sleep 30
                    curl -f https://[app].azurewebsites.net/ready
                  displayName: 'Health Check'
                - task: PublishCodeCoverageResults@1
                  inputs:
                    codeCoverageTool: 'Cobertura'
                    summaryFileLocation: 'coverage.xml'
```

---

## 12. Observability Checklist

Before deploying to production:

**Logging:**
- [ ] zerolog configured with JSON output
- [ ] All handlers log with request ID
- [ ] No PII in any logs (run audit scan)
- [ ] Log retention policy documented
- [ ] Log sampling configured (for high-volume services)

**Metrics:**
- [ ] Prometheus scrape config defined
- [ ] http_requests_total, http_request_duration_seconds, http_errors_total exported
- [ ] Custom business metrics defined
- [ ] Metric labels don't contain PII
- [ ] Metrics endpoint `/metrics` accessible on :8080

**Health Checks:**
- [ ] GET /health returns 200 (liveness check)
- [ ] GET /ready returns 200 only when all deps healthy
- [ ] Health checks on port 8081 (separate from app)
- [ ] Kubernetes/orchestrator configured to use these endpoints

**Tracing:**
- [ ] OpenTelemetry SDK initialized
- [ ] Trace ID propagated to logs
- [ ] Jaeger/X-Ray exporter configured
- [ ] Database queries include span attributes

**Alerting:**
- [ ] Alert rules defined for: error rate > 1%, p99 latency > 500ms, pod restarts > 3
- [ ] Notification channels configured (PagerDuty/Slack/Email)
- [ ] Alert testing completed
- [ ] Runbook links added to alert annotations

**SLO/SLI:**
- [ ] SLO targets documented (uptime, latency, error rate)
- [ ] SLI queries verified in Prometheus/CloudWatch
- [ ] Error budget calculation shown
- [ ] SLO tracking dashboard created

**Dashboards:**
- [ ] Grafana/Azure Monitor dashboard created
- [ ] 4+ panels showing key metrics (request rate, error rate, latency, connections)
- [ ] Dashboard linked from runbooks
- [ ] Auto-refresh configured (30s or 1m)

**Compliance:**
- [ ] Log retention policy enforced
- [ ] PII audit completed
- [ ] Data residency compliant (for GDPR/HIPAA)
- [ ] Encryption in transit (TLS 1.3) and at rest enabled
- [ ] Audit logging enabled for compliance framework

**CI/CD:**
- [ ] Deployment includes health check wait step
- [ ] Metrics ingestion verified post-deploy
- [ ] Rollback procedure tested
- [ ] On-call documentation updated
