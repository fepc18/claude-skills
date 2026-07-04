# Technical Specification: [Feature Name] (Golang Backend)

**Version:** 1.0
**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Status:** Draft / In Review / Approved

---

## 1. Package Structure & Layering

**Ref:** `../../references/clean-architecture.md` + `../../references/golang-standards.md`

**Directory Layout:**
```
project-name/
├── cmd/
│   └── server/
│       └── main.go              ← Entry point, dependency injection
├── internal/
│   ├── domain/                  ← Business logic (innermost)
│   │   ├── [entity].go          ← Entity definition + domain methods
│   │   ├── [entity]_repository.go ← Repository interface
│   │   └── [entity]_service.go  ← Domain service
│   ├── application/             ← Use cases & orchestration
│   │   ├── create_[entity].go   ← Use case handler
│   │   ├── update_[entity].go
│   │   └── delete_[entity].go
│   ├── infrastructure/          ← Concrete implementations
│   │   ├── repository/
│   │   │   ├── postgres_[entity]_repository.go
│   │   │   └── in_memory_[entity]_repository.go (for testing)
│   │   ├── http/
│   │   │   ├── router.go        ← Chi router setup
│   │   │   └── middleware.go    ← Auth, logging, CORS
│   │   └── logger/
│   │       └── zerolog_logger.go
│   └── interface/               ← HTTP handlers (outermost)
│       └── http/
│           ├── [entity]_handler.go ← HTTP endpoint handlers
│           └── error_response.go
├── migrations/                  ← Database migrations
│   ├── 001_create_[entities]_table.up.sql
│   └── 001_create_[entities]_table.down.sql
├── go.mod
├── go.sum
├── Dockerfile
└── docker-compose.yml
```

**Layer Responsibilities:**

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| Domain | Pure business logic, entities, value objects, interfaces | User entity, UserRepository interface, CreateUserService |
| Application | Use cases, orchestration, input validation | CreateUserUseCase, UpdateUserUseCase |
| Infrastructure | Concrete implementations of interfaces | PostgresUserRepository, ZerologLogger |
| Interface | HTTP handlers, request/response translation | UserHandler, middleware |

---

## 2. API Contract (OpenAPI 3.0)

**Specification Format:** OpenAPI YAML

```yaml
openapi: 3.0.0
info:
  title: [Service Name] API
  version: 1.0.0
  description: '[Feature] microservice'

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: http://localhost:8080/v1
    description: Development

paths:
  /[entities]:
    get:
      summary: List [entities]
      operationId: list[Entities]
      tags:
        - [Entity]
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
          description: Max results per page
        - name: offset
          in: query
          schema:
            type: integer
            default: 0
          description: Pagination offset
      security:
        - bearerAuth: []
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  items:
                    type: array
                    items:
                      $ref: '#/components/schemas/[Entity]'
                  total:
                    type: integer
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'

    post:
      summary: Create [entity]
      operationId: create[Entity]
      tags:
        - [Entity]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Create[Entity]Request'
      security:
        - bearerAuth: []
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/[Entity]'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
                  details:
                    type: object
                    additionalProperties: true
        '401':
          $ref: '#/components/responses/Unauthorized'
        '409':
          description: Conflict (e.g., email already exists)
        '500':
          $ref: '#/components/responses/InternalError'

  /[entities]/{id}:
    get:
      summary: Get [entity] by ID
      operationId: get[Entity]
      tags:
        - [Entity]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      security:
        - bearerAuth: []
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/[Entity]'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          description: Not found
        '500':
          $ref: '#/components/responses/InternalError'

    put:
      summary: Update [entity]
      operationId: update[Entity]
      tags:
        - [Entity]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Update[Entity]Request'
      security:
        - bearerAuth: []
      responses:
        '200':
          description: Updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/[Entity]'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

    delete:
      summary: Delete [entity]
      operationId: delete[Entity]
      tags:
        - [Entity]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      security:
        - bearerAuth: []
      responses:
        '204':
          description: Deleted successfully
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalError'

components:
  schemas:
    [Entity]:
      type: object
      required:
        - id
        - [field1]
        - [field2]
        - created_at
        - updated_at
      properties:
        id:
          type: string
          format: uuid
        [field1]:
          type: string
          description: '[Description]'
        [field2]:
          type: integer
          description: '[Description]'
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time

    Create[Entity]Request:
      type: object
      required:
        - [field1]
      properties:
        [field1]:
          type: string
          minLength: 1
          maxLength: 255
        [field2]:
          type: integer
          minimum: 1

    Update[Entity]Request:
      type: object
      properties:
        [field1]:
          type: string
          minLength: 1
          maxLength: 255
        [field2]:
          type: integer
          minimum: 1

  responses:
    Unauthorized:
      description: Unauthorized (missing or invalid JWT)
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: 'Missing authorization header'

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: '[Entity] not found'

    ValidationError:
      description: Validation error
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              details:
                type: object
                additionalProperties: true

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: 'Internal error'

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

---

## 3. Domain Layer Design

**Ref:** `../../references/clean-architecture.md`

### Entity: [EntityName]

**File:** `internal/domain/[entity].go`

```go
package domain

