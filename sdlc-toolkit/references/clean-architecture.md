# Clean Architecture Standards

Clean architecture organizes code into concentric layers, where inner layers define business logic independent of frameworks and infrastructure.

## Core Principles

### 1. Dependency Rule
**Inner layers must NEVER depend on outer layers.**

```
Outer Layers (Framework, DB, Web)
    ↓ dependencies ↓
Middle Layers (Application Services)
    ↓ dependencies ↓
Inner Layers (Domain Logic)
↑ NO reverse dependencies
```

- **Domain layer** (innermost) knows nothing about HTTP, databases, or frameworks
- **Application layer** orchestrates domain logic, doesn't know about HTTP/DB details
- **Infrastructure layer** implements interfaces defined by domain/application
- **Interface layer** (outermost) handles HTTP requests, translates to domain objects

### 2. Separation of Concerns
- **One reason to change** — single responsibility
- **Business logic isolated** from technical details (HTTP, SQL, caching)
- **Easy to test** — domain can be tested without infrastructure

### 3. Testability
- Domain layer: Pure unit tests (no mocks needed)
- Application layer: Unit tests with interface mocks
- Infrastructure layer: Integration tests with real or containerized dependencies
- Interface layer: Contract tests and integration tests

## Golang Package Structure

### Directory Layout
```
project-name/
├── cmd/
│   └── server/
│       └── main.go              ← Entry point. Dependency injection.
├── internal/
│   ├── domain/                  ← Business logic (innermost)
│   │   ├── user.go              ← Entity (User struct + domain methods)
│   │   ├── user_repository.go   ← Repository interface
│   │   └── user_service.go      ← Domain service (business rules)
│   ├── application/             ← Use cases & orchestration
│   │   └── create_user.go       ← Use case handler
│   ├── infrastructure/          ← Concrete implementations
│   │   ├── repository/
│   │   │   └── postgres_user_repository.go
│   │   ├── http/
│   │   │   └── router.go        ← HTTP routes setup
│   │   └── logger/
│   │       └── zerolog_logger.go
│   └── interface/               ← HTTP handlers (outermost)
│       ├── http/
│       │   └── user_handler.go  ← HTTP endpoint handlers
│       └── middleware/
│           └── auth.go          ← Middleware
├── pkg/                         ← Reusable packages (if any)
├── migrations/                  ← Database migrations
├── go.mod
└── docker-compose.yml
```

### Layer Responsibilities

#### Domain Layer (`internal/domain/`)
**Purpose:** Pure business logic independent of any framework.

**What lives here:**
- Entities (domain models with business methods)
- Value objects (immutable concepts like Money, Email)
- Repository interfaces (contracts, not implementations)
- Domain services (complex business logic across entities)
- Domain events (what happened in the business)
- Errors (domain-specific error types)

**Example: User Entity**
```go
package domain

type User struct {
  ID    string
  Email string
  Name  string
}

// Domain methods (business logic)
func (u *User) UpdateEmail(newEmail string) error {
  if !isValidEmail(newEmail) {
    return ErrInvalidEmail
  }
  if u.Email == newEmail {
    return ErrEmailUnchanged
  }
  u.Email = newEmail
  return nil
}

// Repository interface (contract)
type UserRepository interface {
  Save(ctx context.Context, user *User) error
  FindByID(ctx context.Context, id string) (*User, error)
}

// Domain service (orchestrates entities)
type UserService struct {
  repo UserRepository
}

func (s *UserService) RegisterUser(ctx context.Context, email, name string) (*User, error) {
  if err := s.repo.Exists(ctx, email); err == nil {
    return nil, ErrEmailAlreadyExists
  }

  user := &User{ID: generateID(), Email: email, Name: name}
  if err := s.repo.Save(ctx, user); err != nil {
    return nil, err
  }
  return user, nil
}
```

#### Application Layer (`internal/application/`)
**Purpose:** Orchestrate domain logic, implement use cases.

**What lives here:**
- Use case handlers (one per user action)
- Application services (delegate to domain)
- DTOs (Data Transfer Objects) for use case input/output
- Transactions coordination

**Example: CreateUserUseCase**
```go
package application

type CreateUserInput struct {
  Email string
  Name  string
}

type CreateUserOutput struct {
  ID    string
  Email string
}

type CreateUserUseCase struct {
  userService *domain.UserService
}

func (uc *CreateUserUseCase) Execute(ctx context.Context, input CreateUserInput) (*CreateUserOutput, error) {
  user, err := uc.userService.RegisterUser(ctx, input.Email, input.Name)
  if err != nil {
    return nil, err // Propagate domain errors
  }

  return &CreateUserOutput{
    ID:    user.ID,
    Email: user.Email,
  }, nil
}
```

#### Infrastructure Layer (`internal/infrastructure/`)
**Purpose:** Implement interfaces defined by domain/application.

**What lives here:**
- Repository implementations (PostgreSQL, MongoDB, etc.)
- HTTP client implementations
- Logger implementations
- Cache implementations
- Dependency injection setup

