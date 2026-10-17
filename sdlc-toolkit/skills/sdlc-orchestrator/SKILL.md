---
name: sdlc-orchestrator
description: Master skill that orchestrates the complete product development lifecycle — from discovery to growth. Guides users through 13 stages in 3 phases (Discover → Build → Launch & Grow) — product discovery, product design, architecture, ATAM evaluation, architecture review, functional specs, UX/UI design, technical specs, test strategy, deployment specs, product analytics, go-to-market, and growth strategy. Use it whenever the user starts a new initiative, wants the full pipeline, or asks "what's next" for a product end-to-end — including launch, GTM or growth phases.
model_invoked: true
triggers:
  - iniciar proyecto
  - flujo completo de desarrollo
  - pipeline de desarrollo
  - ciclo de vida del producto
  - product lifecycle
  - sdlc
  - pdlc
  - comenzar desarrollo de
  - quiero construir
  - nueva iniciativa
  - de la idea al lanzamiento
  - idea to launch
  - start new project
  - development pipeline
  - full sdlc
---

# SDLC Orchestrator

## Purpose
The sdlc-orchestrator guides users through the complete product lifecycle — not just building software, but validating that it's worth building, and making sure it reaches customers and grows after deployment. It maintains state across 13 stages grouped in 3 phases, invokes specialized skills at each stage, and tracks progress.

| Phase | Question it answers | Stages |
|---|---|---|
| **A. Discover** | Should we build this, and what exactly? | 0–1 |
| **B. Build** | How do we design it, build it right, test it, and ship it? | 2–9 |
| **C. Launch & Grow** | How do we measure it, bring it to market, and grow it? | 10–12 |

Stage 12 (growth) closes the loop: its learnings feed the next iteration of Stage 0–1.

## How It Works

### 1. Initialization
When triggered, ask the user:
- **Project Name:** e.g., "UserManagement", "OrderProcessing"
- **Brief Description:** 1-2 sentences about what the project does
- **Key Stakeholders:** e.g., "Engineering team, Product team, C-level execs"
- **Timeline/Scope:** Rough estimate of complexity (Small/Medium/Large)
- **Starting point:** New idea (start at Stage 0), validated idea (Stage 1), existing product being extended, or already built and needs launch/growth (Stage 10+)

Use the starting point to recommend where to begin rather than always forcing Stage 0. A team with a running product asking about launch doesn't need to re-do architecture.

### 2. Present the Pipeline
Display the pipeline with status indicators:

```
📋 PRODUCT DEVELOPMENT LIFECYCLE PIPELINE
═══════════════════════════════════════════════════════════

── PHASE A · DISCOVER ─────────────────────────────────────
[0]  Product Discovery     (Problem & Market Validation)    [PENDING]
     └─ Output: [project]-discovery-brief.md · Skill: product-discovery
[1]  Product Design        (PRD)                            [PENDING]
     └─ Output: [project]-prd.md · Skill: product-design

── PHASE B · BUILD ────────────────────────────────────────
[2]  Architecture (arc42)  (System Design)                  [PENDING]
     └─ Output: [project]-arc42.md · Skill: arc42-doc
[3]  Evaluation (ATAM)     (Architecture Trade-offs)        [PENDING]
     └─ Output: [project]-atam-assessment.md · Skill: atam-facilitator
[4]  Architecture Review   (Quality & Gaps)                 [PENDING]
     └─ Output: [project]-arch-review.md · Skill: arch-review
[5]  Functional Specs      (Feature Specifications)         [PENDING]
     └─ Output: [project]-functional-specs.md · Skill: functional-specs
[6]  UX/UI Design          (Flows, Design System, Mockups)  [PENDING]
     └─ Output: [project]-ux-ui-design.md + design artifacts · Skill: ux-ui-design
[7]  Technical Specs       (Code-Ready Specifications)      [PENDING]
     └─ Output: [project]-technical-specs.md · Skill: technical-specs
[8]  Test Strategy         (Testing Specs & Smoke Tests)    [PENDING]
     └─ Output: [project]-test-strategy.md · Skill: test-strategy
[9]  Deployment Specs      (Cloud Infrastructure & CI/CD)   [PENDING]
     └─ Output: [project]-[cloud]-deployment-spec.md · Skill: deployment-specs

── PHASE C · LAUNCH & GROW ────────────────────────────────
[10] Product Analytics     (North Star, Tracking Plan)      [PENDING]
     └─ Output: [project]-measurement-plan.md · Skill: product-analytics
[11] Go-to-Market          (Positioning, Pricing, Launch)   [PENDING]
     └─ Output: [project]-gtm-plan.md · Skill: go-to-market
[12] Growth Strategy       (Loops, Experiments, Retention)  [PENDING]
     └─ Output: [project]-growth-plan.md · Skill: growth-strategy
     └─ ↺ Learnings feed back into Stage 0–1 (next iteration)

═══════════════════════════════════════════════════════════
```

