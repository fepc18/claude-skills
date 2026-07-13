# Implementation Scaffolding: [ProjectName] (Golang)

## 1. Directory Tree

Complete clean-architecture Golang project structure:

```
[project-name]/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── domain/
│   │   ├── [entity].go
│   │   ├── [entity]_repository.go (interface)
│   │   └── errors.go
│   ├── application/
│   │   ├── create_[entity].go
│   │   ├── update_[entity].go
│   │   └── delete_[entity].go
│   ├── infrastructure/
│   │   └── repository/
│   │       ├── postgres_[entity]_repository.go
│   │       └── postgres_connection.go
│   └── interface/
│       └── http/
│           ├── [entity]_handler.go
│           ├── router.go
│           ├── middleware.go
│           └── request_response.go
├── pkg/
│   └── middleware/
│       ├── auth.go
│       ├── logger.go
│       ├── recovery.go
│       └── cors.go
├── migrations/
│   ├── 001_create_[entities]_table.up.sql
│   └── 001_create_[entities]_table.down.sql
├── go.mod
├── go.sum
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .gitignore
├── Makefile
├── README.md
└── .github/
    └── workflows/
        └── test.yml
```

---

## 2. go.mod

```
module github.com/[yourorg]/[project-name]

go 1.22

require (
	github.com/chi-middleware/logrus-chi v0.0.0-20240314134529-c5065a6b69dc
	github.com/go-chi/chi/v5 v5.1.0
	github.com/go-chi/cors v1.2.1
	github.com/google/uuid v1.6.0
	github.com/jmoiron/sqlx v1.4.0
	github.com/lib/pq v1.10.9
	github.com/rs/zerolog v1.32.0
)

require (
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	golang.org/x/sys v0.16.0 // indirect
)
```

---

## 3. cmd/server/main.go

```go
package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/go-chi/chi/v5"

	"github.com/[yourorg]/[project-name]/internal/infrastructure/repository"
	"github.com/[yourorg]/[project-name]/internal/application"
	httpinterface "github.com/[yourorg]/[project-name]/internal/interface/http"
)

func main() {
	// Zerolog setup
	log.Logger = zerolog.New(os.Stdout).
		With().
		Timestamp().
		Caller().
		Logger()

	// Database connection
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal().Msg("DATABASE_URL environment variable not set")
	}

	db, err := sqlx.Connect("postgres", dbURL)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to connect to database")
	}
	defer db.Close()

	if err := db.PingContext(context.Background()); err != nil {
		log.Fatal().Err(err).Msg("Failed to ping database")
	}

	log.Info().Msg("Connected to database")

	// Dependency Injection: Create repository (infrastructure)
	[entity]Repo := repository.NewPostgres[Entity]Repository(db)

	// Dependency Injection: Create use cases (application)
	create[Entity]UseCase := application.NewCreate[Entity]UseCase([entity]Repo)
	update[Entity]UseCase := application.NewUpdate[Entity]UseCase([entity]Repo)
	delete[Entity]UseCase := application.NewDelete[Entity]UseCase([entity]Repo)

	// Dependency Injection: Create HTTP handlers (interface)
	[entity]Handler := httpinterface.New[Entity]Handler(
		create[Entity]UseCase,
		update[Entity]UseCase,
		delete[Entity]UseCase,
	)

	// Create router
	r := chi.NewRouter()
	httpinterface.RegisterRoutes(r, [entity]Handler)

	// HTTP server
	addr := os.Getenv("HTTP_ADDR")
	if addr == "" {
		addr = ":8080"
	}

	server := &http.Server{
		Addr:         addr,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Info().Str("addr", addr).Msg("Starting HTTP server")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("HTTP server error")
		}
	}()

	// Graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Info().Msg("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatal().Err(err).Msg("Server shutdown error")
	}

	log.Info().Msg("Server stopped gracefully")
}
```

---

## 4. internal/domain/[entity].go

```go
package domain

import (
	"context"
	"errors"
	"time"
)

// [Entity] represents a domain entity
type [Entity] struct {
	ID        string
	[Field1]  string
	[Field2]  int
	CreatedAt time.Time
	UpdatedAt time.Time
}

// Validate checks if entity is valid
func (e *[Entity]) Validate() error {
	if e.[Field1] == "" {
		return errors.New("[field1] is required")
	}
	if e.[Field2] < 0 {
		return errors.New("[field2] must be positive")
	}
	return nil
}

// [Entity]Repository defines the contract for [entity] data access
type [Entity]Repository interface {
	Save(ctx context.Context, entity *[Entity]) error
	FindByID(ctx context.Context, id string) (*[Entity], error)
	FindAll(ctx context.Context, offset, limit int) ([]*[Entity], int64, error)
	Update(ctx context.Context, entity *[Entity]) error
	Delete(ctx context.Context, id string) error
}

// Domain errors
var (
	ErrInvalid[Entity]       = errors.New("[entity] is invalid")
	ErrNotFound              = errors.New("[entity] not found")
	ErrDuplicate             = errors.New("[entity] already exists")
	ErrUnauthorized          = errors.New("unauthorized")
)
```

