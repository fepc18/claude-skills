---
name: test-strategy
description: Genera estrategias de testing completas para microservicios Golang y aplicaciones React. Incluye pirámide de tests, unit/integration/E2E test specs con código real, BDD scenarios en Gherkin, test data strategy, coverage targets, integración con CI/CD y smoke test suites que alimentan el deployment.
model_invoked: true
triggers:
  - test strategy
  - estrategia de testing
  - plan de pruebas
  - testing strategy
  - qué tests necesito
  - cómo testear
  - test plan
  - plan de tests
  - unit tests
  - integration tests
  - e2e tests
  - pruebas unitarias
  - pruebas de integración
  - cobertura de tests
  - test coverage
  - playwright
  - vitest
  - testing con golang
  - bdd
  - gherkin
  - smoke tests
---

# Test Strategy Skill

## Purpose

Generate comprehensive testing strategies that bridge technical specifications and deployment. This skill produces:
- Testing pyramid architecture (unit, integration, E2E breakdown)
- Real code examples for each test type (not pseudocode)
- Domain-driven test organization
- Mocking strategies (for Golang: interfaces; for React: MSW)
- BDD scenarios in Gherkin format
- Test data factories and fixtures
- Coverage targets by module/package
- Security and accessibility test cases
- CI/CD pipeline integration guide
- Smoke test suite (feeds into deployment specs)

## Critical: Reference Standards

**Before generating specs, ALWAYS review:**
1. `../../references/golang-standards.md` — Package structure, middleware, database access patterns
2. `../../references/react-standards.md` — Hooks, components, TypeScript, testing frameworks
3. `../../references/security-rules.md` — Auth, validation, error handling, test cases

All test strategies MUST comply with these standards.

## Workflow

### 1. Technology Stack

Ask the user:
- "What stack do you need the Test Strategy for?" (Golang backend / React frontend / Full-Stack)
- If Full-Stack: "Should I create separate specs or integrated specs?" (Usually separate is cleaner)

### 2. Scope & Coverage Targets

Ask clarifying questions:
- "What testing levels do you want to include?" (Unit required + Integration mínimum; E2E, Performance, Accessibility optional)
- "What's your target code coverage?" (Recommended: 80% global, 100% critical paths)
- "Are there security-critical endpoints or features?" (Payment, auth, user data - require 100% coverage)

### 3. Specification Generation

Generate comprehensive test spec using the template at `assets/golang-test-strategy.md` or `assets/react-test-strategy.md` based on user's technology choice.

For full-stack features: Generate both specs and link them with shared test data strategy section.

### 4. File Output

Generate filename: `[feature-name]-test-strategy.md` or split:
- `[feature-name]-golang-test-strategy.md` (backend)
- `[feature-name]-react-test-strategy.md` (frontend)

Save to: `/sessions/[session-id]/mnt/outputs/`

### 5. Validation & Developer Readiness

Before returning:
- Show testing pyramid with % breakdown
- Show sample unit test (table-driven for Golang, Vitest for React)
- Show CI/CD integration order
- Ask: "Is this ready for implementation? Any clarifications needed?"
- Offer to add performance test templates or additional test scenarios

### 6. Deployment Specs Bridge

After the test strategy is approved by the user, ask:

**"Would you like to also generate Deployment Specifications (Stage 8)? The smoke test suite from this strategy will be integrated into the CI/CD deployment pipeline for Azure, AWS, or DigitalOcean."**

Options:
- Yes → Invoke `deployment-specs` skill with context:
  - App type: [Golang / React / Full-Stack]
  - Health check paths: `/health` and `/ready`
  - Smoke test suite: (reference to test cases generated above)
  - Coverage requirement: (threshold from this spec)
- No → Test strategy is complete. Save and exit.

If Yes: The deployment-specs skill will reference smoke tests from this test strategy in the CI/CD pipeline generation.

## Reference Standards Integration

### Testing Pyramid Ratios

**Golang Microservices:**
- Unit Tests (Domain + Application): 70% → test pure domain logic, use cases, validation rules
- Integration Tests (Repositories + External): 20% → real database, external service mocks (MSW)
- E2E / Contract Tests (HTTP handlers): 10% → API endpoints, happy paths, error responses

