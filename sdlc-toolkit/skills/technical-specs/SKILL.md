---
name: technical-specs
description: Generates code-ready technical specifications including API contracts (OpenAPI), component architectures (React), microservice designs (Golang), data models, and implementation checklists aligned to security and clean architecture standards.
model_invoked: true
triggers:
  - specs técnicas
  - technical specs
  - diseño técnico
  - spec técnica del feature
  - contrato de api
  - diseño de microservicio
  - estructura del componente react
  - diseño de base de datos
  - endpoints
  - openapi
  - api contract
  - component design
  - service design
  - data model
---

# Technical Specs Skill

## Purpose
Generate code-ready technical specifications that bridge the gap between functional specs and implementation. This skill produces:
- API contracts (OpenAPI/Swagger YAML)
- React component structures (atomic design, hooks, state management)
- Golang microservice architectures (package layout, domain/application/infrastructure)
- Data models and database schemas
- Deployment and infrastructure requirements
- Security and compliance checklists

## Critical: Reference Standards
**Before generating specs, ALWAYS review:**
1. `../../references/security-rules.md` — Auth, input validation, error handling, logging
2. `../../references/clean-architecture.md` — Layer separation, dependency injection, interfaces
3. `../../references/react-standards.md` — Hooks, components, TypeScript, testing
4. `../../references/golang-standards.md` — Package structure, middleware, database access

All technical specs MUST comply with these standards.

## Workflow

### 1. Feature Context
Ask the user:
- "What feature are you designing the technical specs for?" (should reference functional spec)
- "Is this React frontend, Golang backend, or both?" (or database design)
- "What are the key technical constraints?" (scalability, latency, integrations)

### 2. Architecture Decision
Ask clarifying questions based on technology:

**For React:**
- "Which atomic design level?" (atoms, molecules, organisms)
- "What state management?" (useState, custom hooks, Zustand)
- "Is this public/authenticated?" (determines auth handling)

**For Golang:**
- "Is this a new microservice or existing?" (affects package structure)
- "What's the primary concern?" (CRUD API, background job, data pipeline)
- "Which databases/external services?" (affects infrastructure dependencies)

**For Both:**
- "What's the data flow?" (request → processing → response/side effects)
- "Are there performance requirements?" (latency, throughput, concurrency)

### 3. Specification Generation
Generate comprehensive technical spec using the template at `assets/react-component-spec.md` or `assets/golang-service-spec.md`.

For full-stack features: Generate both specs.

### 4. File Output
Generate filename: `[feature-name]-technical-spec.md` or split:
- `[feature-name]-react-spec.md` (frontend)
- `[feature-name]-golang-spec.md` (backend)

Save to: `/sessions/[session-id]/mnt/outputs/`

### 5. Validation & Developer Readiness
Before returning:
- Show API contract (OpenAPI)
- Show React component tree OR Golang package layout
- Ask: "Is this ready for development? Any clarifications needed?"
- Offer to add implementation checklists or test plans

### 5.5 Security Checkpoint (CRITICAL)
**Before proceeding to next stages, validate against OWASP Top 10:**

Quick security validation:
- ✅ Authentication: Endpoints requiring auth have JWT/Bearer validation?
- ✅ Input Validation: All endpoints validate input (length, type, format)?
- ✅ Injection Prevention: Using parameterized queries (SQL)? Safe JSON handling (React)?
- ✅ Secrets: No hardcoded credentials, all via env vars?
- ✅ CORS: Specific origins whitelisted (not *)?
- ✅ Rate Limiting: Sensitive endpoints (auth, API) rate-limited?
- ✅ Error Handling: Errors don't expose internal details?
- ✅ Logging: Plan to log security events (no PII)?

**If any fail:**
Ask user: "Should I invoke `security-validation` skill for deep OWASP review before proceeding?"
- Option A: Yes → Invoke security-validation skill
- Option B: No → Flag in Output and continue

### 6. Database Schema, Test Strategy, Security Validation & Implementation Bridge

After the technical spec is approved by the user, ask:

**"Would you like to proceed with the next stages? You can now generate:"**

Options:
- A) **Security Validation** → Invoke `security-validation` skill
  - Purpose: Deep OWASP Top 10 validation of technical specs and design
  - When to use: Before implementation to prevent security issues at source
  - Output: Detailed findings per OWASP category, remediation roadmap, compliance checklist
  - Critical: Catches issues early (cheaper to fix in design than code)
  - Recommended: Run BEFORE database/test/implementation steps

- B) **Database Schema** → Invoke `database-schema` skill
  - Purpose: Generate SQL schemas, migrations, indexes, seed data (for Golang/backend projects)
  - When to use: If this feature involves data persistence (most features do)
  - Output: production-ready DDL, migration pairs, repository interfaces
  - Note: Should be created BEFORE implementation scaffolding for backend
  - Pre-requisites: Technical spec must define data model/entities