import (
  "errors"
  "time"
)

// Entity definition
type [Entity] struct {
  ID        string
  [Field1]  string
  [Field2]  int
  CreatedAt time.Time
  UpdatedAt time.Time
}

// Domain-specific errors
var (
  ErrInvalid[Field1]    = errors.New("invalid [field1]")
  ErrDuplicate[Entity]  = errors.New("[entity] already exists")
  ErrNotFound[Entity]   = errors.New("[entity] not found")
)

// Domain methods (business logic)
func (e *[Entity]) Update[Field1](new[Field1] string) error {
  if new[Field1] == "" {
    return ErrInvalid[Field1]
  }
  if e.[Field1] == new[Field1] {
    return errors.New("[field1] unchanged")
  }
  e.[Field1] = new[Field1]
  e.UpdatedAt = time.Now()
  return nil
}

// Repository interface (contract)
type [Entity]Repository interface {
  Save(ctx context.Context, entity *[Entity]) error
  FindByID(ctx context.Context, id string) (*[Entity], error)
  FindAll(ctx context.Context, limit, offset int) ([]*[Entity], int, error)
  Delete(ctx context.Context, id string) error
}

// Domain service (orchestrates entities)
type [Entity]Service struct {
  repo [Entity]Repository
}

func New[Entity]Service(repo [Entity]Repository) *[Entity]Service {
  return &[Entity]Service{repo: repo}
}

func (s *[Entity]Service) Create(ctx context.Context, [field1] string) (*[Entity], error) {
  if [field1] == "" {
    return nil, ErrInvalid[Field1]
  }

  entity := &[Entity]{
    ID:        generateID(),
    [Field1]:  [field1],
    CreatedAt: time.Now(),
    UpdatedAt: time.Now(),
  }

  if err := s.repo.Save(ctx, entity); err != nil {
    return nil, err
  }
  return entity, nil
}
```

---

## 4. Application Layer Design

**Ref:** `../../references/clean-architecture.md`

### Use Case: Create[Entity]

**File:** `internal/application/create_[entity].go`

```go
package application

import (
  "context"
  "myapp/internal/domain"
)

// Input DTO
type Create[Entity]Input struct {
  [Field1] string `json:"[field1]" validate:"required,min=1,max=255"`
  [Field2] int    `json:"[field2]" validate:"required,min=1"`
}

// Output DTO
type Create[Entity]Output struct {
  ID        string    `json:"id"`
  [Field1]  string    `json:"[field1]"`
  [Field2]  int       `json:"[field2]"`
  CreatedAt time.Time `json:"created_at"`
}

// Use case handler
type Create[Entity]UseCase struct {
  service *domain.[Entity]Service
}

func New Create[Entity]UseCase(service *domain.[Entity]Service) *Create[Entity]UseCase {
  return &Create[Entity]UseCase{service: service}
}

func (uc *Create[Entity]UseCase) Execute(ctx context.Context, input Create[Entity]Input) (*Create[Entity]Output, error) {
  // Validate input (application layer)
  if err := validate(input); err != nil {
    return nil, err
  }

  // Call domain service (business logic)
  entity, err := uc.service.Create(ctx, input.[Field1])
  if err != nil {
    return nil, err
  }

  // Translate domain entity to output DTO
  return &Create[Entity]Output{
    ID:        entity.ID,
    [Field1]:  entity.[Field1],
    [Field2]:  entity.[Field2],
    CreatedAt: entity.CreatedAt,
  }, nil
}
```

---

## 5. Infrastructure Layer Design

**Ref:** `../../references/golang-standards.md`

### Repository Implementation: Postgres[Entity]Repository

**File:** `internal/infrastructure/repository/postgres_[entity]_repository.go`

```go
package repository

import (
  "context"
  "database/sql"
  "fmt"
  "myapp/internal/domain"

  "github.com/jmoiron/sqlx"
)