---

## 5. internal/domain/errors.go

```go
package domain

import "fmt"

// Error types for domain layer
type ValidationError struct {
	Message string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("validation error: %s", e.Message)
}

type NotFoundError struct {
	Entity string
	ID     string
}

func (e *NotFoundError) Error() string {
	return fmt.Sprintf("%s with id %s not found", e.Entity, e.ID)
}

type ConflictError struct {
	Message string
}

func (e *ConflictError) Error() string {
	return fmt.Sprintf("conflict: %s", e.Message)
}
```

---

## 6. internal/application/create_[entity].go

```go
package application

import (
	"context"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"github.com/[yourorg]/[project-name]/internal/domain"
)

// Create[Entity]Input is the input for creating an entity
type Create[Entity]Input struct {
	[Field1] string
	[Field2] int
}

// Create[Entity]Output is the output after creating an entity
type Create[Entity]Output struct {
	ID       string
	[Field1] string
}

// Create[Entity]UseCase handles entity creation
type Create[Entity]UseCase struct {
	repo domain.[Entity]Repository
}

// NewCreate[Entity]UseCase creates a new use case
func NewCreate[Entity]UseCase(repo domain.[Entity]Repository) *Create[Entity]UseCase {
	return &Create[Entity]UseCase{repo: repo}
}

// Execute creates a new entity
func (uc *Create[Entity]UseCase) Execute(ctx context.Context, input *Create[Entity]Input) (*Create[Entity]Output, error) {
	log.Info().Str("field1", input.[Field1]).Int("field2", input.[Field2]).Msg("Creating entity")

	entity := &domain.[Entity]{
		ID:       uuid.NewString(),
		[Field1]: input.[Field1],
		[Field2]: input.[Field2],
	}

	if err := entity.Validate(); err != nil {
		log.Warn().Err(err).Msg("Validation failed")
		return nil, err
	}

	if err := uc.repo.Save(ctx, entity); err != nil {
		log.Error().Err(err).Msg("Failed to save entity")
		return nil, err
	}

	log.Info().Str("id", entity.ID).Msg("Entity created successfully")
	return &Create[Entity]Output{
		ID:       entity.ID,
		[Field1]: entity.[Field1],
	}, nil
}
```

---

## 7. internal/infrastructure/repository/postgres_connection.go

```go
package repository

import (
	"context"
	"fmt"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

// NewPostgresConnection creates a database connection
func NewPostgresConnection(dsn string) (*sqlx.DB, error) {
	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to postgres: %w", err)
	}

	if err := db.PingContext(context.Background()); err != nil {
		return nil, fmt.Errorf("failed to ping postgres: %w", err)
	}

	return db, nil
}
```

---

## 8. internal/infrastructure/repository/postgres_[entity]_repository.go

