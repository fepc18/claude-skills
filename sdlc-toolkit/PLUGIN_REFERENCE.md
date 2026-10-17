# sdlc-toolkit Plugin — Complete Reference Guide

## Overview

**sdlc-toolkit** is a comprehensive software development lifecycle plugin that orchestrates a 13-stage product lifecycle in 3 phases — **Discover → Build → Launch & Grow** — from problem validation to production deployment, go-to-market and growth, plus complementary skills for acceleration and safety guardrails.

**Problem Solved:** Teams lack structured methodology to bridge gap between validated problem → specification → implementation → deployment → launch → growth. Results in misalignment, rework, inadequate testing, unsafe deployments.

**Solution:** Sequential workflow with specialized skills, each producing auditable deliverables aligned to industry standards (clean architecture, security rules, cloud conventions).

---

## Core Philosophy

- **Structured but Flexible:** 13-stage core pipeline (3 phases) + optional complementary skills
- **Full Product Lifecycle:** Building is not the finish line — products are validated before building and measured, launched and grown after deploying
- **Production-Ready Outputs:** Every skill generates real, executable code/config (not pseudocode)
- **Reference-Based:** All outputs comply with project's reference standards (golang-standards.md, react-standards.md, security-rules.md, cloud-standards.md, clean-architecture.md)
- **Autonomous Delegation:** Harness Engineering enables safe Claude Code autonomy with guardrails
- **Auditable Everything:** All outputs are git-committable, reviewable, reversible

---

## Skills Architecture

### PHASE A: Discover (Stages 0–1)

#### Stage 0: product-discovery
- **Purpose:** Validate WHETHER to build — problem, customer and opportunity
- **Inputs:** Idea, evidence (interviews, data), business context
- **Outputs:** Discovery brief — problem statement, Jobs-to-be-Done, evidence log, competitive landscape, TAM/SAM/SOM (bottom-up), Lean Canvas, Opportunity Solution Tree, riskiest assumptions, validation experiments, interview guide, Go / Pivot / Kill recommendation
- **Decision gate:** Pivot/Kill stops the pipeline before the PRD
- **Output Location:** `[project-name]-discovery-brief.md`

### TIER 1: Core SDLC Pipeline (Stages 1–9 — Sequential)

#### Stage 1: product-design
- **Purpose:** Define WHAT to build
- **Inputs:** Project concept, stakeholders, success criteria
- **Outputs:** Product Requirements Document (PRD) with vision, personas, features, user stories, epics, success metrics
- **Workflow:** Project context → Stakeholders → Features → Acceptance criteria → Success metrics → Generate PRD
- **References:** None (foundational)

#### Stage 2: arc42-doc (existing skill)
- **Purpose:** Design HOW to build it (architecture blueprint)
- **Inputs:** PRD from Stage 1
- **Outputs:** arc42 architecture document (structure, context, building blocks, crosscutting concepts)
- **References:** clean-architecture.md

#### Stage 3: atam-facilitator (existing skill)
- **Purpose:** Evaluate architecture quality against quality attributes
- **Inputs:** Architecture from Stage 2
- **Outputs:** ATAM assessment with risks, trade-offs, architectural decisions
- **References:** security-rules.md, cloud-standards.md

#### Stage 4: arch-review (existing skill)
- **Purpose:** Identify gaps, quality issues, improvement recommendations
- **Inputs:** Architecture + ATAM assessment
- **Outputs:** Architecture review report with prioritized recommendations
- **References:** clean-architecture.md, security-rules.md

#### Stage 5: functional-specs
- **Purpose:** Detail FEATURES with acceptance criteria and flows
- **Inputs:** PRD + validated architecture
- **Outputs:** Feature specifications with user stories, acceptance criteria (BDD/Gherkin), wireframes, state flows
- **Workflow:** Feature selection → User stories → Acceptance criteria → Test scenarios → Wireframes → Generate spec
- **References:** None (bridges PRD → Technical Specs)

