---
name: implementation-scaffolding
description: Genera la estructura base de proyecto lista para codificar. Golang sigue clean-architecture (cmd/, internal/domain, application, infrastructure, interface/). React pregunta la estructura preferida — Atomic Design, Feature-Based, Page-Based o Flat — y genera el árbol de directorios, archivos de configuración, stubs de componentes/servicios, y setup de testing.
model_invoked: true
triggers:
  - scaffolding
  - scaffold
  - generar estructura de proyecto
  - project structure
  - estructura de proyecto
  - crear proyecto base
  - boilerplate
  - proyecto inicial
  - initial project
  - generate project
  - new project setup
  - setup del proyecto
  - carpetas del proyecto
  - directorios del proyecto
  - project setup
  - crear el proyecto
  - inicio de proyecto
  - kickstart project
  - generate boilerplate
---

# Implementation Scaffolding Skill

## Purpose

Generate production-ready project structure immediately after completing all specifications. This skill produces:
- Directory tree with all necessary folders
- Configuration files (tsconfig.json, vite.config.ts, go.mod, Dockerfile, etc.)
- Stub files for components, services, handlers with proper imports
- Testing setup (vitest, playwright, Go test structure)
- CI/CD workflow files (.github/workflows or azure-pipelines.yml)
- .env.example with all required environment variables
- README with setup and running instructions

This gets developers to "Hello World" in minutes, not hours.

## Workflow

### 1. Stack Selection

Ask the user:
- "Which stack are you scaffolding?" (Golang backend / React frontend / Full-Stack)
- "If Full-Stack: should I create both backend and frontend in the same repository or separate?"

### 2. Structure Preference (React Only)

**For React projects**, ask the user to choose folder structure:
- **A) Atomic Design** (atoms/molecules/organisms/pages) — recommended, aligns with react-standards.md
  - Best for: Medium to large projects with many components, design systems, multi-team development
- **B) Feature-Based** (features/auth/, features/dashboard/, each self-contained)
  - Best for: Domain-driven development, clear feature boundaries, easier to parallel work
- **C) Page-Based** (pages/, components/shared/) — simple structure
  - Best for: Small to medium projects, straightforward page layouts
- **D) Flat** (components/, hooks/, utils/) — minimal structure
  - Best for: Prototypes, simple projects, quick MVPs

**For Golang**, structure is always:
```
cmd/server/
internal/domain/
internal/application/
internal/infrastructure/
internal/interface/
pkg/middleware/
migrations/
```

### 3. Project Configuration

Ask:
- "What is the project name?" (e.g., "UserManagement", "OrderProcessing")
- "Go module name?" (e.g., "github.com/yourorg/user-management") — Golang only
- "Which features do you want scaffolded?" (e.g., "User CRUD, Authentication, Teams")
- "Does this project need Docker?" (Yes/No)
- "CI/CD platform?" (GitHub Actions / Azure DevOps)

### 4. Scaffolding Generation

Generate complete directory tree with:
- All folders created
- Stub files with proper imports and minimal implementations
- Configuration files with sensible defaults
- Testing setup files
- CI/CD workflows
- .env.example

### 5. Output & Getting Started

Save all files to `/sessions/[session-id]/mnt/outputs/[project-name]-scaffolding/`

Provide:
- Complete file tree (ASCII)
- Instructions to extract and start developing
- "First run" commands (npm install && npm run dev, go run ./cmd/server/main.go)
- Next steps: "Open src/App.tsx and start building"

## Template Structure

This skill uses two assets:

### `assets/golang-scaffolding.md`

Complete Golang project with:
- Directory tree (ASCII)
- go.mod with production dependencies
- cmd/server/main.go with dependency injection setup
- internal/domain/, internal/application/, internal/infrastructure/ stubs
- internal/interface/http/ with router and middleware
- pkg/middleware/ (auth, logging, recovery)
- migrations/ directory setup
- Dockerfile multi-stage build
- .github/workflows/test.yml (or azure-pipelines.yml)
- .env.example
- README.md with setup instructions

### `assets/react-scaffolding.md`

Separate sections for each structure type:

**Option A: Atomic Design** — src/components/{atoms,molecules,organisms,pages}, src/hooks/, src/services/, src/types/, src/mocks/
**Option B: Feature-Based** — src/features/{feature}/, each with components/, hooks/, services/, types/
**Option C: Page-Based** — src/pages/, src/components/shared/
**Option D: Flat** — src/components/, src/hooks/, src/utils/, src/services/

**Common to all options:**
- package.json with dependencies for Vite, React Query, Zustand, Testing
- vite.config.ts
- tsconfig.json (strict mode)
- tailwind.config.ts
- vitest.config.ts
- playwright.config.ts
- src/main.tsx, src/App.tsx
- src/mocks/server.ts (MSW setup)
- .env.example
- .gitignore
- README.md

## Reference Standards Integration

### Golang