- C) **Test Strategy (Stage 7)** → Invoke `test-strategy` skill
  - Purpose: Define comprehensive testing approach (unit, integration, E2E, accessibility, smoke tests)
  - Output: Test strategy document with real code examples, BDD scenarios, coverage targets, CI/CD integration
  - Recommended: Generates smoke tests that feed into deployment pipeline
  - After: Can then proceed to Deployment Specs (Stage 8)
  - Security Note: Includes security test cases (auth, injection, XSS, CSRF)

- D) **Deployment Specifications (Stage 8)** → Invoke `deployment-specs` skill
  - Purpose: Generate cloud-specific infrastructure configs (Terraform, CI/CD pipelines, secrets strategy)
  - Targets: Azure, AWS, or DigitalOcean
  - Context: Uses app type, ports, health endpoints, environment variables from this spec
  - Note: Can integrate smoke tests from separate test-strategy if created

- E) **Generate in sequence (RECOMMENDED)** → Security Validation → Database Schema → Test Strategy → Deployment Specs
  - Sequence: Spec → Security Review → Database → Test → Deploy
  - Result: Complete secure technical pipeline with validation at each step
  - Flow: Full SDLC from specs through production with security-first approach

- F) **Implementation Scaffolding** → Invoke `implementation-scaffolding` skill (standalone)
  - Purpose: Generate project boilerplate structure ready for coding
  - React: Asks for preferred folder structure (Atomic Design, Feature-Based, Page-Based, Flat)
  - Golang: Always clean-architecture with dependency injection setup
  - Output: Directory tree, config files, stub components/handlers, testing setup
  - Use case: After specs are done OR standalone for quick project kickstart
  - Note: Includes security hardening recommendations from checklist

- G) **No** → Technical spec is complete. Save and exit.

**Recommended full SDLC flow (SECURITY-FIRST):**
Security Validation → Database Schema (if backend) → Test Strategy (Stage 7) → Deployment Specs (Stage 8)

**For immediate development kickstart:**
Security Validation + Database Schema + Implementation Scaffolding + Test Strategy, then deploy with deployment-specs.

## Reference Standards Integration

### Security Rules Applied
- ✅ All API endpoints require JWT validation (if authenticated)
- ✅ Input validation at API boundary (Golang backend)
- ✅ React components sanitize user input with DOMPurify
- ✅ No hardcoded secrets; all config via env vars
- ✅ CORS configured for specific origins
- ✅ Rate limiting on sensitive endpoints
- ✅ Errors don't expose system details
- ✅ Logs don't contain PII

### Clean Architecture Applied
- ✅ Golang: Strict layer separation (domain → application → infrastructure → interface)
- ✅ React: Atomic design (atoms → molecules → organisms → pages)
- ✅ Interfaces as contracts between layers
- ✅ Dependency injection (explicit, not global)
- ✅ Domain logic independent of frameworks
- ✅ Easy to test (domain pure, application mocked, infrastructure integration)

### React Standards Applied
- ✅ TypeScript strict mode, no `any`
- ✅ Functional components only, hooks for logic
- ✅ Custom hooks for business logic
- ✅ Props interfaces on every component
- ✅ React Query for server state, Zustand for client state
- ✅ Error boundaries, accessibility (a11y)
- ✅ Testing with Vitest + React Testing Library

### Golang Standards Applied
- ✅ Clean package structure (cmd, internal/domain, internal/application, internal/infrastructure)
- ✅ Repository pattern for data access
- ✅ Explicit error handling (no panic in production)
- ✅ Context propagation in all functions
- ✅ Middleware stack for logging, auth, recovery
- ✅ Structured logging with zerolog
- ✅ Parameterized SQL queries (no injection)

## Template Structure

### React Component Spec

```markdown
# Technical Specification: [Feature Name] (React)

## 1. Component Tree

[ASCII tree showing atomic design hierarchy]

## 2. Component Specifications

### Component 1: [Name]

**Atomic Level:** [Atom/Molecule/Organism/Page]
**Props Interface:** [TypeScript interface]
**Hooks Used:** [Custom hooks, built-in hooks]
**State Management:** [useState, Zustand, React Query]
**Styling:** [Approach: CSS modules, styled-components, Tailwind]

## 3. Data Fetching (React Query)

[useQuery/useMutation specifications]

## 4. Global State (Zustand)

[Store definitions, actions]

## 5. Testing Strategy

[Unit tests, integration tests, E2E tests]

## 6. Performance Considerations

[useMemo, useCallback, code splitting, bundling]

## 7. Security Checklist

[Input validation, XSS prevention, CSP, auth]

## 8. Accessibility (WCAG 2.1 AA)

[ARIA, semantic HTML, focus management]
```

### Golang Service Spec