```go
package repository

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/jmoiron/sqlx"
	"github.com/[yourorg]/[project-name]/internal/domain"
)

// Postgres[Entity]Repository implements domain.[Entity]Repository
type Postgres[Entity]Repository struct {
	db *sqlx.DB
}

// NewPostgres[Entity]Repository creates a new repository
func NewPostgres[Entity]Repository(db *sqlx.DB) *Postgres[Entity]Repository {
	return &Postgres[Entity]Repository{db: db}
}

// Save creates or updates an entity
func (r *Postgres[Entity]Repository) Save(ctx context.Context, entity *domain.[Entity]) error {
	query := `
		INSERT INTO [entities] (id, [field1], [field2], created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (id) DO UPDATE
		SET [field1] = $2, [field2] = $3, updated_at = $5
	`

	_, err := r.db.ExecContext(ctx, query,
		entity.ID,
		entity.[Field1],
		entity.[Field2],
		entity.CreatedAt,
		entity.UpdatedAt,
	)

	if err != nil {
		return fmt.Errorf("save [entity]: %w", err)
	}

	return nil
}

// FindByID retrieves an entity by ID
func (r *Postgres[Entity]Repository) FindByID(ctx context.Context, id string) (*domain.[Entity], error) {
	query := `SELECT id, [field1], [field2], created_at, updated_at FROM [entities] WHERE id = $1`

	var entity domain.[Entity]
	if err := r.db.GetContext(ctx, &entity, query, id); err != nil {
		if err == sql.ErrNoRows {
			return nil, &domain.NotFoundError{Entity: "[Entity]", ID: id}
		}
		return nil, fmt.Errorf("find [entity] by id: %w", err)
	}

	return &entity, nil
}

// FindAll retrieves all entities with pagination
func (r *Postgres[Entity]Repository) FindAll(ctx context.Context, offset, limit int) ([]*domain.[Entity], int64, error) {
	// Get total count
	var total int64
	if err := r.db.GetContext(ctx, &total, `SELECT COUNT(*) FROM [entities]`); err != nil {
		return nil, 0, fmt.Errorf("count [entities]: %w", err)
	}

	// Get paginated results
	query := `SELECT id, [field1], [field2], created_at, updated_at FROM [entities] ORDER BY created_at DESC OFFSET $1 LIMIT $2`

	var entities []*domain.[Entity]
	if err := r.db.SelectContext(ctx, &entities, query, offset, limit); err != nil {
		return nil, 0, fmt.Errorf("find all [entities]: %w", err)
	}

	return entities, total, nil
}

// Update updates an entity
func (r *Postgres[Entity]Repository) Update(ctx context.Context, entity *domain.[Entity]) error {
	query := `UPDATE [entities] SET [field1] = $1, [field2] = $2, updated_at = $3 WHERE id = $4`

	result, err := r.db.ExecContext(ctx, query,
		entity.[Field1],
		entity.[Field2],
		entity.UpdatedAt,
		entity.ID,
	)

	if err != nil {
		return fmt.Errorf("update [entity]: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("rows affected: %w", err)
	}

	if rows == 0 {
		return &domain.NotFoundError{Entity: "[Entity]", ID: entity.ID}
	}

	return nil
}

// Delete deletes an entity
func (r *Postgres[Entity]Repository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM [entities] WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("delete [entity]: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("rows affected: %w", err)
	}

	if rows == 0 {
		return &domain.NotFoundError{Entity: "[Entity]", ID: id}
	}

	return nil
}
```

---

## 9. internal/interface/http/router.go

```go
package http

import (
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
	"github.com/[yourorg]/[project-name]/pkg/middleware"
)

// RegisterRoutes registers all HTTP routes
func RegisterRoutes(r *chi.Mux, [entity]Handler *[Entity]Handler) {
	// CORS middleware
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		ExposedHeaders:   []string{"X-Total-Count"},
		MaxAge:           300,
		AllowCredentials: false,
	}))

	// Middleware stack
	r.Use(middleware.Logger)
	r.Use(middleware.Recovery)

	// Health checks
	r.Get("/health", HealthCheck)
	r.Get("/ready", ReadinessCheck)

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		r.Use(middleware.Auth) // Require authentication

		// [Entity] routes
		r.Post("/[entities]", [entity]Handler.Create)
		r.Get("/[entities]/{id}", [entity]Handler.GetByID)
		r.Get("/[entities]", [entity]Handler.GetAll)
		r.Put("/[entities]/{id}", [entity]Handler.Update)
		r.Delete("/[entities]/{id}", [entity]Handler.Delete)
	})
}

// HealthCheck returns liveness probe
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// ReadinessCheck returns readiness probe
func ReadinessCheck(w http.ResponseWriter, r *http.Request) {
	// TODO: Check database connection
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
}
```

---

## 10. internal/interface/http/[entity]_handler.go

```go
package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"
	"github.com/[yourorg]/[project-name]/internal/application"
)

// [Entity]Handler handles HTTP requests for [entities]
type [Entity]Handler struct {
	create *application.Create[Entity]UseCase
	update *application.Update[Entity]UseCase
	delete *application.Delete[Entity]UseCase
}

// New[Entity]Handler creates a new handler
func New[Entity]Handler(
	create *application.Create[Entity]UseCase,
	update *application.Update[Entity]UseCase,
	delete *application.Delete[Entity]UseCase,
) *[Entity]Handler {
	return &[Entity]Handler{
		create: create,
		update: update,
		delete: delete,
	}
}

// Create handles POST /[entities]
func (h *[Entity]Handler) Create(w http.ResponseWriter, r *http.Request) {
	var req application.Create[Entity]Input
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "invalid request body"})
		return
	}

	output, err := h.create.Execute(r.Context(), &req)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(output)
}

// GetByID handles GET /[entities]/{id}
func (h *[Entity]Handler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if id == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "id is required"})
		return
	}

	// TODO: Implement GetByID use case

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "GetByID not yet implemented"})
}

// GetAll handles GET /[entities]?offset=0&limit=10
func (h *[Entity]Handler) GetAll(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	// TODO: Implement GetAll use case

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "GetAll not yet implemented"})
}

// Update handles PUT /[entities]/{id}
func (h *[Entity]Handler) Update(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement
	w.WriteHeader(http.StatusNotImplemented)
}

// Delete handles DELETE /[entities]/{id}
func (h *[Entity]Handler) Delete(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement
	w.WriteHeader(http.StatusNotImplemented)
}
```

---

## 11. pkg/middleware/auth.go

```go
package middleware

import (
	"net/http"
	"strings"
)

// Auth middleware validates JWT token
func Auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}

		token := parts[1]
		// TODO: Validate JWT token
		_ = token

		next.ServeHTTP(w, r)
	})
}
```

---

## 12. pkg/middleware/logger.go

```go
package middleware

import (
	"net/http"
	"time"

	"github.com/rs/zerolog/log"
)

// Logger middleware logs HTTP requests
func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		log.Info().
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Str("remote_addr", r.RemoteAddr).
			Msg("HTTP request")

		next.ServeHTTP(w, r)

		log.Info().
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Dur("duration_ms", time.Since(start)).
			Msg("HTTP response")
	})
}
```

---

## 13. Dockerfile

```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./cmd/server

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/
COPY --from=builder /app/server .

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./server"]
```

---

## 14. Migrations Directory

```
migrations/
├── 001_create_[entities]_table.up.sql
│   └── DDL to create tables, indexes, ENUMs
└── 001_create_[entities]_table.down.sql
    └── DROP statements in reverse order
```

---

## 15. .env.example

```env
# Server
HTTP_ADDR=:8080
LOG_LEVEL=info

# Database
DATABASE_URL=postgres://user:password@localhost:5432/[project-name]?sslmode=disable

# Authentication
JWT_SECRET=your-secret-key-here

# External Services
API_BASE_URL=http://api.example.com
```

---

## 16. Makefile

```makefile
.PHONY: help build run test docker-build docker-run migrate-up migrate-down

help:
	@echo "Available targets: build, run, test, docker-build, docker-run, migrate-up, migrate-down"

build:
	go build -o bin/server ./cmd/server

run:
	go run ./cmd/server/main.go

test:
	go test ./... -v -race -coverprofile=coverage.out

docker-build:
	docker build -t [project-name]:latest .

docker-run:
	docker run -p 8080:8080 --env-file .env [project-name]:latest

migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1
```

---

## 17. .github/workflows/test.yml

```yaml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v4

    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.22'

    - name: Run tests
      run: go test ./... -v -race -coverprofile=coverage.out
      env:
        DATABASE_URL: postgres://testuser:testpass@localhost:5432/testdb?sslmode=disable

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.out
```

---

## 18. README.md

```markdown
# [ProjectName]

[Brief description of the project]

## Setup

### Prerequisites
- Go 1.22+
- PostgreSQL 15+
- Docker & Docker Compose (optional)

### Local Development

1. Clone the repository
```bash
git clone https://github.com/[yourorg]/[project-name]
cd [project-name]
```

2. Install dependencies
```bash
go mod download
```

3. Set up environment
```bash
cp .env.example .env
# Edit .env with your database credentials
```

4. Run migrations
```bash
migrate -path migrations -database "$(grep DATABASE_URL .env | cut -d= -f2)" up
```

5. Start the server
```bash
go run ./cmd/server/main.go
```

Server will be available at `http://localhost:8080`

## Health Checks

- Liveness probe: `GET /health`
- Readiness probe: `GET /ready`

## Testing

```bash
# Run all tests
go test ./... -v -race

# With coverage
go test ./... -coverprofile=coverage.out && go tool cover -html=coverage.out
```

## Docker

```bash
# Build image
docker build -t [project-name]:latest .

# Run container
docker-compose up
```

## Architecture

- `cmd/server/` — Application entrypoint
- `internal/domain/` — Domain entities & interfaces
- `internal/application/` — Use cases & business logic
- `internal/infrastructure/` — Repository implementations
- `internal/interface/http/` — HTTP handlers & routes
- `pkg/middleware/` — Shared middleware (auth, logging, recovery)
- `migrations/` — Database migrations

See `internal/domain/[entity]_repository.go` for the repository interface example.

## Next Steps

1. Implement missing handlers in `internal/interface/http/[entity]_handler.go`
2. Create more use cases in `internal/application/`
3. Add database seed data to `migrations/`
4. Write tests in parallel with implementation
```

---

## Getting Started

1. **Extract the scaffolding** to your local machine
2. **Replace placeholders:**
   - `[project-name]` → your project name
   - `[entity]` → your entity name (User, Product, etc.)
   - `[Field1]`, `[Field2]` → your entity fields
   - `[yourorg]` → your GitHub organization
3. **Install dependencies:** `go mod download`
4. **Start developing:** `go run ./cmd/server/main.go`

Your server will boot with:
- ✅ Clean architecture structure
- ✅ Dependency injection setup
- ✅ Health check endpoints
- ✅ Middleware stack (auth, logging, recovery)
- ✅ Repository pattern ready to implement
- ✅ Docker support
- ✅ CI/CD workflow

Happy coding!