#### Stage 6: ux-ui-design
- **Purpose:** Define what the user SEES and DOES, screen by screen
- **Inputs:** PRD, functional specs, measurement plan events; existing frontend code for existing products
- **Outputs:** UX/UI design spec — user flows (Mermaid), screen inventory + navigation, design system (tokens + component inventory), wireframes → mockups with all states (empty, loading, error, no permission), WCAG 2.2 AA requirements, usability test plan, component map for technical-specs
- **Two modes:**
  - *Existing product* — respects the current stack and visual language (e.g., Bootstrap 5 + react-bootstrap + SCSS); extracts its design system, logs inconsistencies as design debt, Impeccable only for diagnostics
  - *New product* — React + TypeScript + Tailwind + shadcn/ui (Radix) + lucide + TanStack Table + React Hook Form/Zod; tokens as CSS variables (light/dark); Impeccable for polish
- **Where designs live:** Claude **Design System** and **Design** artifacts when available; otherwise token files + HTML mockups in the real stack
- **Skip when:** backend-only work
- **Output Location:** `[project-name]-ux-ui-design.md`

#### Stage 7: technical-specs
- **Purpose:** Generate CODE-READY specifications
- **Inputs:** Functional specs + Architecture + Reference standards
- **Outputs:**
  - OpenAPI/Swagger contracts (REST APIs)
  - React component architectures (with props, hooks, state management)
  - Golang microservice designs (packages, interfaces, repository pattern)
  - Data models + database entities
  - Implementation checklists
- **Workflow:** Feature context → Architecture decision → Spec generation → API contracts → Component trees → Validation
- **References:** golang-standards.md, react-standards.md, security-rules.md, clean-architecture.md
- **Bridge Options:** Database Schema → Test Strategy → Deployment Specs (recommended sequence)

#### Stage 8: test-strategy
- **Purpose:** Define comprehensive testing approach with code examples
- **Inputs:** Technical specs (API contracts, component tree, env vars)
- **Outputs:**
  - Testing pyramid distribution (unit/integration/E2E percentages)
  - Real code examples (Jest/Vitest for React, Go table-driven tests, etc.)
  - BDD scenarios (Gherkin format)
  - Coverage targets by module
  - CI/CD integration guide
  - **Smoke test suite** (feeds into Stage 9)
- **Golang Pattern:** Table-driven tests, mocking via interfaces, integration tests with testcontainers
- **React Pattern:** Vitest + React Testing Library, Playwright E2E, axe-core accessibility
- **Workflow:** Stack selection → Scope & coverage → Spec generation → Smoke tests → CI/CD integration
- **References:** golang-standards.md, react-standards.md, security-rules.md
- **Output Location:** `/sessions/[session-id]/mnt/outputs/[project-name]-test-strategy.md`

#### Stage 9: deployment-specs
- **Purpose:** Generate cloud-specific infrastructure and CI/CD pipelines
- **Inputs:** Technical specs (app type, ports, health endpoints, env vars) + Smoke tests from Stage 8
- **Outputs:**
  - Terraform HCL (multi-cloud standard)
  - Native IaC (Bicep for Azure, CloudFormation for AWS, app.yaml for DigitalOcean)
  - GitHub Actions workflows (with OIDC authentication)
  - Azure DevOps pipelines (with Workload Identity Federation)
  - Secrets management strategy (Key Vault, Secrets Manager, app config)
  - Blue/green deployment patterns
  - Rollback procedures (infrastructure, application, database)
  - Deployment checklists (pre/during/post)
  - Smoke test integration
- **Cloud Targets:** Azure (Terraform + Bicep) / AWS (Terraform + CloudFormation) / DigitalOcean (Terraform + App Spec) / Multi-cloud
- **Workflow:** Cloud selection → App type → Environment scope → Spec generation → Validation → Checklist
- **References:** cloud-standards.md, security-rules.md
- **Bridge:** Observability Specs (for production monitoring)
- **Output Location:** `/sessions/[session-id]/mnt/outputs/[project-name]-[cloud]-deployment-spec.md`

---

### PHASE C: Launch & Grow (Stages 10–12)

#### Stage 10: product-analytics
- **Purpose:** Define HOW product success is measured (product health, not system health — see observability-specs)
- **Inputs:** PRD success criteria, functional specs flows, discovery brief
- **Outputs:** Measurement plan — North Star Metric + metric tree, AARRR metrics with formulas/owners, HEART per feature, identity model, event catalog (tracking plan), typed React `useTrack()` wrapper, Golang `EventPublisher` port + adapter, dashboards, privacy/PII governance
- **Timing:** Best run right after Stage 5 so events become requirements in Stage 7 and are tested in Stage 8
- **References:** security-rules.md, react-standards.md, golang-standards.md, clean-architecture.md
- **Output Location:** `[project-name]-measurement-plan.md`