**React Applications:**
- Unit Tests (Components + Custom Hooks): 60% → rendering, event handling, hook logic
- Integration Tests (User Flows): 30% → multi-component interactions, form submissions, data fetching
- E2E Tests (Critical Happy Paths): 10% → full user journeys in Playwright

### Security Tests Applied

- ✅ Protected endpoints require valid JWT (401 without token)
- ✅ Expired tokens rejected (401 on auth endpoint)
- ✅ SQL injection attempts rejected (400 Bad Request)
- ✅ Oversized payloads rejected (413 Payload Too Large)
- ✅ Rate limiting enforced on sensitive endpoints (429 Too Many Requests)
- ✅ XSS prevention in React components (DOMPurify tested)
- ✅ CSRF token validation tested

### Clean Architecture Applied

- ✅ Golang: Strict layer separation in tests (domain → application → infrastructure → interface)
- ✅ React: Component isolation (atom tests independent of page context)
- ✅ Mocks at layer boundaries (never mock internals of layer under test)
- ✅ Integration tests use real databases (testcontainers pattern)
- ✅ E2E tests exercise full request path (no mocking at HTTP handler level)

## Template Structure

### Golang Test Strategy

```markdown
# Test Strategy: [Feature Name] (Golang)

## 1. Testing Pyramid

Distribución por nivel (70/20/10 pattern)
- Unit: 70% → domain + application layer
- Integration: 20% → repositories + external services
- E2E/Contract: 10% → HTTP endpoints

## 2. Unit Tests — Domain Layer

Table-driven test pattern, all domain logic here

## 3. Unit Tests — Application Layer

Mocking via interfaces (never concrete implementations)

## 4. Integration Tests — Repository Layer

Real database with testcontainers or test DB

## 5. Handler Tests — HTTP Layer

Request/response validation, middleware testing

## 6. Security Test Cases

Auth, validation, injection, rate limiting tests

## 7. BDD Scenarios (Gherkin)

Feature definitions with Scenario outlines

## 8. Test Data Strategy

Factory functions for entities

## 9. Coverage Targets

Table with targets per package

## 10. Performance Tests

Benchmarks for critical paths

## 11. CI/CD Test Integration

Order: unit → integration → security → coverage

## 12. Smoke Test Suite

Post-deployment verification tests

## 13. Test Checklist

Pre-implementation verification
```

### React Test Strategy

```markdown
# Test Strategy: [Feature Name] (React)

## 1. Testing Pyramid

Distribución por nivel (60/30/10 pattern)
- Unit: 60% → components + custom hooks
- Integration: 30% → user flows
- E2E: 10% → critical happy paths

## 2. Unit Tests — Components

Vitest + React Testing Library patterns

## 3. Unit Tests — Custom Hooks

renderHook testing patterns

## 4. Integration Tests — User Flows

MSW mock setup for API calls

## 5. E2E Tests — Playwright

Critical user journeys

## 6. Accessibility Tests

axe-core and WCAG 2.1 AA compliance

## 7. Security Test Cases

XSS prevention, sensitive data protection

## 8. Test Data / Fixtures

Factory functions for test entities

## 9. Coverage Targets

Table with targets per area

## 10. CI/CD Test Integration

Order: type check → lint → unit+integration → coverage → a11y → E2E

## 11. Smoke Test Suite

Post-deployment verification tests

## 12. Test Checklist

Pre-implementation verification
```

## Quality Checklist

Before returning the spec to the user:

**For Golang:**
- ✅ Testing pyramid clearly defined with % breakdown
- ✅ Table-driven test examples shown (not pseudocode)
- ✅ Mocking via interfaces demonstrated
- ✅ Integration test DB pattern (testcontainers or test fixture)
- ✅ Security test cases cover auth, validation, injection, rate limiting
- ✅ BDD scenarios in valid Gherkin syntax
- ✅ Coverage targets specified per package (domain 90%, application 85%, etc.)
- ✅ CI/CD order defined (unit → integration → security → coverage check)
- ✅ Smoke test suite includes health checks, critical endpoints
- ✅ Race detector guidance (`go test -race`)
- ✅ No `t.Skip()` without justification
- ✅ No `time.Sleep()` in tests

