# Test Strategy: [Feature Name] (Golang)

## 1. Testing Pyramid

Recommended distribution for Golang microservices:

```
          /\           E2E/Contract Tests (10%)
         /  \          └─ HTTP endpoint integration
        /    \
       /      \        Integration Tests (20%)
      /        \       └─ Repository + External services
     /          \
    /____________\     Unit Tests (70%)
    Domain + Application
```

**Breakdown:**
- **Unit Tests (70%):** Domain layer entities + Application layer use cases
- **Integration Tests (20%):** Repository implementations + external service integrations
- **E2E/Contract Tests (10%):** HTTP handlers + API contract validation

---

## 2. Unit Tests — Domain Layer

Patrón obligatorio: Table-driven tests para todas las funciones de dominio

```go
// internal/domain/[entity]_test.go
package domain

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func Test[Entity]_Validate(t *testing.T) {
    tests := []struct {
        name    string
        input   *[Entity]
        wantErr bool
        errMsg  string
    }{
        {
            name: "valid entity",
            input: &[Entity]{
                ID:    "uuid-1",
                Name:  "Test Entity",
                Email: "test@example.com",
            },
            wantErr: false,
        },
        {
            name: "empty name",
            input: &[Entity]{
                ID:    "uuid-1",
                Name:  "",
                Email: "test@example.com",
            },
            wantErr: true,
            errMsg:  "name is required",
        },
        {
            name: "invalid email format",
            input: &[Entity]{
                ID:    "uuid-1",
                Name:  "Test",
                Email: "invalid-email",
            },
            wantErr: true,
            errMsg:  "email format is invalid",
        },
        {
            name: "boundary: very long name",
            input: &[Entity]{
                ID:    "uuid-1",
                Name:  string(make([]byte, 300)),
                Email: "test@example.com",
            },
            wantErr: true,
            errMsg:  "name exceeds maximum length",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.input.Validate()
            if tt.wantErr {
                assert.Error(t, err)
                assert.Contains(t, err.Error(), tt.errMsg)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

---

## 3. Unit Tests — Application Layer (Use Cases)

Mocking via interfaces (nunca implementaciones concretas). Usar testify/mock para expectations.

```go
// internal/application/create_[entity]_test.go
package application

import (
    "context"
    "errors"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "your-module/internal/domain"
)

// Mock the repository interface
type mock[Entity]Repository struct {
    mock.Mock
}

func (m *mock[Entity]Repository) Save(ctx context.Context, entity *domain.[Entity]) error {
    args := m.Called(ctx, entity)
    return args.Error(0)
}

func (m *mock[Entity]Repository) FindByID(ctx context.Context, id string) (*domain.[Entity], error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*domain.[Entity]), args.Error(1)
}

func TestCreate[Entity]UseCase_Execute(t *testing.T) {
    tests := []struct {
        name        string
        input       *Create[Entity]Input
        mockReturn  error
        wantErr     bool
        errMsg      string
    }{
        {
            name: "successfully creates entity",
            input: &Create[Entity]Input{
                Name:  "Test Entity",
                Email: "test@example.com",
            },
            mockReturn: nil,
            wantErr:    false,
        },
        {
            name: "repository error",
            input: &Create[Entity]Input{
                Name:  "Test Entity",
                Email: "test@example.com",
            },
            mockReturn: errors.New("database connection failed"),
            wantErr:    true,
            errMsg:     "database connection failed",
        },
        {
            name: "validation error",
            input: &Create[Entity]Input{
                Name:  "",
                Email: "test@example.com",
            },
            wantErr: true,
            errMsg:  "name is required",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := new(mock[Entity]Repository)
            if tt.input.Name != "" { // Only mock if input is valid
                repo.On("Save", mock.Anything, mock.MatchedBy(func(e *domain.[Entity]) bool {
                    return e.Name == tt.input.Name
                })).Return(tt.mockReturn)
            }

            uc := NewCreate[Entity]UseCase(repo)
            output, err := uc.Execute(context.Background(), tt.input)

            if tt.wantErr {
                assert.Error(t, err)
                assert.Contains(t, err.Error(), tt.errMsg)
                assert.Nil(t, output)
            } else {
                assert.NoError(t, err)
                assert.NotNil(t, output)
                assert.NotEmpty(t, output.ID)
                repo.AssertExpectations(t)
            }
        })
    }
}
```

---

## 4. Integration Tests — Repository Layer

Tests con base de datos real usando testcontainers u otro fixture de DB.

```go
// internal/infrastructure/repository/postgres_[entity]_repository_test.go
// +build integration

