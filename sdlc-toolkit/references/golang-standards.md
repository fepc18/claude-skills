# Golang Microservices Standards

Binding standards for all Golang microservices and backend components in technical specifications.

## Project Structure

### Canonical Layout
```
project-name/
├── cmd/
│   └── server/
│       └── main.go              ← Entry point, dependency injection
├── internal/
│   ├── domain/                  ← Business logic (entities, interfaces)
│   │   ├── user.go
│   │   ├── user_repository.go
│   │   └── user_service.go
│   ├── application/             ← Use cases, orchestration
│   │   └── create_user.go
│   ├── infrastructure/          ← Concrete implementations
│   │   ├── repository/
│   │   ├── http/
│   │   ├── grpc/
│   │   └── logger/
│   └── interface/               ← HTTP, gRPC handlers
│       ├── http/
│       │   └── user_handler.go
│       └── middleware/
│           └── auth.go
├── pkg/                         ← Public, reusable packages
│   └── errors/
│       └── errors.go
├── migrations/                  ← Database migrations (golang-migrate format)
│   ├── 001_create_users_table.up.sql
│   └── 001_create_users_table.down.sql
├── docker-compose.yml
├── Dockerfile
├── go.mod
├── go.sum
├── Makefile
└── .golangci.yml                ← Linter configuration
```

## Dependency Management

### go.mod Best Practices
```go
go 1.23

require (
  github.com/go-chi/chi/v5 v5.0.11
  github.com/lib/pq v1.10.9
  github.com/rs/zerolog v1.31.0
)

require (
  github.com/mattn/go-colorable v0.1.13 // indirect (transitive)
)
```

**Rules:**
- ✅ Commit `go.mod` and `go.sum`
- ✅ Pin exact versions (no `v1.0` or `^1.0`)
- ✅ Run `go mod tidy` before commits
- ❌ Never use `go get -u` in CI/CD (unpredictable versions)
- ❌ Avoid vendoring unless in monorepo

## HTTP Router (Chi)

### Router Setup
```go
package main

import (
  "github.com/go-chi/chi/v5"
  "github.com/go-chi/chi/middleware"
)

func setupRouter(handlers *http.Handlers) chi.Router {
  r := chi.NewRouter()

  // Middleware stack (outer-to-inner execution)
  r.Use(middleware.Logger)
  r.Use(middleware.Recoverer)
  r.Use(authMiddleware)

  // Public routes
  r.Post("/auth/login", handlers.Login)
  r.Post("/auth/register", handlers.Register)

  // Protected routes
  r.Group(func(r chi.Router) {
    r.Use(protectedMiddleware)
    r.Get("/users/{id}", handlers.GetUser)
    r.Put("/users/{id}", handlers.UpdateUser)
    r.Delete("/users/{id}", handlers.DeleteUser)
  })

  return r
}

func main() {
  r := setupRouter(handlers)
  http.ListenAndServe(":8080", r)
}
```

## Middleware Stack

### Standard Middleware Order
```go
r := chi.NewRouter()

// 1. Logging (always first)
r.Use(middleware.Logger)

// 2. Recovery (panic handling)
r.Use(middleware.Recoverer)

// 3. Request ID (tracing)
r.Use(middleware.RequestID)

// 4. CORS (if needed)
r.Use(corsMiddleware)

// 5. Content-Type validation
r.Use(contentTypeMiddleware)

// 6. Authentication (if needed)
r.Use(authMiddleware)

// 7. Timeout (last before handlers)
r.Use(middleware.Timeout(30 * time.Second))
```

### Authentication Middleware
```go
func authMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    authHeader := r.Header.Get("Authorization")
    if authHeader == "" {
      http.Error(w, "Missing auth token", http.StatusUnauthorized)
      return
    }

    // Extract and validate token
    token, err := jwt.ValidateToken(authHeader)
    if err != nil {
      http.Error(w, "Invalid token", http.StatusUnauthorized)
      return
    }

    // Add user info to context
    ctx := context.WithValue(r.Context(), contextKeyUserID, token.UserID)
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}

// Usage in handler
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
  userID := r.Context().Value(contextKeyUserID).(string)
  // ... use userID
}
```

## Error Handling