### 3. Sequential Execution
After presenting the pipeline, ask the user:
- "Ready to begin with Stage [recommended]: [name]?" (Yes / Skip to [X] / Cancel)
- If Yes → Invoke the stage's skill
- If Skip → Ask which stage to start with
- If Cancel → Exit orchestrator, save progress

### 4. Stage Completion and Tracking
After each skill completes:
- Mark stage as `[COMPLETED]` in the pipeline display
- Save the output reference (brief, PRD, spec, plan…)
- Show the next stage
- Ask: "Continue to Stage [X]?" (Yes / Review Previous / Adjust / Exit)

**Decision gates** — some stages can change the path, so respect their outcome:
- After Stage 0: if the discovery recommendation is *Pivot* or *Kill*, don't push forward to the PRD. Offer to rerun discovery with the new direction or stop.
- After Stage 4: if the architecture review has critical Must-Have gaps, offer to loop back to Stage 2 before specs.
- After Stage 11: launch phases have go/no-go criteria; growth work (Stage 12) normally starts once the beta/GA data exists.

### 5. Progress Context
Maintain a running context block:
```
📊 PROJECT PROGRESS
Project: UserManagement
Created: 2026-07-01
Completed Stages: 2/13  ·  Phase: A · Discover ✓  →  B · Build

Documents Generated:
  A ✓ usermanagement-discovery-brief.md
    ✓ usermanagement-prd.md
  B ○ usermanagement-arc42.md
    ○ usermanagement-atam-assessment.md
    ○ usermanagement-arch-review.md
    ○ usermanagement-functional-specs.md
    ○ usermanagement-ux-ui-design.md
    ○ usermanagement-technical-specs.md
    ○ usermanagement-test-strategy.md
    ○ usermanagement-[cloud]-deployment-spec.md
  C ○ usermanagement-measurement-plan.md
    ○ usermanagement-gtm-plan.md
    ○ usermanagement-growth-plan.md

Next: Architecture (arc42)
```

## Behavior Rules

### Flexibility
- Users can skip stages if they have existing documentation
- Users can revisit previous stages to regenerate outputs
- Users can exit and resume later (context preserved in conversation)
- Users can run only one phase (e.g., "solo la fase de lanzamiento" → Stages 10–12)

### Parallel tracks (recommendations, not requirements)
- **Product analytics early:** Stage 10 is listed in Phase C, but the tracking plan is cheapest to build when it runs right after Stage 5 (functional specs) so events become requirements in Stage 7 and are tested in Stage 8. Suggest this when the user reaches Stage 5.
- **GTM prep during build:** positioning, pricing hypothesis and beta recruitment (Stage 11) can start while Stages 7–9 are in progress; launch timelines are usually longer than teams expect.

### Stage Details

#### Stage 0: Product Discovery
- **Purpose:** Validate the problem, customer and opportunity before committing to build
- **Inputs:** Idea, any evidence (interviews, data), business context
- **Outputs:** Discovery brief — JTBD, competitors, TAM/SAM/SOM, Lean Canvas, riskiest assumptions, validation plan, Go/Pivot/Kill
- **Skill:** `product-discovery`

#### Stage 1: Product Design
- **Purpose:** Define what to build (vision, personas, features, requirements)
- **Inputs:** Discovery brief from Stage 0 (or project concept if skipped)
- **Outputs:** Product Requirements Document (PRD)
- **Skill:** `product-design`

#### Stage 2: Architecture (arc42)
- **Purpose:** Design the high-level solution architecture
- **Inputs:** PRD from Stage 1
- **Outputs:** arc42 architecture document
- **Skill:** `arc42-doc` (existing skill)
- **Note:** References clean-architecture.md standards

#### Stage 3: Evaluation (ATAM)
- **Purpose:** Evaluate architecture against quality attributes
- **Inputs:** Architecture from Stage 2
- **Outputs:** ATAM assessment with risks and decisions
- **Skill:** `atam-facilitator` (existing plugin)

#### Stage 4: Architecture Review
- **Purpose:** Identify gaps, quality issues, improvement areas
- **Inputs:** Architecture + ATAM assessment
- **Outputs:** Architecture review report with recommendations
- **Skill:** `arch-review` (existing skill)

#### Stage 5: Functional Specifications
- **Purpose:** Detail features, flows, user stories, acceptance criteria
- **Inputs:** PRD + validated architecture
- **Outputs:** Functional specifications for each feature
- **Skill:** `functional-specs`
- **Scope:** Can create multiple feature specs per project

#### Stage 6: UX/UI Design
- **Purpose:** Define what the user sees and does, screen by screen — flows, information architecture, design system, wireframes/mockups with all states, accessibility, usability test plan
- **Inputs:** PRD + functional specs (+ measurement plan events if available; existing frontend code for existing products)
- **Outputs:** UX/UI design spec + component map; Design System and Design artifacts when available (otherwise token files and HTML mockups)
- **Skill:** `ux-ui-design`
- **Modes:** *Existing product* → respect the current stack and visual language (extract its design system, Impeccable only for diagnostics). *New product* → React + Tailwind + shadcn/ui, design system defined from scratch, Impeccable for polish.
- **Skip when:** the work is backend-only (APIs, jobs, integrations with no UI)