package repository

import (
    "context"
    "os"
    "testing"
    "time"
    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/wait"
    "your-module/internal/domain"
)

func setupTestDB(t *testing.T) *pgxpool.Pool {
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    req := testcontainers.ContainerRequest{
        Image:        "postgres:15-alpine",
        ExposedPorts: []string{"5432/tcp"},
        Env: map[string]string{
            "POSTGRES_USER":     "testuser",
            "POSTGRES_PASSWORD": "testpass",
            "POSTGRES_DB":       "testdb",
        },
        WaitingFor: wait.ForLog("database system is ready to accept connections"),
    }

    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
    require.NoError(t, err)

    host, err := container.Host(ctx)
    require.NoError(t, err)

    port, err := container.MappedPort(ctx, "5432/tcp")
    require.NoError(t, err)

    dsn := "postgres://testuser:testpass@" + host + ":" + port.Port() + "/testdb?sslmode=disable"

    pool, err := pgxpool.New(ctx, dsn)
    require.NoError(t, err)

    // Run migrations
    createTableSQL := `
        CREATE TABLE IF NOT EXISTS [entities] (
            id UUID PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            created_at TIMESTAMP NOT NULL,
            updated_at TIMESTAMP NOT NULL
        );
    `
    _, err = pool.Exec(ctx, createTableSQL)
    require.NoError(t, err)

    t.Cleanup(func() {
        pool.Close()
        container.Terminate(ctx)
    })

    return pool
}

func TestIntegrationPostgres[Entity]Repository_SaveAndFindByID(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    db := setupTestDB(t)
    repo := NewPostgres[Entity]Repository(db)
    ctx := context.Background()

    tests := []struct {
        name    string
        entity  *domain.[Entity]
        wantErr bool
    }{
        {
            name: "save and retrieve entity",
            entity: &domain.[Entity]{
                ID:    "550e8400-e29b-41d4-a716-446655440000",
                Name:  "Test Entity",
                Email: "test@example.com",
            },
            wantErr: false,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Save
            err := repo.Save(ctx, tt.entity)
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            require.NoError(t, err)

            // Find
            found, err := repo.FindByID(ctx, tt.entity.ID)
            require.NoError(t, err)
            assert.Equal(t, tt.entity.ID, found.ID)
            assert.Equal(t, tt.entity.Name, found.Name)
            assert.Equal(t, tt.entity.Email, found.Email)
        })
    }
}

func TestIntegrationPostgres[Entity]Repository_FindAll(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    db := setupTestDB(t)
    repo := NewPostgres[Entity]Repository(db)
    ctx := context.Background()

    // Insert test data
    entities := []*domain.[Entity]{
        {ID: "550e8400-e29b-41d4-a716-446655440001", Name: "Entity 1", Email: "entity1@example.com"},
        {ID: "550e8400-e29b-41d4-a716-446655440002", Name: "Entity 2", Email: "entity2@example.com"},
        {ID: "550e8400-e29b-41d4-a716-446655440003", Name: "Entity 3", Email: "entity3@example.com"},
    }
    for _, e := range entities {
        err := repo.Save(ctx, e)
        require.NoError(t, err)
    }

    // Find all with pagination
    results, total, err := repo.FindAll(ctx, 0, 10)
    require.NoError(t, err)
    assert.Equal(t, int64(3), total)
    assert.Len(t, results, 3)
}

func TestIntegrationPostgres[Entity]Repository_Delete(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    db := setupTestDB(t)
    repo := NewPostgres[Entity]Repository(db)
    ctx := context.Background()

    entity := &domain.[Entity]{
        ID:    "550e8400-e29b-41d4-a716-446655440000",
        Name:  "Test Entity",
        Email: "test@example.com",
    }

    err := repo.Save(ctx, entity)
    require.NoError(t, err)

    err = repo.Delete(ctx, entity.ID)
    require.NoError(t, err)

    _, err = repo.FindByID(ctx, entity.ID)
    assert.Error(t, err)
}
```

---

## 5. Handler Tests — HTTP Layer

```go
// internal/interface/http/[entity]_handler_test.go
package http

import (
    "bytes"
    "context"
    "encoding/json"
    "errors"
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "your-module/internal/application"
    "your-module/internal/domain"
)