### Custom Error Types
```go
package domain

type ErrorCode string

const (
  ErrInvalidInput ErrorCode = "INVALID_INPUT"
  ErrNotFound     ErrorCode = "NOT_FOUND"
  ErrConflict     ErrorCode = "CONFLICT"
  ErrInternal     ErrorCode = "INTERNAL"
)

type DomainError struct {
  Code    ErrorCode
  Message string
  Details map[string]string
}

func (e *DomainError) Error() string {
  return e.Message
}

// Constructor
func NewDomainError(code ErrorCode, message string) *DomainError {
  return &DomainError{
    Code:    code,
    Message: message,
    Details: make(map[string]string),
  }
}
```

### Error Handling in Handlers
```go
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
  var req CreateUserRequest
  if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    respondError(w, http.StatusBadRequest, "Invalid request body")
    return
  }

  user, err := h.useCase.Execute(r.Context(), req)
  if err != nil {
    switch {
    case errors.Is(err, domain.ErrInvalidInput):
      respondError(w, http.StatusBadRequest, "Invalid input")
    case errors.Is(err, domain.ErrConflict):
      respondError(w, http.StatusConflict, "User already exists")
    case errors.Is(err, domain.ErrNotFound):
      respondError(w, http.StatusNotFound, "Not found")
    default:
      log.Errorf("unexpected error: %v", err)
      respondError(w, http.StatusInternalServerError, "Internal error")
    }
    return
  }

  w.Header().Set("Content-Type", "application/json")
  json.NewEncoder(w).Encode(user)
}

// Helper
func respondError(w http.ResponseWriter, code int, message string) {
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(code)
  json.NewEncoder(w).Encode(map[string]string{"error": message})
}
```

### No Panic in Production
```go
// BAD: Crashes server
func handleRequest(w http.ResponseWriter, r *http.Request) {
  if err := something(); err != nil {
    panic(err) // Server crashes!
  }
}

// GOOD: Explicit error handling
func handleRequest(w http.ResponseWriter, r *http.Request) {
  if err := something(); err != nil {
    log.Errorf("operation failed: %v", err)
    http.Error(w, "Internal error", http.StatusInternalServerError)
    return
  }
}
```

## Logging

### Zerolog Setup
```go
package main

import "github.com/rs/zerolog"

func initLogger() {
  zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
  if os.Getenv("LOG_LEVEL") == "debug" {
    zerolog.SetGlobalLevel(zerolog.DebugLevel)
  } else {
    zerolog.SetGlobalLevel(zerolog.InfoLevel)
  }
}

// Usage
log := zerolog.New(os.Stderr).With().Timestamp().Logger()

log.Info().
  Str("user_id", "user123").
  Str("action", "login").
  Msg("User logged in")

log.Error().
  Err(err).
  Str("endpoint", "/users").
  Msg("Request failed")
```

### Logging Rules
✅ **Do:**
- Log structured key-value pairs
- Include request ID for tracing
- Log security events (auth failures, suspicious activity)
- Log operation success/failure with context

❌ **Don't:**
- Log PII (passwords, emails, credit cards)
- Log raw request/response bodies
- Log tokens or credentials
- Create huge log entries

```go
// BAD: Logs sensitive data
log.Info().
  Str("email", user.Email).
  Str("password", user.Password).
  Msg("User created")

// GOOD: Logs only IDs and actions
log.Info().
  Str("user_id", user.ID).
  Str("action", "user_created").
  Msg("User registration completed")
```

## Database Access

### SQL Injection Prevention (sqlx)
```go
import "github.com/jmoiron/sqlx"

// GOOD: Parameterized query
err := db.GetContext(ctx, &user,
  "SELECT id, email, name FROM users WHERE id = $1",
  userID,
)

// BAD: SQL Injection
err := db.QueryRowContext(ctx,
  fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID),
).Scan(&user)
```

### Repository Pattern
```go
package domain

type User struct {
  ID    string
  Email string
  Name  string
}

type UserRepository interface {
  Save(ctx context.Context, user *User) error
  FindByID(ctx context.Context, id string) (*User, error)
  FindByEmail(ctx context.Context, email string) (*User, error)
  Delete(ctx context.Context, id string) error
}
```