#### Stage 11: go-to-market
- **Purpose:** Bring the product to market
- **Inputs:** Discovery brief, PRD, measurement plan, deployment spec
- **Outputs:** GTM plan — ICP + buying roles, positioning (April Dunford), messaging per persona, pricing & packaging (value metric, tiers, local taxes/payments), sales motion (PLG / sales-led / partner-led), channel priorities, launch tier, alpha → beta → GA phases with go/no-go criteria, T-8w → T+30d timeline, sales/support/legal/billing readiness, launch KPIs, risks
- **Output Location:** `[project-name]-gtm-plan.md`

#### Stage 12: growth-strategy
- **Purpose:** Build a repeatable growth system after launch, and close the lifecycle loop
- **Inputs:** Measurement plan, GTM plan, live product data
- **Outputs:** Growth plan — PMF check, growth model equation with sensitivity analysis, funnel diagnosis, growth loops, levers per stage (activation, retention, churn, expansion, referral), ICE/RICE experiment backlog, A/B test design with sample size, operating rhythm, feedback loop into discovery/PRD/specs, 90-day targets
- **Output Location:** `[project-name]-growth-plan.md`

---

### TIER 2: Optional Complementary Skills (Acceleration & Execution)

#### database-schema
- **Purpose:** Generate production-ready SQL schemas, migrations, indexes
- **When to Use:** After Stage 7, before implementation if backend/database involved
- **Inputs:** Technical specs (data models, entities)
- **Outputs:**
  - Entity Relationship Diagram (ASCII)
  - DDL SQL with UUID PKs, timestamps, constraints
  - Migration pairs (001_*.up.sql + .down.sql) — golang-migrate format
  - Foreign key relationships + join tables for N:M
  - Index strategy with naming pattern idx_{table}_{column}
  - Seed data (test fixtures)
  - Repository interface stubs (Go domain layer)
  - Database checklist
- **Key Features:**
  - UUID PRIMARY KEY on all tables (never serial/int)
  - created_at, updated_at TIMESTAMP WITH TIME ZONE on all tables
  - Forward-only migration rule (CRITICAL: never rollback in production)
  - Parameterized queries ($1, $2) — no string formatting
- **Workflow:** Entity identification → Relationship mapping → Query patterns → Schema generation → Migrations → Seed data
- **References:** golang-standards.md, clean-architecture.md, cloud-standards.md (forward-only rule)
- **Bridge:** Implementation Scaffolding (generates repository implementations)
- **Output Location:** `/sessions/[session-id]/mnt/outputs/[project-name]-database-schema.md`

#### implementation-scaffolding
- **Purpose:** Generate complete project boilerplate ready for coding
- **When to Use:** Standalone or after Stages 7-9
- **Inputs:** Stack (Golang/React/Full-Stack), project name, features to scaffold
- **React Output (with structure choice):**
  - **Option A: Atomic Design** (atoms/molecules/organisms/pages) — recommended for large projects
  - **Option B: Feature-Based** (features/{auth,products,orders}/) — self-contained features
  - **Option C: Page-Based** (pages/, components/shared/) — simple structure
  - **Option D: Flat** (components/, hooks/, utils/) — minimal/MVP structure
  - Package.json with Vite, React Query, Zustand, Tailwind, Vitest, Playwright
  - vite.config.ts, tsconfig.json (strict mode), tailwind.config.ts
  - vitest.config.ts, playwright.config.ts
  - src/mocks/server.ts (MSW setup), src/App.tsx, src/main.tsx
  - .env.example, .gitignore, README.md
- **Golang Output (always Clean Architecture):**
  - cmd/server/main.go — dependency injection, graceful shutdown
  - internal/domain/ — entities, validation, repository interfaces
  - internal/application/ — use cases with DI
  - internal/infrastructure/repository/ — PostgreSQL implementations
  - internal/interface/http/ — handlers, router, middleware
  - pkg/middleware/ — auth, logger (zerolog), recovery
  - migrations/ — directory structure
  - go.mod with production dependencies
  - Dockerfile (multi-stage), docker-compose.yml
  - .github/workflows/test.yml, Makefile
  - .env.example, README.md