type Postgres[Entity]Repository struct {
  db *sqlx.DB
}

func NewPostgres[Entity]Repository(db *sqlx.DB) *Postgres[Entity]Repository {
  return &Postgres[Entity]Repository{db: db}
}

func (r *Postgres[Entity]Repository) Save(ctx context.Context, entity *domain.[Entity]) error {
  const query = `
    INSERT INTO [entities] (id, [field1], [field2], created_at, updated_at)
    VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (id) DO UPDATE SET
      [field1] = $2,
      [field2] = $3,
      updated_at = $5
  `

  _, err := r.db.ExecContext(
    ctx, query,
    entity.ID, entity.[Field1], entity.[Field2],
    entity.CreatedAt, entity.UpdatedAt,
  )
  if err != nil {
    return fmt.Errorf("save [entity]: %w", err)
  }
  return nil
}

func (r *Postgres[Entity]Repository) FindByID(ctx context.Context, id string) (*domain.[Entity], error) {
  entity := &domain.[Entity]{}
  const query = `
    SELECT id, [field1], [field2], created_at, updated_at
    FROM [entities]
    WHERE id = $1
  `

  err := r.db.GetContext(ctx, entity, query, id)
  if err == sql.ErrNoRows {
    return nil, domain.ErrNotFound[Entity]
  }
  if err != nil {
    return nil, fmt.Errorf("find [entity]: %w", err)
  }
  return entity, nil
}

func (r *Postgres[Entity]Repository) FindAll(ctx context.Context, limit, offset int) ([]*domain.[Entity], int, error) {
  entities := []*domain.[Entity]{}

  // Total count
  var total int
  err := r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM [entities]")
  if err != nil {
    return nil, 0, fmt.Errorf("count [entities]: %w", err)
  }

  // Paginated results
  const query = `
    SELECT id, [field1], [field2], created_at, updated_at
    FROM [entities]
    ORDER BY created_at DESC
    LIMIT $1 OFFSET $2
  `

  err = r.db.SelectContext(ctx, &entities, query, limit, offset)
  if err != nil {
    return nil, 0, fmt.Errorf("list [entities]: %w", err)
  }
  return entities, total, nil
}

func (r *Postgres[Entity]Repository) Delete(ctx context.Context, id string) error {
  const query = "DELETE FROM [entities] WHERE id = $1"
  result, err := r.db.ExecContext(ctx, query, id)
  if err != nil {
    return fmt.Errorf("delete [entity]: %w", err)
  }

  rowsAffected, err := result.RowsAffected()
  if err != nil {
    return fmt.Errorf("rows affected: %w", err)
  }

  if rowsAffected == 0 {
    return domain.ErrNotFound[Entity]
  }
  return nil
}
```

---

## 6. Interface Layer: HTTP Handlers

**File:** `internal/interface/http/[entity]_handler.go`

```go
package http

import (
  "encoding/json"
  "net/http"
  "myapp/internal/application"
  "myapp/internal/domain"

  "github.com/go-chi/chi/v5"
)

type [Entity]Handler struct {
  createUC *application.Create[Entity]UseCase
  // Other use cases...
}

func New[Entity]Handler(createUC *application.Create[Entity]UseCase) *[Entity]Handler {
  return &[Entity]Handler{createUC: createUC}
}

func (h *[Entity]Handler) Create(w http.ResponseWriter, r *http.Request) {
  var req application.Create[Entity]Input
  if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    respondError(w, http.StatusBadRequest, "Invalid request body")
    return
  }

  output, err := h.createUC.Execute(r.Context(), req)
  if err != nil {
    switch err {
    case domain.ErrInvalid[Field1]:
      respondError(w, http.StatusBadRequest, "Invalid [field1]")
    case domain.ErrDuplicate[Entity]:
      respondError(w, http.StatusConflict, "[Entity] already exists")
    default:
      log.Errorf("create [entity]: %v", err)
      respondError(w, http.StatusInternalServerError, "Internal error")
    }
    return
  }

  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(http.StatusCreated)
  json.NewEncoder(w).Encode(output)
}

func (h *[Entity]Handler) Get(w http.ResponseWriter, r *http.Request) {
  id := chi.URLParam(r, "id")
  // ... implementation
}

func (h *[Entity]Handler) List(w http.ResponseWriter, r *http.Request) {
  // ... implementation
}

func (h *[Entity]Handler) Update(w http.ResponseWriter, r *http.Request) {
  // ... implementation
}