```go
package infrastructure

type PostgresUserRepository struct {
  db *sqlx.DB
}

func (r *PostgresUserRepository) Save(ctx context.Context, user *domain.User) error {
  const query = `
    INSERT INTO users (id, email, name)
    VALUES ($1, $2, $3)
    ON CONFLICT (id) DO UPDATE SET email = $2, name = $3
  `
  _, err := r.db.ExecContext(ctx, query, user.ID, user.Email, user.Name)
  if err != nil {
    return fmt.Errorf("save user: %w", err)
  }
  return nil
}

func (r *PostgresUserRepository) FindByID(ctx context.Context, id string) (*domain.User, error) {
  user := &domain.User{}
  const query = `SELECT id, email, name FROM users WHERE id = $1`

  err := r.db.GetContext(ctx, user, query, id)
  if err == sql.ErrNoRows {
    return nil, domain.ErrUserNotFound
  }
  if err != nil {
    return nil, fmt.Errorf("find user: %w", err)
  }
  return user, nil
}
```

### Database Migrations
```sql
-- migrations/001_create_users_table.up.sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

```bash
# Run migrations
migrate -path migrations -database "postgres://..." up

# Rollback
migrate -path migrations -database "postgres://..." down 1
```

## Context Propagation

### Mandatory Context in All Functions
```go
// GOOD: Context propagated
func (uc *CreateUserUseCase) Execute(ctx context.Context, req Request) (*User, error) {
  // Check if context is cancelled
  select {
  case <-ctx.Done():
    return nil, ctx.Err()
  default:
  }

  // Pass context to repository
  user, err := uc.repo.Save(ctx, newUser)
  return user, err
}

// BAD: No context
func (uc *CreateUserUseCase) Execute(req Request) (*User, error) {
  // No way to cancel or timeout
  user, err := uc.repo.Save(newUser) // Missing context!
  return user, err
}
```

### Timeout Handling
```go
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
  // Context from request (already has timeout from middleware)
  ctx := r.Context()

  // Add additional timeout if needed
  ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
  defer cancel()

  user, err := h.useCase.Execute(ctx, req)
  if err == context.DeadlineExceeded {
    http.Error(w, "Request timeout", http.StatusGatewayTimeout)
    return
  }
  // ...
}
```

## gRPC for Inter-Service Communication

### Proto Definition
```protobuf
// api/proto/user.proto
syntax = "proto3";

package api.v1;

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
}

message GetUserRequest {
  string id = 1;
}

message GetUserResponse {
  string id = 1;
  string email = 2;
  string name = 3;
}

message CreateUserRequest {
  string email = 1;
  string name = 2;
}

message CreateUserResponse {
  string id = 1;
  string email = 2;
}
```

### Server Implementation
```go
package grpc

import (
  pb "myservice/api/proto"
  "google.golang.org/grpc"
)

type UserServiceServer struct {
  pb.UnimplementedUserServiceServer
  useCase *application.CreateUserUseCase
}

func (s *UserServiceServer) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.CreateUserResponse, error) {
  user, err := s.useCase.Execute(ctx, application.CreateUserInput{
    Email: req.Email,
    Name:  req.Name,
  })
  if err != nil {
    return nil, grpc.Errorf(codes.Internal, "failed to create user")
  }

  return &pb.CreateUserResponse{
    Id:    user.ID,
    Email: user.Email,
  }, nil
}

func setupGRPC(useCase *application.CreateUserUseCase) *grpc.Server {
  s := grpc.NewServer()
  pb.RegisterUserServiceServer(s, &UserServiceServer{useCase: useCase})
  return s
}
```

## Testing

### Table-Driven Tests
```go
func TestValidateEmail(t *testing.T) {
  tests := []struct {
    name    string
    email   string
    wantErr bool
  }{
    {"Valid email", "user@example.com", false},
    {"Missing @", "user.example.com", true},
    {"Missing domain", "user@", true},
    {"Empty string", "", true},
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      err := validateEmail(tt.email)
      if (err != nil) != tt.wantErr {
        t.Errorf("got error %v, want error %v", err != nil, tt.wantErr)
      }
    })
  }
}
```

### Mocking with Interfaces
```go
// Mock repository
type mockUserRepository struct {
  mock.Mock
}