**Example: PostgreSQL User Repository**
```go
package repository

type PostgresUserRepository struct {
  db *sqlx.DB
}

func (r *PostgresUserRepository) Save(ctx context.Context, user *domain.User) error {
  query := `INSERT INTO users (id, email, name) VALUES ($1, $2, $3)`
  _, err := r.db.ExecContext(ctx, query, user.ID, user.Email, user.Name)
  return err
}

func (r *PostgresUserRepository) FindByID(ctx context.Context, id string) (*domain.User, error) {
  user := &domain.User{}
  query := `SELECT id, email, name FROM users WHERE id = $1`
  err := r.db.GetContext(ctx, user, query, id)
  if err == sql.ErrNoRows {
    return nil, domain.ErrUserNotFound
  }
  return user, err
}
```

#### Interface Layer (`internal/interface/http/`)
**Purpose:** Handle HTTP requests, translate to/from domain objects.

**What lives here:**
- HTTP handlers
- HTTP middleware
- Request validation
- Response formatting

**Example: User HTTP Handler**
```go
package http

type UserHandler struct {
  createUserUC *application.CreateUserUseCase
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
  var req struct {
    Email string `json:"email"`
    Name  string `json:"name"`
  }

  if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    http.Error(w, "Invalid request", http.StatusBadRequest)
    return
  }

  // Translate HTTP request to use case input
  input := application.CreateUserInput{
    Email: req.Email,
    Name:  req.Name,
  }

  // Execute use case
  output, err := h.createUserUC.Execute(r.Context(), input)
  if err != nil {
    // Handle domain errors, return appropriate HTTP status
    if errors.Is(err, domain.ErrInvalidEmail) {
      http.Error(w, "Invalid email", http.StatusBadRequest)
      return
    }
    http.Error(w, "Internal error", http.StatusInternalServerError)
    return
  }

  // Translate use case output to HTTP response
  w.Header().Set("Content-Type", "application/json")
  json.NewEncoder(w).Encode(output)
}
```

#### Dependency Injection (`cmd/server/main.go`)
```go
package main

func main() {
  db := setupDatabase()

  // Infrastructure implementations
  userRepo := repository.NewPostgresUserRepository(db)
  logger := setupLogger()

  // Domain services
  userService := &domain.UserService{Repo: userRepo}

  // Application use cases
  createUserUC := &application.CreateUserUseCase{UserService: userService}

  // HTTP handlers
  handler := &http.UserHandler{CreateUserUC: createUserUC}

  // Setup router
  r := chi.NewRouter()
  r.Post("/users", handler.CreateUser)

  http.ListenAndServe(":8080", r)
}
```

## React Component Structure

### Directory Layout by Feature
```
src/
├── components/
│   ├── atoms/                   ← Smallest, reusable pieces
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── Label.tsx
│   ├── molecules/               ← Simple combinations of atoms
│   │   ├── FormField.tsx        ← Label + Input
│   │   ├── SearchBox.tsx
│   │   └── Card.tsx
│   ├── organisms/               ← Complex, feature-complete components
│   │   ├── UserForm.tsx
│   │   ├── Header.tsx
│   │   └── AuthModal.tsx
│   ├── templates/               ← Page layouts
│   │   ├── AuthLayout.tsx
│   │   └── DashboardLayout.tsx
│   └── pages/                   ← Routed components
│       ├── LoginPage.tsx
│       └── DashboardPage.tsx
├── hooks/                       ← Custom React hooks (business logic)
│   ├── useAuth.ts
│   ├── useUser.ts
│   └── usePagination.ts
├── services/                    ← API clients, utilities
│   ├── api/
│   │   ├── userApi.ts
│   │   └── authApi.ts
│   └── utils/
│       ├── formatting.ts
│       └── validation.ts
├── stores/                      ← Global state (Zustand)
│   ├── authStore.ts
│   └── userStore.ts
├── types/                       ← TypeScript types
│   ├── domain.ts                ← Domain models
│   └── api.ts                   ← API response types
└── App.tsx
```

### Atomic Design Explanation

#### Atoms (Lowest Level)
- Single, reusable UI elements
- No business logic
- Props control behavior
- Examples: Button, Input, Label, Icon

```tsx
// atoms/Button.tsx
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  variant?: 'primary' | 'secondary';
}

export const Button: React.FC<ButtonProps> = ({
  label,
  onClick,
  disabled = false,
  variant = 'primary'
}) => (
  <button
    onClick={onClick}
    disabled={disabled}
    className={`btn btn-${variant}`}
  >
    {label}
  </button>
);
```

#### Molecules (Combination of Atoms)
- Simple component compositions
- Still relatively generic
- Examples: FormField (Label + Input), SearchBox

```tsx
// molecules/FormField.tsx
interface FormFieldProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  error?: string;
}

export const FormField: React.FC<FormFieldProps> = ({
  label,
  value,
  onChange,
  error
}) => (
  <div className="form-field">
    <Label text={label} />
    <Input value={value} onChange={onChange} />
    {error && <span className="error">{error}</span>}
  </div>
);
```