func (h *[Entity]Handler) Delete(w http.ResponseWriter, r *http.Request) {
  // ... implementation
}

// Helper: respond with error
func respondError(w http.ResponseWriter, code int, message string) {
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(code)
  json.NewEncoder(w).Encode(map[string]string{"error": message})
}
```

---

## 7. Router Setup (Chi)

**File:** `internal/infrastructure/http/router.go`

```go
package http

import (
  "myapp/internal/application"
  "myapp/internal/domain"
  httpinterface "myapp/internal/interface/http"

  "github.com/go-chi/chi/v5"
  "github.com/go-chi/chi/middleware"
  "github.com/go-chi/cors"
)

func SetupRouter(
  [entity]Service *domain.[Entity]Service,
) chi.Router {
  r := chi.NewRouter()

  // Middleware stack
  r.Use(middleware.Logger)
  r.Use(middleware.Recoverer)
  r.Use(middleware.RequestID)
  r.Use(cors.Handler(cors.Options{
    AllowedOrigins:   []string{os.Getenv("CORS_ORIGIN")},
    AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE"},
    AllowedHeaders:   []string{"Authorization", "Content-Type"},
    ExposedHeaders:   []string{"X-Total-Count"},
    AllowCredentials: true,
    MaxAge:           300,
  }))

  // Public endpoints
  r.Post("/auth/login", authHandler.Login)
  r.Post("/auth/register", authHandler.Register)

  // Protected endpoints
  r.Group(func(r chi.Router) {
    r.Use(authMiddleware)

    handler := httpinterface.New[Entity]Handler(
      application.NewCreate[Entity]UseCase([entity]Service),
    )

    r.Post("/[entities]", handler.Create)
    r.Get("/[entities]", handler.List)
    r.Get("/[entities]/{id}", handler.Get)
    r.Put("/[entities]/{id}", handler.Update)
    r.Delete("/[entities]/{id}", handler.Delete)
  })

  return r
}
```

---

## 8. Middleware Stack

**File:** `internal/infrastructure/http/middleware.go`

```go
package http

import (
  "net/http"
  "github.com/rs/zerolog"
)

// Auth Middleware
func authMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    authHeader := r.Header.Get("Authorization")
    if authHeader == "" {
      http.Error(w, "Missing auth header", http.StatusUnauthorized)
      return
    }

    token, err := jwt.ValidateToken(authHeader)
    if err != nil {
      http.Error(w, "Invalid token", http.StatusUnauthorized)
      return
    }

    ctx := context.WithValue(r.Context(), contextKeyUserID, token.UserID)
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}