func (m *mockUserRepository) FindByID(ctx context.Context, id string) (*domain.User, error) {
  args := m.Called(ctx, id)
  if args.Get(0) == nil {
    return nil, args.Error(1)
  }
  return args.Get(0).(*domain.User), args.Error(1)
}

// Test
func TestGetUser(t *testing.T) {
  mockRepo := new(mockUserRepository)
  mockRepo.On("FindByID", mock.Anything, "user1").Return(
    &domain.User{ID: "user1", Email: "user@example.com"},
    nil,
  )

  useCase := &application.GetUserUseCase{Repo: mockRepo}
  user, err := useCase.Execute(context.Background(), "user1")

  assert.NoError(t, err)
  assert.Equal(t, "user1", user.ID)
}
```

## Linting (golangci-lint)

### Configuration (.golangci.yml)
```yaml
run:
  timeout: 5m
  skip-dirs:
    - vendor

linters:
  enable:
    - errcheck         # Error must be checked
    - gosimple         # Simplify code
    - govet            # Go vet errors
    - ineffassign      # Unused assignments
    - staticcheck       # Static analysis
    - typecheck        # Type errors
    - unused           # Unused code
    - misspell         # Misspellings
    - goimports        # Import order

linters-settings:
  errcheck:
    check-type-assertions: true
```

## Docker and Kubernetes

### Multi-Stage Dockerfile
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
CMD ["./app"]
```

### Kubernetes Probes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myservice
spec:
  containers:
  - name: app
    image: myservice:latest
    ports:
    - containerPort: 8080
    - containerPort: 8081  # Admin port for health checks

    # Liveness probe (restart if unhealthy)
    livenessProbe:
      httpGet:
        path: /health
        port: 8081
      initialDelaySeconds: 30
      periodSeconds: 10

    # Readiness probe (remove from load balancer if unhealthy)
    readinessProbe:
      httpGet:
        path: /ready
        port: 8081
      initialDelaySeconds: 5
      periodSeconds: 5
```

```go
// Health check endpoint
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(http.StatusOK)
  json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

// Readiness check endpoint
func readinessHandler(w http.ResponseWriter, r *http.Request) {
  if !isReady() {
    w.WriteHeader(http.StatusServiceUnavailable)
    return
  }
  w.WriteHeader(http.StatusOK)
  json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
}
```

## Code Style

### Naming Conventions
- **Packages:** lowercase, single word if possible
- **Functions:** CamelCase, `GetUser`, `CreateOrder`
- **Methods:** CamelCase, `(u *User) IsActive()`
- **Constants:** UPPER_SNAKE_CASE (only if exported), otherwise camelCase
- **Interfaces:** end with "er", `Reader`, `Writer`, `Repository`
- **Errors:** prefix "Err", `ErrNotFound`, `ErrInvalidInput`

### Error Wrapping
```go
// GOOD: Wrap errors with context
if err := db.Save(user); err != nil {
  return fmt.Errorf("save user: %w", err)
}

// BAD: Lose context
if err := db.Save(user); err != nil {
  return err
}
```

## Anti-Patterns

### ❌ Global State
```go
// BAD: Global database connection
var db *sqlx.DB

func init() {
  var err error
  db, err = sqlx.Connect("postgres", "...")
}

// GOOD: Dependency injection
func newHandler(db *sqlx.DB) *Handler {
  return &Handler{db: db}
}
```

### ❌ Inflexible Interfaces
```go
// BAD: Interface too specific to implementation
type UserService interface {
  SaveToDatabase(user *User) error
  SendEmailNotification(email string) error
}

// GOOD: Interface focused on behavior
type UserRepository interface {
  Save(ctx context.Context, user *User) error
}

type Notifier interface {
  Send(ctx context.Context, email string) error
}
```

### ❌ Ignoring Errors
```go
// BAD: Error ignored
func setup() {
  _ = loadConfig()
  db.Connect()
}

// GOOD: Explicit error handling
func setup() error {
  if err := loadConfig(); err != nil {
    return fmt.Errorf("load config: %w", err)
  }
  if err := db.Connect(); err != nil {
    return fmt.Errorf("connect db: %w", err)
  }
  return nil
}
```

---

**Last Updated:** 2026-07-01