#### Organisms (Complex Components)
- Feature-complete components
- May contain business logic via hooks
- Examples: LoginForm, UserProfile, DataTable

```tsx
// organisms/UserForm.tsx
interface UserFormProps {
  onSubmit: (user: UserData) => void;
}

export const UserForm: React.FC<UserFormProps> = ({ onSubmit }) => {
  const { user, updateUser, validate, errors } = useUserForm();

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      if (validate()) onSubmit(user);
    }}>
      <FormField
        label="Email"
        value={user.email}
        onChange={(email) => updateUser({ email })}
        error={errors.email}
      />
      <FormField
        label="Name"
        value={user.name}
        onChange={(name) => updateUser({ name })}
        error={errors.name}
      />
      <Button label="Submit" onClick={() => {}} />
    </form>
  );
};
```

#### Templates (Layouts)
- Page structure and layout
- Define regions (header, footer, sidebar, main)
- No logic or styling specific to content

```tsx
// templates/DashboardLayout.tsx
interface DashboardLayoutProps {
  children: React.ReactNode;
}

export const DashboardLayout: React.FC<DashboardLayoutProps> = ({ children }) => (
  <div className="dashboard">
    <Header />
    <Sidebar />
    <main className="content">{children}</main>
    <Footer />
  </div>
);
```

#### Pages (Routed Components)
- Connected to router
- Compose templates and organisms
- Manage page-level state
- Load data on mount

```tsx
// pages/DashboardPage.tsx
export const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const { users, loading } = useUsers();

  if (loading) return <LoadingSpinner />;

  return (
    <DashboardLayout>
      <UserList users={users} />
    </DashboardLayout>
  );
};
```

### Custom Hooks (Business Logic)
Encapsulate component logic for reusability.

```tsx
// hooks/useAuth.ts
interface User {
  id: string;
  email: string;
}

export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load user from localStorage or API
    authApi.getCurrentUser().then(setUser).finally(() => setLoading(false));
  }, []);

  const login = async (email: string, password: string) => {
    const user = await authApi.login(email, password);
    setUser(user);
    return user;
  };

  const logout = () => {
    authApi.logout();
    setUser(null);
  };

  return { user, loading, login, logout };
};
```

### Global State Management (Zustand)
For state needed across multiple components.

```tsx
// stores/authStore.ts
import { create } from 'zustand';

interface AuthState {
  user: User | null;
  token: string | null;
  setUser: (user: User) => void;
  setToken: (token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  setUser: (user) => set({ user }),
  setToken: (token) => set({ token }),
  logout: () => set({ user: null, token: null }),
}));
```

## Interfaces as Contracts

Both Golang and React use interfaces to define contracts between layers.

### Golang Examples
```go
// Repository interface (contract)
type UserRepository interface {
  Save(ctx context.Context, user *User) error
  FindByID(ctx context.Context, id string) (*User, error)
}

// Logger interface
type Logger interface {
  Infof(msg string, args ...interface{})
  Errorf(msg string, args ...interface{})
}

// These can have multiple implementations
```

### React Examples
```tsx
// Props interface (contract)
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
}

// Hook return interface
interface UseAuthReturn {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}
```

## Anti-Patterns to Avoid

### ❌ Circular Dependencies
```go
// BAD: domain depends on infrastructure
package domain
import "myapp/internal/infrastructure"

var repo infrastructure.PostgresUserRepository
```

**Fix:** Use interfaces in domain, implement in infrastructure.

### ❌ God Objects
```go
// BAD: User has 50+ fields and 30+ methods
type User struct {
  ID, Email, Name, Address, Phone, ... // 50 fields
  Save(), Update(), Delete(), Validate(), ... // 30 methods
}
```

**Fix:** Separate concerns. User entity + separate services/value objects.

### ❌ Leaky Abstractions
```go
// BAD: Domain layer exposes database error
if err == sql.ErrNoRows {
  return domain.ErrUserNotFound
}
```

**Fix:** Translate DB errors to domain errors in repository.

### ❌ Business Logic in HTTP Handlers
```go
// BAD: Logic in handler
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
  // Validation, business logic, everything here
  if len(email) < 5 { ... }
  if userExists { ... }
  db.Insert(...) // Direct DB access
}
```

**Fix:** Use application use cases and domain services.

### ❌ React Component with Too Much Logic
```tsx
// BAD: Component does everything
export const UserForm = () => {
  const [users, setUsers] = useState([]);
  const [formData, setFormData] = useState({});

  // Direct API calls, state management, validation, etc.
  useEffect(() => {
    fetch('/api/users').then(setUsers);
  }, []);

  const handleSubmit = async () => {
    const validation = ...;
    const response = await fetch('/api/users', { ... });
    // ...
  };

  return <form> ... </form>;
};
```

**Fix:** Extract to custom hooks and services.

---

**Last Updated:** 2026-07-01