```markdown
# Technical Specification: [Feature Name] (Golang)

## 1. Package Structure

[Directory layout with responsibilities]

## 2. API Contract (OpenAPI)

[YAML specification for all endpoints]

## 3. Domain Layer Design

[Entities, interfaces, domain services]

## 4. Application Layer Design

[Use cases, orchestration logic]

## 5. Infrastructure Layer Design

[Repository implementations, external integrations]

## 6. HTTP Handler Specifications

[Middleware, request/response handling]

## 7. Data Model & Database

[SQL schema, migrations, relationships]

## 8. Error Handling Strategy

[Custom error types, HTTP status codes]

## 9. Deployment & Infrastructure

[Docker, Kubernetes, observability]

## 10. Security Checklist

[Auth, validation, secrets, rate limiting]

## 11. Testing Strategy

[Unit, integration, E2E tests]
```

## Interaction Examples

### Example 1: React Form Component

**User:** "I need technical specs for a user registration form"

**Technical Spec Includes:**
- Component tree: RegisterForm (organism) → FormField (molecule) → Input (atom) + Label (atom)
- Props interface: `RegisterFormProps { onSuccess?: (user: User) => void }`
- Hooks: `useRegisterForm` (custom) for validation, `useMutation` (React Query) for API call
- Zustand store: `useAuthStore` to save user after registration
- Validation: Email regex, password strength, client-side + server-side
- Security: Input sanitization, CSRF token handling, password rules
- Testing: Unit tests for validation, E2E test for full flow
- Accessibility: Form labels, error messages linked to fields

### Example 2: Golang User Service

**User:** "Technical specs for a user management microservice"

**Technical Spec Includes:**
- Package structure: `cmd/server/main.go`, `internal/{domain,application,infrastructure,interface}`
- OpenAPI contract: POST/GET/PUT/DELETE /users endpoints with request/response schemas
- Domain layer: User entity, UserRepository interface, UserService for business logic
- Application layer: CreateUserUseCase, UpdateUserUseCase with input validation
- Infrastructure: PostgresUserRepository implementation, JWT middleware, error handling middleware
- Database: Users table schema, indexes, migrations
- Error handling: Custom error types (ErrInvalidEmail, ErrUserExists), appropriate HTTP status codes
- Security: JWT validation middleware, password hashing (bcrypt), rate limiting on auth endpoints, input validation
- Testing: Table-driven tests for domain logic, mocks for repositories, integration tests with real DB

## Quality Checklist

Before returning the spec to the user:

**For React:**
- ✅ Component tree shows atomic design levels
- ✅ All components have Props interfaces (no `any`)
- ✅ Custom hooks extract reusable logic
- ✅ React Query usage for server state clear
- ✅ Zustand store (if used) is explicitly defined
- ✅ Security considerations (XSS, CSP, auth) addressed
- ✅ Accessibility checklist included
- ✅ Testing strategy is specific (not vague)

**For Golang:**
- ✅ Package structure follows clean architecture (cmd, internal/{domain,application,infrastructure,interface})
- ✅ API contract is complete OpenAPI YAML
- ✅ Domain entities and interfaces defined
- ✅ Repository pattern applied
- ✅ Middleware stack clear (logging, auth, recovery)
- ✅ Error handling with custom error types
- ✅ Database schema with migrations included
- ✅ Security checklist covers auth, validation, rate limiting, logging
- ✅ Context propagation in all functions

**For Both:**
- ✅ References security-rules.md standards
- ✅ References clean-architecture.md principles
- ✅ References technology-specific standards (react-standards or golang-standards)
- ✅ Implementation is code-ready (not design-phase)
- ✅ Checklists are specific and actionable

**Deployment Readiness:**
- ✅ Health check endpoint defined (`GET /health` returns 200 with status JSON)
- ✅ Readiness endpoint defined (`GET /ready` returns 200 when dependencies available, 503 if not)
- ✅ Graceful shutdown strategy documented (SIGTERM handling, drain period)
- ✅ No secrets hardcoded anywhere (all via environment variables per security-rules.md)
- ✅ Deployment spec bridge offered to user (prompt for deployment-specs skill in Step 6)

## Refinement Workflow

If the user asks for adjustments:
- "What section would you like to refine?" (API contract, component tree, error handling, etc.)
- Edit and re-display
- Ask: "Better? Ready for development?"
- Offer to generate additional docs (deployment guide, testing plan, etc.)

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 6), can be used independently
**Feeds into:**
- Implementation (developers use these specs to code)
- `deployment-specs` skill (Stage 7): this technical spec provides app type, service ports, health endpoints, and environment variables that the deployment-specs skill consumes to generate cloud infrastructure
**References:**
- `../../references/security-rules.md` (auth, validation, error handling)
- `../../references/clean-architecture.md` (layer separation, patterns)
- `../../references/react-standards.md` (components, hooks, testing)
- `../../references/golang-standards.md` (package structure, middleware, database)
- `../../references/cloud-standards.md` (secrets management, deployment conventions) — used by downstream deployment-specs skill

**Output location:** `/sessions/[session-id]/mnt/outputs/[feature-name]-{react,golang}-technical-spec.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with embedded OpenAPI YAML, PlantUML, and code examples