#### Stage 7: Technical Specifications
- **Purpose:** Code-ready specifications (API contracts, data models, component designs)
- **Inputs:** Functional specs + UX/UI design spec (component map, tokens) + architecture + reference standards (+ tracking plan events if Stage 10 ran early)
- **Outputs:** Technical specifications (React components, Golang services)
- **Skill:** `technical-specs`
- **Scope:** Generates specs per feature/component, references security-rules.md and clean-architecture.md

#### Stage 8: Test Strategy
- **Purpose:** Define comprehensive testing approach covering unit, integration, E2E, accessibility, performance and smoke tests
- **Inputs:** Technical specs from Stage 7 (API contracts, component tree, environment variables)
- **Outputs:** Test strategy document with real code examples, BDD scenarios, coverage targets, CI/CD integration guide, and smoke test suite
- **Skill:** `test-strategy`
- **Note:** References golang-standards.md and react-standards.md; smoke test suite integrates into Stage 9 CI/CD

#### Stage 9: Deployment Specs
- **Purpose:** Cloud-specific deployment infrastructure, CI/CD pipelines, secrets management, rollback plans
- **Inputs:** Technical specs from Stage 7 + smoke test suite from Stage 8
- **Outputs:** Deployment specification(s) with Terraform HCL, native IaC (Bicep/CloudFormation), GitHub Actions / Azure DevOps pipelines, deployment checklists
- **Skill:** `deployment-specs`
- **Cloud targets:** Azure, AWS, DigitalOcean, or Multi-cloud
- **Note:** References cloud-standards.md

#### Stage 10: Product Analytics
- **Purpose:** Define how product success is measured — North Star Metric, metric tree, AARRR funnel, tracking plan and instrumentation
- **Inputs:** PRD success criteria, functional specs flows, discovery brief
- **Outputs:** Measurement plan with event catalog, typed React/Golang instrumentation, dashboards, privacy rules
- **Skill:** `product-analytics`
- **Note:** Different from `observability-specs` (system health). Best run alongside Stage 5–7.

#### Stage 11: Go-to-Market
- **Purpose:** Bring the product to market — ICP, positioning, messaging, pricing & packaging, sales motion, phased launch (alpha/beta/GA) with go/no-go criteria, enablement
- **Inputs:** Discovery brief, PRD, measurement plan, deployment spec (release mechanics, feature flags)
- **Outputs:** GTM plan with launch timeline and launch KPIs
- **Skill:** `go-to-market`

#### Stage 12: Growth Strategy
- **Purpose:** Build a repeatable growth system after launch — growth model, loops, activation/retention/monetization levers, prioritized experiment backlog, feedback loop to the roadmap
- **Inputs:** Measurement plan, GTM plan, live product data
- **Outputs:** Growth plan with experiments (ICE/RICE, sample sizes) and 90-day targets
- **Skill:** `growth-strategy`
- **Note:** Closes the loop — new problems go to Stage 0, roadmap changes to Stage 1, winning experiments to Stage 5–7

## Exit Conditions

### Successful Completion
- User completes all 13 stages → Offer to export full project documentation bundle
- Display summary: "Project [X] is validated, specified, deployable, instrumented and has a launch and growth plan."
- Offer optional complementary skills:
  - **Database Schema** (`database-schema`) — SQL, migrations, indexes
  - **Implementation Scaffolding** (`implementation-scaffolding`) — project boilerplate (React / Golang clean-architecture)
  - **Observability Specs** (`observability-specs`) — logging, metrics, alerts, dashboards, SLO/SLI
  - **Security Validation** (`security-validation`) — OWASP validation of specs and code
  - **Harness Setup** (`harness-setup`) — CLAUDE.md + hooks for safe delegation to Claude Code
- Suggest the next iteration: "When growth experiments produce learnings, restart at Stage 0/1 for v2."

### Early Exit
- User chooses to exit mid-pipeline
- Save conversation state with project name and completed stages
- "You can resume this project anytime by saying '[Project Name] sdlc' or 'resume [Project Name]'"

## Implementation Notes

- **No file creation by this skill.** Outputs are created by invoked skills.
- **Conversation state is the source of truth** for what stages are complete.
- **Always show current progress** at the start of each message.
- **Default to sequential flow** but allow flexibility when user requests.
- **Collect feedback** after each stage: "How was this stage? Any adjustments needed?"

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Dependencies:** product-discovery, product-design, functional-specs, ux-ui-design, technical-specs, test-strategy, deployment-specs, product-analytics, go-to-market, growth-strategy, security-validation + optional database-schema, implementation-scaffolding, observability-specs, harness-setup + existing arc42-doc, arch-review, atam-facilitator