- **Key Features:**
  - Production-ready code (not stubs)
  - Real dependency injection (no globals)
  - Complete test setup
  - Health check endpoints (/health liveness, /ready readiness)
  - Structured logging (zerolog for Golang, console for React)
- **Workflow:** Stack selection → Structure choice (React) → Project config → File generation → Output
- **References:** clean-architecture.md, react-standards.md, golang-standards.md
- **Output Location:** `/sessions/[session-id]/mnt/outputs/[project-name]-scaffolding/`

#### observability-specs
- **Purpose:** Generate production monitoring strategy (logging, metrics, alerts, dashboards, SLO/SLI)
- **When to Use:** After Stage 9 (deployment specs complete)
- **Inputs:** Stack type (Golang/React/Full-Stack), cloud platform, compliance requirements
- **Golang Output:**
  - Structured logging (zerolog with JSON format, zero PII)
  - Prometheus metrics (counters, histograms, gauges)
  - Health endpoints (/health liveness on port 8081, /ready readiness)
  - OpenTelemetry tracing (Jaeger/X-Ray exporters)
  - Alert rules (error rate >1%, p99 latency >500ms, pod restarts >3)
  - Cloud-specific setup (Azure App Insights / AWS CloudWatch / DigitalOcean Prometheus+Grafana)
  - Grafana dashboard JSON
  - SLO/SLI definitions (uptime, latency, error rate)
  - Log retention policy (30-90 days based on compliance)
  - CI/CD integration for observability
- **React Output:**
  - Error Boundary implementation (catches unhandled component errors)
  - Core Web Vitals tracking (LCP <2.5s, INP <200ms, CLS <0.1)
  - Error reporting (Sentry / Azure App Insights / DataDog)
  - User analytics (anonymous, no PII)
  - RUM (Real User Monitoring) setup
  - Lighthouse CI for performance budgets
  - Frontend SLO (page load <2s, error rate <0.1%)
- **Key Features:**
  - Zero PII rule enforced (no emails, passwords, tokens in logs)
  - Multi-cloud support (Azure, AWS, DigitalOcean)
  - Compliance-aware (GDPR, HIPAA, SOC2 retention policies)
  - Production-ready examples (not templates)
- **Workflow:** Stack selection → Cloud platform → Compliance requirements → SLO targets → Spec generation → Bridge to deployment
- **References:** cloud-standards.md, security-rules.md, golang-standards.md, react-standards.md
- **Output Location:** `/sessions/[session-id]/mnt/outputs/[project-name]-observability-specs.md`

#### harness-setup
- **Purpose:** Generate Claude Code guardrails for safe autonomous delegation
- **When to Use:** After any/all stages when ready to delegate work to Claude Code
- **Inputs:** Project name, tech stack, critical paths, conventions, test commands
- **Outputs:**
  - **CLAUDE.md** — Work contract defining:
    * Exact stack versions (Node 20.11.0, Go 1.21, etc.)
    * Folder structure (where code goes, never write outside these paths)
    * Protected paths (migrations, infra, secrets — require approval)
    * Development conventions (import order, naming, patterns)
    * Testing requirements (which tests must pass before commit)
    * CI/CD commands (linting, type checking, build)
    * Decision protocol (when to stop and ask for human approval)
    * 3-5 real code examples showing correct patterns
    * Troubleshooting guide
  - **pretooluse-hook.sh** — PreToolUse hook that:
    * Blocks writes to protected paths (migrations, infra, .env*)
    * Detects destructive commands (rm -rf, git reset --hard)
    * Warns about deprecated patterns
    * Returns actionable error messages
  - **posttooluse-hook.sh** — PostToolUse hook that:
    * Runs tests after every file change
    * Verifies linting passes
    * Checks build succeeds
    * Creates autonomous self-correction loop (agent fixes its own errors)
  - **settings-json-snippet.json** — Ready-to-merge .claude/settings.json config
  - **HARNESS_SETUP_GUIDE.md** — Step-by-step installation + activation