// Logging Middleware
func loggingMiddleware(log *zerolog.Logger) func(http.Handler) http.Handler {
  return func(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
      log.Info().
        Str("method", r.Method).
        Str("path", r.RequestURI).
        Str("user_id", getUserID(r.Context())).
        Msg("request")

      next.ServeHTTP(w, r)
    })
  }
}
```

---

## 9. Data Model & Database Schema

**Migration File:** `migrations/001_create_[entities]_table.up.sql`

```sql
CREATE TABLE IF NOT EXISTS [entities] (
  id UUID PRIMARY KEY,
  [field1] VARCHAR(255) NOT NULL,
  [field2] INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_[entities]_created_at ON [entities](created_at DESC);
CREATE INDEX idx_[entities]_[field1] ON [entities]([field1]);

-- Trigger to auto-update updated_at
CREATE TRIGGER update_[entities]_updated_at
BEFORE UPDATE ON [entities]
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

**Rollback:** `migrations/001_create_[entities]_table.down.sql`

```sql
DROP TRIGGER IF EXISTS update_[entities]_updated_at ON [entities];
DROP INDEX IF EXISTS idx_[entities]_[field1];
DROP INDEX IF EXISTS idx_[entities]_created_at;
DROP TABLE IF EXISTS [entities];
```

---

## 10. Error Handling & HTTP Status Codes

**Ref:** `../../references/golang-standards.md`

| Error | HTTP Status | Response |
|-------|-------------|----------|
| Validation error | 400 Bad Request | `{"error": "Invalid [field]"}` |
| Missing auth | 401 Unauthorized | `{"error": "Missing auth header"}` |
| Permission denied | 403 Forbidden | `{"error": "Forbidden"}` |
| Not found | 404 Not Found | `{"error": "[Entity] not found"}` |
| Conflict (duplicate) | 409 Conflict | `{"error": "[Entity] already exists"}` |
| Rate limited | 429 Too Many Requests | `{"error": "Rate limit exceeded"}` |
| Internal error | 500 Internal Server Error | `{"error": "Internal error"}` |

---

## 11. Deployment & Infrastructure

**Dockerfile:**
```dockerfile
# Build stage
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app ./cmd/server

# Runtime stage
FROM alpine:3.18
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/app .
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD /app/app -health
CMD ["./app"]
```

**Kubernetes Deployment:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: [service-name]
spec:
  containers:
  - name: [service-name]
    image: [service-name]:latest
    ports:
    - name: http
      containerPort: 8080
    - name: admin
      containerPort: 8081

    livenessProbe:
      httpGet:
        path: /health
        port: admin
      initialDelaySeconds: 30
      periodSeconds: 10

    readinessProbe:
      httpGet:
        path: /ready
        port: admin
      initialDelaySeconds: 5
      periodSeconds: 5

    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: postgres-secret
          key: url
    - name: JWT_SECRET
      valueFrom:
        secretKeyRef:
          name: jwt-secret
          key: secret
```

---

## 12. Security Checklist

**Ref:** `../../references/security-rules.md`

- [ ] **Auth:** JWT validation on all protected endpoints
- [ ] **Input Validation:** All inputs validated at API boundary (validator.v10)
- [ ] **SQL Injection:** Parameterized queries only (sqlx with $1, $2, etc.)
- [ ] **Error Messages:** Generic messages (no system details leaked)
- [ ] **Logging:** Structured logging, no PII, no tokens
- [ ] **Secrets:** All secrets from env vars, never hardcoded
- [ ] **Rate Limiting:** Implemented on sensitive endpoints (auth, API)
- [ ] **CORS:** Configured for specific origins (not `*`)
- [ ] **HTTPS:** Enforced in production
- [ ] **Dependencies:** `go mod audit`, no vulnerable packages
- [ ] **Database:** Migrations version controlled, DDL reviewed
- [ ] **Recovery:** No panic in request handlers, graceful error responses

---

## 13. Testing Strategy

**Ref:** `../../references/golang-standards.md`

### Unit Tests: Domain Layer

**File:** `internal/domain/[entity]_test.go`

```go
func TestUpdate[Field1](t *testing.T) {
  tests := []struct {
    name    string
    initial string
    new     string
    wantErr bool
  }{
    {"Valid update", "old", "new", false},
    {"Empty field", "old", "", true},
    {"No change", "same", "same", true},
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      entity := &[Entity]{[Field1]: tt.initial}
      err := entity.Update[Field1](tt.new)
      if (err != nil) != tt.wantErr {
        t.Errorf("got error %v, want error %v", err != nil, tt.wantErr)
      }
    })
  }
}
```

### Integration Tests: Repository

**File:** `internal/infrastructure/repository/postgres_[entity]_repository_test.go`

```go
func TestPostgres[Entity]RepositorySave(t *testing.T) {
  db := setupTestDB(t)
  defer db.Close()

  repo := repository.NewPostgres[Entity]Repository(db)
  entity := &domain.[Entity]{ID: "1", [Field1]: "test"}

  err := repo.Save(context.Background(), entity)
  assert.NoError(t, err)

  retrieved, err := repo.FindByID(context.Background(), "1")
  assert.NoError(t, err)
  assert.Equal(t, "test", retrieved.[Field1])
}
```

### Handler Tests

```go
func TestCreate[Entity]Handler(t *testing.T) {
  mockUC := new(mock[Entity]UseCase)
  mockUC.On("Execute", mock.Anything, mock.Anything).
    Return(&application.Create[Entity]Output{ID: "1"}, nil)

  handler := httpinterface.New[Entity]Handler(mockUC)

  body := `{"[field1]":"test"}`
  req := httptest.NewRequest("POST", "/[entities]", strings.NewReader(body))
  w := httptest.NewRecorder()

  handler.Create(w, req)

  assert.Equal(t, http.StatusCreated, w.Code)
}
```

---

## 14. Deployment Checklist

- [ ] Code builds without errors: `go build ./cmd/server`
- [ ] All tests pass: `go test ./...`
- [ ] Linting passes: `golangci-lint run`
- [ ] Vulnerability scan: `go mod audit`
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] Docker image builds and runs
- [ ] Kubernetes manifests validated
- [ ] Health check endpoints working
- [ ] Logging configured correctly
- [ ] Security checks passed (JWT, validation, SQL injection prevention)

---

**Document Owner:** [Backend Lead]
**Last Updated:** [YYYY-MM-DD]
**Review Cycle:** Quarterly