type mockCreate[Entity]UseCase struct {
    mock.Mock
}

func (m *mockCreate[Entity]UseCase) Execute(ctx context.Context, input *application.Create[Entity]Input) (*application.Create[Entity]Output, error) {
    args := m.Called(ctx, input)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*application.Create[Entity]Output), args.Error(1)
}

func TestCreate[Entity]Handler(t *testing.T) {
    tests := []struct {
        name           string
        body           string
        mockReturn     *application.Create[Entity]Output
        mockErr        error
        wantStatusCode int
        wantBody       string
    }{
        {
            name: "success: creates entity",
            body: `{"name":"Test Entity","email":"test@example.com"}`,
            mockReturn: &application.Create[Entity]Output{
                ID:    "uuid-1",
                Name:  "Test Entity",
                Email: "test@example.com",
            },
            mockErr:        nil,
            wantStatusCode: http.StatusCreated,
        },
        {
            name:           "error: invalid JSON body",
            body:           `{invalid json}`,
            wantStatusCode: http.StatusBadRequest,
            wantBody:       "invalid request body",
        },
        {
            name:           "error: validation failure",
            body:           `{"name":"","email":"test@example.com"}`,
            mockReturn:     nil,
            mockErr:        errors.New("name is required"),
            wantStatusCode: http.StatusBadRequest,
        },
        {
            name:           "error: internal server error",
            body:           `{"name":"Test","email":"test@example.com"}`,
            mockReturn:     nil,
            mockErr:        errors.New("database error"),
            wantStatusCode: http.StatusInternalServerError,
            wantBody:       "internal server error",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mockUC := new(mockCreate[Entity]UseCase)
            if tt.mockReturn != nil || tt.mockErr != nil {
                mockUC.On("Execute", mock.Anything, mock.Anything).Return(tt.mockReturn, tt.mockErr)
            }

            handler := New[Entity]Handler(mockUC)

            req := httptest.NewRequest(http.MethodPost, "/[entities]", bytes.NewBufferString(tt.body))
            req.Header.Set("Content-Type", "application/json")
            w := httptest.NewRecorder()

            handler.Create(w, req)

            assert.Equal(t, tt.wantStatusCode, w.Code)
            if tt.wantBody != "" {
                assert.Contains(t, w.Body.String(), tt.wantBody)
            }
        })
    }
}
```

---

## 6. Security Test Cases (obligatorio per security-rules.md)

```go
// internal/interface/http/security_test.go
package http

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestProtectedEndpoint_RequiresAuth(t *testing.T) {
    handler := New[Entity]Handler(nil)

    req := httptest.NewRequest(http.MethodGet, "/protected/[entity]", nil)
    // No Authorization header
    w := httptest.NewRecorder()

    handler.GetProtected(w, req)

    assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestProtectedEndpoint_RejectsExpiredToken(t *testing.T) {
    handler := New[Entity]Handler(nil)

    req := httptest.NewRequest(http.MethodGet, "/protected/[entity]", nil)
    req.Header.Set("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MDAwMDAwMDB9.invalid")
    w := httptest.NewRecorder()

    handler.GetProtected(w, req)

    assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestProtectedEndpoint_RejectsInvalidClaims(t *testing.T) {
    handler := New[Entity]Handler(nil)

    req := httptest.NewRequest(http.MethodGet, "/protected/[entity]/123", nil)
    // Valid token but user doesn't own this resource
    req.Header.Set("Authorization", "Bearer valid.token.for.other.user")
    w := httptest.NewRecorder()

    handler.GetProtected(w, req)

    assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestInputValidation_RejectsSQLInjection(t *testing.T) {
    handler := New[Entity]Handler(nil)

    payload := map[string]string{
        "name": "'; DROP TABLE [entities]; --",
    }
    body, _ := json.Marshal(payload)

    req := httptest.NewRequest(http.MethodPost, "/[entities]", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    handler.Create(w, req)

    // Should reject or sanitize, not execute SQL
    assert.NotEqual(t, http.StatusCreated, w.Code)
}

func TestInputValidation_RejectsOversizedPayload(t *testing.T) {
    handler := New[Entity]Handler(nil)

    // Create 50MB payload
    largeString := make([]byte, 50*1024*1024)

    req := httptest.NewRequest(http.MethodPost, "/[entities]", bytes.NewBuffer(largeString))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    handler.Create(w, req)

    assert.Equal(t, http.StatusRequestEntityTooLarge, w.Code)
}

func TestRateLimiting_BlocksAfterThreshold(t *testing.T) {
    handler := New[Entity]Handler(nil)

    // Make 100 requests (assuming threshold is 10/minute)
    for i := 0; i < 100; i++ {
        req := httptest.NewRequest(http.MethodPost, "/auth/login", bytes.NewBufferString(`{}`))
        req.Header.Set("Content-Type", "application/json")
        w := httptest.NewRecorder()

        handler.Login(w, req)

        if i >= 10 {
            assert.Equal(t, http.StatusTooManyRequests, w.Code)
        }
    }
}
```

---

## 7. BDD Scenarios (Gherkin)

```gherkin
# features/[feature_name].feature

Feature: [Feature Name]
  As a [persona]
  I want to [action]
  So that [benefit]

  Scenario: Create [entity] successfully
    Given the system is ready to accept requests
    When I send a POST request to /[entities] with:
      | name  | Test Entity    |
      | email | test@example.com |
    Then the response status should be 201
    And the response should contain:
      | id    | [uuid]             |
      | name  | Test Entity        |
      | email | test@example.com   |

  Scenario: Reject duplicate email
    Given an [entity] with email "test@example.com" already exists
    When I send a POST request to /[entities] with:
      | name  | Another Entity   |
      | email | test@example.com |
    Then the response status should be 409
    And the response should contain:
      | error | Email already exists |

  Scenario: Validation fails on empty name
    Given the system is ready to accept requests
    When I send a POST request to /[entities] with:
      | name  |                  |
      | email | test@example.com |
    Then the response status should be 400
    And the response should contain:
      | error | Name is required |

  Scenario: Not found on invalid ID
    Given the system is ready to accept requests
    When I send a GET request to /[entities]/invalid-uuid
    Then the response status should be 404
    And the response should contain:
      | error | [Entity] not found |
```

---

## 8. Test Data Strategy

```go
// internal/testutil/factories.go
package testutil

import (
    "time"
    "github.com/google/uuid"
    "your-module/internal/domain"
)

// New[Entity] creates a valid [Entity] with default test values
func New[Entity]() *domain.[Entity] {
    return &domain.[Entity]{
        ID:        uuid.NewString(),
        Name:      "Test Entity",
        Email:     "test@example.com",
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
    }
}

// New[Entity]WithEmail creates an [Entity] with a specific email
func New[Entity]WithEmail(email string) *domain.[Entity] {
    e := New[Entity]()
    e.Email = email
    return e
}

// New[Entity]WithName creates an [Entity] with a specific name
func New[Entity]WithName(name string) *domain.[Entity] {
    e := New[Entity]()
    e.Name = name
    return e
}

// New[Entity]List creates a list of n [Entity] instances
func New[Entity]List(count int) []*domain.[Entity] {
    entities := make([]*domain.[Entity], count)
    for i := 0; i < count; i++ {
        entities[i] = New[Entity]WithEmail("entity" + string(rune(i)) + "@example.com")
    }
    return entities
}

// New[Entity]WithDefaults creates an [Entity] with custom fields via functional options
type [Entity]Option func(*domain.[Entity])

func With[Entity]Name(name string) [Entity]Option {
    return func(e *domain.[Entity]) {
        e.Name = name
    }
}

func With[Entity]Email(email string) [Entity]Option {
    return func(e *domain.[Entity]) {
        e.Email = email
    }
}

func New[Entity]With(opts ...[Entity]Option) *domain.[Entity] {
    e := New[Entity]()
    for _, opt := range opts {
        opt(e)
    }
    return e
}

// Usage in tests:
// entity := testutil.New[Entity]With(
//     testutil.With[Entity]Name("Custom Name"),
//     testutil.With[Entity]Email("custom@example.com"),
// )
```

---

## 9. Coverage Targets

| Package / Layer | Target | Critical Paths | Notes |
|---|---|---|---|
| `internal/domain` | 90% | 100% | All business logic must be covered |
| `internal/application` | 85% | 100% | All use cases must be tested |
| `internal/infrastructure/repository` | 70% | 100% (critical entity) | Integration tests satisfy this |
| `internal/interface/http` | 75% | 100% (auth, payments) | Handlers, middleware tested |
| **Global** | **80%** | — | Pre-merge requirement |

### Coverage Commands

```bash
# Run with coverage
go test ./... -coverprofile=coverage.out

# Generate HTML report
go tool cover -html=coverage.out -o coverage.html

# View in terminal
go tool cover -func=coverage.out | grep total

# Fail if coverage below threshold
go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//' | awk '{if ($1 < 80) exit 1}'
```

---

## 10. Performance Tests (críticos para endpoints)

```go
// internal/interface/http/performance_test.go
package http

import (
    "context"
    "testing"
    "time"
)

func BenchmarkCreate[Entity](b *testing.B) {
    mockUC := new(mockCreate[Entity]UseCase)
    mockUC.On("Execute", context.Background(), mock.Anything).Return(&application.Create[Entity]Output{
        ID:    "uuid-1",
        Name:  "Test",
        Email: "test@example.com",
    }, nil)

    handler := New[Entity]Handler(mockUC)

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        req := httptest.NewRequest(http.MethodPost, "/[entities]", bytes.NewBufferString(`{"name":"Test","email":"test@example.com"}`))
        w := httptest.NewRecorder()
        handler.Create(w, req)
    }
}

func BenchmarkGetAll[Entity]s(b *testing.B) {
    mockUC := new(mockFind[Entity]UseCase)
    mockUC.On("Execute", mock.Anything, mock.Anything).Return([]*application.[Entity]Output{}, nil)

    handler := New[Entity]Handler(mockUC)

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        req := httptest.NewRequest(http.MethodGet, "/[entities]?offset=0&limit=10", nil)
        w := httptest.NewRecorder()
        handler.GetAll(w, req)
    }
}

// Target performance: POST /[entities] < 200ms p99, GET /[entities] < 100ms p99
// Run with: go test -bench=. -benchmem
```

---

## 11. CI/CD Test Integration

Orden de ejecución en pipeline:

```yaml
# .github/workflows/test.yml or azure-pipelines.yml

# Stage 1: Unit Tests (PRs, all branches)
- name: Run Unit Tests
  run: go test ./... -short -race -v
  # -short: skip integration tests
  # -race: detect data races

# Stage 2: Integration Tests (merge to main only)
- name: Run Integration Tests
  if: github.event_name == 'pull_request' || github.ref == 'refs/heads/main'
  run: go test ./... -run Integration -v

# Stage 3: Security Scanning
- name: Security Scan (go mod audit)
  run: go mod audit

- name: SAST with gosec
  run: |
    go install github.com/securego/gosec/v2/cmd/gosec@latest
    gosec ./...

# Stage 4: Coverage Check (bloqueante)
- name: Check Coverage
  run: |
    go test ./... -coverprofile=coverage.out
    coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
    if (( $(echo "$coverage < 80" | bc -l) )); then
      echo "Coverage $coverage% is below 80% threshold"
      exit 1
    fi

# Stage 5: Benchmark (informativo)
- name: Run Benchmarks
  run: go test -bench=. -benchmem -run=^$ ./...
  continue-on-error: true  # No bloquea el pipeline
```

---

## 12. Smoke Test Suite (para deployment-specs)

Suite de verificación ejecutada post-deployment en staging/producción.

```go
// smoketest/main_test.go
// +build smoke

package smoketest

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "testing"
    "time"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

var appURL string

func init() {
    appURL = os.Getenv("APP_URL")
    if appURL == "" {
        appURL = "http://localhost:8080"
    }
}

func TestSmokeHealth_Endpoint(t *testing.T) {
    client := &http.Client{Timeout: 5 * time.Second}
    resp, err := client.Get(appURL + "/health")
    require.NoError(t, err)
    defer resp.Body.Close()

    assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestSmokeReadiness_Endpoint(t *testing.T) {
    client := &http.Client{Timeout: 5 * time.Second}
    resp, err := client.Get(appURL + "/ready")
    require.NoError(t, err)
    defer resp.Body.Close()

    assert.Equal(t, http.StatusOK, resp.StatusCode)

    var readiness map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&readiness)
    assert.Equal(t, "ready", readiness["status"])
}

func TestSmokeAuth_LoginEndpointExists(t *testing.T) {
    client := &http.Client{Timeout: 5 * time.Second}
    body := []byte(`{"email":"test@example.com","password":"wrong"}`)
    resp, err := client.Post(appURL+"/auth/login", "application/json", bytes.NewReader(body))
    require.NoError(t, err)
    defer resp.Body.Close()

    // Should not be 404 (endpoint exists), can be 401/400 (auth failure)
    assert.NotEqual(t, http.StatusNotFound, resp.StatusCode)
}

func TestSmokeAPI_[Entity]sEndpoint(t *testing.T) {
    client := &http.Client{Timeout: 5 * time.Second}
    resp, err := client.Get(appURL + "/api/[entities]")
    require.NoError(t, err)
    defer resp.Body.Close()

    // Should return 200 or 401 (auth required), not 404
    assert.Contains(t, []int{http.StatusOK, http.StatusUnauthorized}, resp.StatusCode)
}

func TestSmokeDatabase_Connectivity(t *testing.T) {
    client := &http.Client{Timeout: 5 * time.Second}
    resp, err := client.Get(appURL + "/health/db")
    require.NoError(t, err)
    defer resp.Body.Close()

    var health map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&health)
    assert.Equal(t, "ok", health["database"])
}

// Run with: go test -tags=smoke ./smoketest -v
// Typically runs after deployment in CI/CD as final validation
```

---

## 13. Test Checklist

Use this checklist before marking the feature as testable:

- [ ] **Unit Tests**
  - [ ] Domain layer: all entities have Validate() tests
  - [ ] Application layer: all use cases have Execute() tests with mocked repos
  - [ ] Table-driven tests used for all domain logic
  - [ ] No `time.Sleep()` in tests (use mocks or channels)
  - [ ] All error paths tested

- [ ] **Integration Tests**
  - [ ] Repository tests use real database (testcontainers or test fixture)
  - [ ] External service tests use MSW or equivalent mocking
  - [ ] Tests run with `-run Integration` only during merge
  - [ ] Database schema matches production
  - [ ] Migrations tested

- [ ] **HTTP Handler Tests**
  - [ ] All endpoints have handler tests
  - [ ] Request validation tested (empty fields, invalid types)
  - [ ] Response format validated (JSON structure)
  - [ ] Error responses tested (4xx, 5xx codes)

- [ ] **Security Tests**
  - [ ] Auth endpoints: 401 without token
  - [ ] Protected endpoints: 401/403 on invalid token
  - [ ] Input validation: SQL injection attempts rejected
  - [ ] Payload size: oversized requests rejected (413)
  - [ ] Rate limiting: enforced on sensitive endpoints (429)

- [ ] **BDD Scenarios**
  - [ ] Feature file written in Gherkin syntax
  - [ ] Happy path scenario exists
  - [ ] Error cases documented
  - [ ] Scenarios are testable (Given/When/Then structure)

- [ ] **Test Data**
  - [ ] Factory functions created for all entities
  - [ ] Factories with functional options for customization
  - [ ] Test fixtures consistent across test files

- [ ] **Coverage**
  - [ ] `go test ./... -cover` shows >= 80% global
  - [ ] `go tool cover -func=coverage.out` shows domain >= 90%
  - [ ] Critical paths at 100%
  - [ ] Coverage report generated (coverage.html)

- [ ] **Race Detection**
  - [ ] `go test -race ./...` runs without data races
  - [ ] Concurrent operations tested (if applicable)
  - [ ] No goroutine leaks

- [ ] **Performance**
  - [ ] Benchmarks run: `go test -bench=. ./...`
  - [ ] POST endpoints < 200ms p99
  - [ ] GET endpoints < 100ms p99
  - [ ] No N+1 queries in repository tests

- [ ] **CI/CD Integration**
  - [ ] Unit tests run on every PR
  - [ ] Integration tests run on merge to main
  - [ ] Coverage check enforces >= 80%
  - [ ] Security scanning enabled (go mod audit, gosec)
  - [ ] Benchmark results tracked

- [ ] **Smoke Tests**
  - [ ] Health endpoint tested (/health)
  - [ ] Readiness endpoint tested (/ready)
  - [ ] Critical business endpoints exist
  - [ ] Database connectivity verified
  - [ ] Smoke tests pass in staging before prod deployment

- [ ] **Documentation**
  - [ ] Test strategy documented (this file)
  - [ ] Run instructions provided (go test -short vs full)
  - [ ] Coverage targets documented
  - [ ] Smoke test execution documented

---

**Next Step:** After test strategy is approved, proceed to Stage 8: **Deployment Specifications** where the smoke test suite defined here will be integrated into CI/CD pipelines for Azure, AWS, or DigitalOcean.