- ✅ Clean architecture: cmd/ → internal/{domain,application,infrastructure,interface}/ → pkg/
- ✅ Dependency injection at main.go entrypoint
- ✅ All functions accept context.Context as first argument
- ✅ Repository pattern: domain interfaces → infrastructure implementations
- ✅ Middleware stack for logging, auth, recovery
- ✅ Structured logging with zerolog
- ✅ Error types in domain layer
- ✅ Testing structure: internal/domain/*_test.go, internal/application/*_test.go, etc.

### React

- ✅ Imports in order: React → external libs → local components → types → styles
- ✅ TypeScript strict mode (no 'any')
- ✅ Props interfaces on every component (`ComponentProps`)
- ✅ Functional components only, hooks for logic
- ✅ Custom hooks for business logic (useAuth, useForm, etc.)
- ✅ React Query for server state, Zustand for client state
- ✅ Error boundaries for error handling
- ✅ MSW for mocking API in tests
- ✅ Vitest + React Testing Library for unit/integration tests
- ✅ Playwright for E2E tests
- ✅ axe-core for accessibility testing

## Quality Checklist

Before returning the scaffolding to the user:

**Golang:**
- ✅ Directory tree is complete and follows clean architecture
- ✅ go.mod includes production dependencies (database, logging, HTTP router)
- ✅ main.go has dependency injection setup (no global state)
- ✅ cmd/server/main.go compiles without import errors
- ✅ pkg/middleware/ stubs have correct handler signatures
- ✅ Dockerfile multi-stage (builder + runtime)
- ✅ .github/workflows/test.yml is valid YAML
- ✅ .env.example lists all required env vars
- ✅ migrations/ directory exists with .gitkeep
- ✅ README.md has setup, build, run, test instructions

**React:**
- ✅ Directory tree matches chosen structure (Atomic / Feature-Based / Page-Based / Flat)
- ✅ package.json includes Vite, React, TypeScript, testing libraries (Vitest, RTL, Playwright)
- ✅ vite.config.ts configured for React and TypeScript
- ✅ tsconfig.json has strict mode enabled
- ✅ vitest.config.ts configured with RTL setup files
- ✅ playwright.config.ts configured for E2E tests
- ✅ src/App.tsx renders without errors
- ✅ src/mocks/server.ts sets up MSW server
- ✅ .env.example lists required API URLs
- ✅ README.md has setup (npm install), dev (npm run dev), test, build instructions

**Both:**
- ✅ All file paths use forward slashes (no Windows backslashes in examples)
- ✅ No hardcoded secrets in any configuration
- ✅ .gitignore includes node_modules/, dist/, coverage/, *.env.local
- ✅ Code examples are real and can be copy-pasted (not pseudocode)

## Interaction Examples

### Example 1: Full-Stack E-commerce Project

**User:** "I need scaffolding for an e-commerce platform"
**Stack:** Full-Stack
**Golang structure:** Always clean-architecture
**React structure:** Atomic Design (complex multi-team project)

**Scaffolding Generated:**

Backend (Golang):
```
ecommerce-backend/
├── cmd/server/main.go
├── internal/domain/product.go, order.go, user.go
├── internal/application/create_order.go, create_product.go
├── internal/infrastructure/repository/postgres_product_repo.go
├── internal/interface/http/product_handler.go, order_handler.go
├── pkg/middleware/auth.go, logging.go, recovery.go
├── migrations/
├── go.mod (with sqlx, chi, zerolog, etc.)
├── Dockerfile
└── .github/workflows/test.yml
```

Frontend (React):
```
ecommerce-frontend/
├── src/
│   ├── components/
│   │   ├── atoms/ (Button, Input, Badge, etc.)
│   │   ├── molecules/ (FormField, ProductCard, etc.)
│   │   ├── organisms/ (ProductList, Checkout, etc.)
│   │   └── pages/ (HomePage, ProductPage, CheckoutPage)
│   ├── hooks/useProducts.ts, useCart.ts, useAuth.ts
│   ├── services/productApi.ts, orderApi.ts
│   ├── types/domain.ts, api.ts
│   ├── mocks/server.ts, handlers.ts
│   └── App.tsx
├── package.json (Vite, React Query, Zustand, Tailwind, Vitest, Playwright)
└── README.md
```

### Example 2: Simple Backend Service

**User:** "API backend for user management"
**Stack:** Golang only
**Structure:** Clean-architecture (always)

**Scaffolding Generated:**
```
user-api/
├── cmd/server/main.go (HTTP server, dependency injection)
├── internal/domain/user.go (User entity, UserRepository interface)
├── internal/application/create_user_use_case.go
├── internal/infrastructure/repository/postgres_user_repo.go
├── internal/interface/http/user_handler.go, router.go
├── pkg/middleware/auth.go, logger.go
├── migrations/001_create_users_table.up.sql
├── go.mod (chi, sqlx, zerolog, github.com/jmoiron/sqlx)
├── Dockerfile
└── .github/workflows/test.yml
```

## Refinement Workflow

If the user asks for adjustments:
- "What would you like to change?" (add a new feature module, change structure, add Docker Compose, etc.)
- Provide updated file tree and stubs
- Ask: "Better? Ready to start implementing?"

## Dependencies & Context

**Used by:** After completing all 8 SDLC stages (or as standalone scaffolding)
**Feeds into:** Developer implementation — this scaffolding is the starting point for writing business logic
**References:**
- `../../references/clean-architecture.md` (Golang layout, repository pattern)
- `../../references/react-standards.md` (import order, naming, component structure)
- `../../references/golang-standards.md` (middleware, logging, database patterns)

**Output location:** `/sessions/[session-id]/mnt/outputs/[project-name]-scaffolding/`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with complete file tree, code stubs, and setup instructions