- **Key Features:**
  - Makes Claude Code work auditable and reversible
  - Prevents unauthorized modifications to critical paths
  - Autonomous feedback loop (agent self-corrects)
  - No false positives (doesn't block legitimate work)
  - Project-specific (customized to team's actual conventions)
- **Workflow:** Project context → Critical protections → Team conventions → Harness generation → Setup guide → Activation
- **References:** security-rules.md, clean-architecture.md
- **Output Location:** `/sessions/[session-id]/mnt/outputs/[project-name]-harness-setup/`

---

## Master Orchestrator Skill: sdlc-orchestrator

**Purpose:** Guides users through all 13 stages (3 phases) sequentially, maintains progress state, offers optional skills

**Workflow:**
1. Initialization (project name, description, stakeholders, scope)
2. Present 13-stage pipeline visualization grouped by phase
3. Sequential execution (Stage 0 → 1 → ... → 12), with decision gates after Stage 0 (Go/Pivot/Kill), Stage 4 (critical gaps) and Stage 11 (launch go/no-go)
4. After each stage: mark complete, show next stage, ask to continue
5. At completion: offer optional skills (database-schema, implementation-scaffolding, observability-specs, harness-setup)
6. Export full project documentation bundle

**Progress Tracking:**
- Maintains state of which stages completed
- Shows generated files at each stage
- Allows skipping/revisiting stages
- Resumable (user can exit and come back)

---

## Data Flow & Integration

```
[0] product-discovery → Discovery Brief (Go / Pivot / Kill)
         ↓
[1] product-design → PRD
         ↓
[2] arc42-doc → Architecture
         ↓
[3] atam-facilitator → ATAM Assessment
         ↓
[4] arch-review → Architecture Review
         ↓
[5] functional-specs → Feature Specs
         ↓
[6] ux-ui-design → Flows, Design System, Mockups, Component Map   (skip for backend-only)
         ↓
[7] technical-specs → API Contracts, Component Trees, Data Models
         ↓
    ├─→ database-schema → SQL Schemas + Migrations
    ├─→ implementation-scaffolding → Project Boilerplate
    ├─→ [8] test-strategy → Testing Strategy + Smoke Tests
    │       ↓
    │   [9] deployment-specs → Cloud Infrastructure + CI/CD
    │       ↓
    │   observability-specs → Monitoring Strategy
    │       ↓
    │   harness-setup → CLAUDE.md + Hooks (Safe Delegation)
    │
    └─→ [Ready for Implementation]
         ↓
[10] product-analytics → North Star + Tracking Plan   (ideally in parallel with [5]–[7])
         ↓
[11] go-to-market → Positioning, Pricing, Launch Plan
         ↓
[12] growth-strategy → Growth Model, Loops, Experiments
         ↺ learnings → [0] product-discovery / [1] product-design (next iteration)
```

**Recommended Sequences:**

**Full Lifecycle (13 stages):**
1. product-discovery → product-design
2. arc42-doc → atam-facilitator → arch-review
3. functional-specs → ux-ui-design → technical-specs → test-strategy → deployment-specs
4. product-analytics → go-to-market → growth-strategy

**For an Existing Product Going to Market:**
1. product-analytics → go-to-market → growth-strategy

**For a New Idea (validate before investing):**
1. product-discovery → (Go) → product-design

**For Implementation Kickstart:**
1. technical-specs → database-schema → implementation-scaffolding → test-strategy

**For Safe Team Delegation:**
1. [Any stage complete] → harness-setup → CLAUDE.md + hooks active

**For Production Visibility:**
1. deployment-specs → observability-specs → monitoring ready

---

## Reference Standards Compliance

Every skill output aligns with project's reference standards:

### clean-architecture.md
- Golang: cmd/ → internal/{domain,application,infrastructure,interface}/ → pkg/
- React: Atomic Design (atoms→molecules→organisms→pages) or Feature-Based
- Dependency Injection at entrypoints, no global state
- Repository pattern for data access
- Layer separation enforced

### golang-standards.md
- golang-migrate format (001_verb_entity.up.sql + .down.sql)
- UUID PRIMARY KEYs, sqlx library
- Structured logging (zerolog) with JSON format
- Health endpoints (/health, /ready) on port 8081
- Middleware stack (auth, logger, recovery)
- Index naming: idx_{table}_{column}
- Parameterized queries ($1, $2, ...)

### react-standards.md
- TypeScript strict mode (no 'any')
- Functional components + hooks
- Props interfaces on every component
- React Query for server state, Zustand for client state
- Custom hooks for business logic
- Error boundaries, accessibility (a11y)
- Testing with Vitest + React Testing Library + Playwright
- Import order: React → external → local → types → styles

### security-rules.md
- JWT with rotation (15min access, 7 day refresh)
- No hardcoded secrets (env vars only)
- Input validation at API boundary
- Rate limiting on sensitive endpoints
- CORS restricted to specific origins (never *)
- Structured logging with zero PII
- HTTPS enforced everywhere
- Error messages don't expose system details

### cloud-standards.md
- Resource naming: {project}-{environment}-{resource-type}
- Tagging: project, environment, managed-by, owner
- Terraform backend remote (never local state)
- OIDC authentication for GitHub Actions (no long-lived tokens)
- Workload Identity Federation for Azure DevOps
- Forward-only migrations (CRITICAL: never rollback in production)
- Health checks port 8081 (separate from app)
- Secrets via cloud-native managers (Key Vault, Secrets Manager)

---

## Output Locations

All skills save outputs to `/sessions/[session-id]/mnt/outputs/` with predictable naming:

| Skill | Output Filename |
|-------|-----------------|
| product-design | [project-name]-prd.md |
| arc42-doc | [project-name]-arc42.md |
| atam-facilitator | [project-name]-atam-assessment.md |
| arch-review | [project-name]-arch-review.md |
| functional-specs | [feature-name]-functional-spec.md |
| technical-specs | [feature-name]-technical-spec.md |
| database-schema | [project-name]-database-schema.md |
| implementation-scaffolding | [project-name]-scaffolding/ (directory) |
| test-strategy | [project-name]-test-strategy.md |
| deployment-specs | [project-name]-[cloud]-deployment-spec.md |
| observability-specs | [project-name]-observability-specs.md |
| harness-setup | [project-name]-harness-setup/ (directory) |

---

## Key Principles

### 1. Production-Ready Outputs
- All code examples are real, executable (not pseudocode)
- All SQL is actual DDL (not illustrative)
- All configs are copy-paste ready
- All JSON/YAML is valid (can validate with jq, yaml validators)

### 2. Structured but Flexible
- Core pipeline is sequential (Stage 1→8 recommended)
- Optional skills can be used standalone or in any order
- Users can skip stages if they have existing work
- Can revisit any stage to regenerate

### 3. Auditable Everything
- All outputs are git-committable
- Generated code follows project conventions
- Clear explanations of decisions (why, not what)
- Diffs are meaningful and reviewable

### 4. Autonomous Self-Correction
- Tests verify code quality automatically
- Linting enforced before commits
- Health checks validate deployments
- Harness hooks prevent known mistakes

### 5. Team-Friendly Escalation
- Agent stops and asks for high-risk decisions
- Database schema changes require approval
- Public API signature changes require review
- Infrastructure changes require confirmation

---

## Quick Start Examples

### Example 1: Full Lifecycle (13 stages)
```
User: "Help me design a new project: expense tracking SPA"

Tool Flow:
1. product-design → PRD with features, personas, success metrics
2. arc42-doc → Architecture (React frontend + Node.js backend + PostgreSQL)
3. atam-facilitator → ATAM assessment
4. arch-review → Review report with recommendations
5. functional-specs → "Add Expense", "View Report", "Export CSV" specs
6. technical-specs → API contracts (REST), React component tree, data model
7. test-strategy → Jest tests, E2E flows, coverage targets
8. deployment-specs → Azure deployment with CI/CD (GitHub Actions)

Optional Next:
→ database-schema → SQL migrations
→ implementation-scaffolding → React Atomic Design boilerplate
→ observability-specs → Application Insights + Grafana setup
→ harness-setup → CLAUDE.md + hooks for safe delegation
```

### Example 2: Quick Implementation Kickstart
```
User: "I have a technical spec. Generate project structure + database."

Tool Flow:
→ implementation-scaffolding → Full Golang + React project structure
→ database-schema → PostgreSQL migrations + repository interfaces
→ test-strategy → Jest tests + Go tests + Playwright E2E setup

Result: Project ready to start coding in 30 minutes
```

### Example 3: Observability Setup
```
User: "We're deploying to production next week. Need monitoring strategy."

Tool Flow:
→ observability-specs → Configure:
  * Logging: zerolog + Azure Log Analytics
  * Metrics: Prometheus endpoints + AlertManager rules
  * Dashboards: Grafana panels
  * SLO: 99.9% uptime, p99 <250ms, error rate <1%
  * Health checks: /health and /ready endpoints

Result: Production-ready monitoring stack
```

### Example 4: Safe Delegation to Claude Code
```
User: "I want to delegate implementation to Claude Code safely."

Tool Flow:
→ harness-setup → Create:
  * CLAUDE.md (project rules, conventions, protected paths)
  * PreToolUse hook (blocks dangerous operations)
  * PostToolUse hook (verifies tests pass)
  * Setup guide (install in .claude/)

Result: Claude Code now works within guardrails:
  * Writes only to src/, tests/, not /migrations/
  * Always runs tests before commit
  * Asks before deleting files or changing APIs
  * Self-corrects when tests fail
```

---

## Common Questions

**Q: Can I skip stages?**
A: Yes. If you have existing PRD, skip product-design. If you have architecture, skip to functional-specs. The orchestrator allows flexibility.

**Q: Are the outputs standards-compliant?**
A: Yes. All outputs reference and comply with golang-standards.md, react-standards.md, clean-architecture.md, security-rules.md, cloud-standards.md.

**Q: Can I use skills standalone?**
A: Yes. Each skill is independent. Use `technical-specs` alone if you just need API contracts. Use `harness-setup` standalone for any project.

**Q: What if I have existing code?**
A: The toolkit generates NEW specifications/code. It doesn't modify existing projects. Use it to generate what's missing.

**Q: How long does each skill take?**
A: Depends on project complexity. Conversational time typically 10-30 minutes per skill. Generated outputs are production-ready immediately.

**Q: Can I customize outputs?**
A: Yes. Every skill has a refinement workflow: "What would you like to change?" → Edit section → Re-display → "Better?"

**Q: What if I disagree with a recommendation?**
A: You can override. The toolkit provides best practices, but teams have their own valid conventions. Adjust to match your project.

---

## Resources

- **Repository:** sdlc-toolkit plugin for Claude Code
- **Reference Standards:** Located in `/references/`
  - clean-architecture.md
  - golang-standards.md
  - react-standards.md
  - security-rules.md
  - cloud-standards.md
- **Assets:** Each skill has `/assets/` with templates, examples, code snippets
- **Docs:** Each skill has SKILL.md with full workflow documentation

---

## Version & Status

- **Current (v1.2.0):** 13-stage lifecycle (10 own skills + 3 reused) + 5 complementary skills + orchestrator — Discover, Build (now with UX/UI Design) and Launch & Grow phases
- **Tested:** All code examples verified to compile/run
- **Maintained:** Regular updates to match evolving best practices
- **Integration:** Works with Claude Code (Claude Opus, Sonnet, Haiku models)

---

## For AI Agents Using This Toolkit

### Best Practices

1. **Read CLAUDE.md First**
   - Every project has a CLAUDE.md defining rules
   - Read it before making changes
   - It's the source of truth for conventions

2. **Follow Reference Standards**
   - Check clean-architecture.md for folder structure
   - Check golang-standards.md / react-standards.md for code patterns
   - Check security-rules.md for auth/validation/logging
   - Check cloud-standards.md for deployment patterns

3. **Generate Incrementally**
   - Don't try to do all 13 stages at once
   - Complete one stage, then move to next
   - Iterate within each stage if needed

4. **Respect Protected Paths**
   - Never modify /migrations/, /infra/, .env* without asking
   - These are enforced by harness-setup hooks
   - If blocked, stop and explain what you need

5. **Test Before Output**
   - Run tests before committing (PostToolUse hook does this)
   - Verify linting passes
   - Check build succeeds
   - Self-correct when tests fail

6. **Output is Auditable**
   - Every file you create should be reviewable
   - Commit messages should be clear
   - Pull requests should have context
   - Team should be able to understand decisions

---

**Last Updated:** July 2026
**Maintainer:** Felipe Pabón
**License:** Aligned with Claude Code plugin standards