**For React:**
- ✅ Testing pyramid with % breakdown
- ✅ Vitest + React Testing Library patterns shown
- ✅ Custom hook testing with renderHook
- ✅ MSW mock setup for API integration tests
- ✅ Playwright E2E test structure
- ✅ axe-core accessibility testing included
- ✅ Security tests cover XSS, sensitive data exposure
- ✅ Test data factories for consistent fixtures
- ✅ Coverage targets per area (UI 80%, hooks 90%, etc.)
- ✅ CI/CD order defined (type check → lint → tests → coverage → a11y → E2E)
- ✅ Smoke test suite includes app load, API health, routing
- ✅ No `setTimeout` in tests (use `waitFor` instead)

**For Both:**
- ✅ References golang-standards.md or react-standards.md
- ✅ References security-rules.md for test cases
- ✅ Code examples are real implementations (not pseudocode)
- ✅ Test strategy is implementation-ready (not design-phase)
- ✅ Checklists are specific and actionable
- ✅ Smoke test suite defined and ready for deployment pipeline
- ✅ Deployment specs bridge offered (prompt for deployment-specs in Step 6)

## Interaction Examples

### Example 1: Golang User Service Testing

**User:** "I need test strategy for the user management microservice we designed in technical specs"

**Test Strategy Includes:**
- Testing Pyramid: 70% unit (User entity, CreateUserUseCase), 20% integration (PostgresUserRepository with real DB), 10% E2E (POST /users endpoint)
- Unit Tests Domain: Table-driven tests for User.ValidateEmail(), User.HashPassword()
- Unit Tests Application: Mock UserRepository on CreateUserUseCase, test validation logic
- Integration Tests: testcontainers PostgreSQL, test actual repository CRUD operations
- Handler Tests: HTTP POST /users, validate JWT middleware, error responses
- Security Tests: 401 without token, 400 on invalid email, 409 on duplicate email, rate limiting on auth endpoints
- BDD: Feature "User Management" with Scenario "Create valid user" and "Email already exists"
- Test Data: NewUserFactory(), NewUserWithEmail(email string)
- Coverage: domain 90%, application 85%, infrastructure 70%
- CI/CD: Unit tests in PR, integration + security in merge to main, coverage > 80% required
- Smoke Tests: `GET /health`, `GET /ready`, `POST /auth/login`, verify user was created

### Example 2: React Registration Form Testing

**User:** "I need test strategy for the user registration form component"

**Test Strategy Includes:**
- Testing Pyramid: 60% unit (RegisterForm, FormField, Input), 30% integration (full form flow with MSW API mock), 10% E2E (happy path in Playwright)
- Unit Tests: Form validation (email, password strength), field rendering, button states
- Custom Hook Tests: useRegisterForm validation logic with renderHook
- Integration Tests: MSW mocking /api/users endpoint, user fills form + submits + success message appears
- E2E Tests: Playwright navigates to /register, fills form, submits, redirects to /login
- Accessibility: Form labels linked to inputs, error messages associated with fields, keyboard navigation
- Security Tests: Input sanitization (XSS payload rejected), no sensitive data in localStorage
- Test Data: createMockUser(), createMockUserList()
- Coverage: components 80%, hooks 90%, utils 95%
- CI/CD: Vitest in PR, Playwright on merge to staging, axe-core accessibility audit
- Smoke Tests: App loads, registration route accessible, API responds

## Refinement Workflow

If the user asks for adjustments:
- "What section would you like to refine?" (Testing Pyramid, unit tests, security tests, coverage targets, etc.)
- Edit and re-display
- Ask: "Better? Ready for implementation?"
- Offer to add performance test templates, stress test scenarios, or chaos engineering patterns

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 7), can be used independently
**Feeds into:**
- Implementation (QA and developers use these specs to create tests)
- `deployment-specs` skill (Stage 8): this test strategy provides smoke test suite that gets integrated into CI/CD pipelines
**References:**
- `../../references/golang-standards.md` (testing patterns, mocking, table-driven tests)
- `../../references/react-standards.md` (Vitest, RTL, E2E patterns, axe-core)
- `../../references/security-rules.md` (auth, validation, security test cases)

**Output location:** `/sessions/[session-id]/mnt/outputs/[feature-name]-test-strategy.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with embedded code examples, Gherkin, and YAML
