---
name: sdlc-orchestrator
description: Master skill that orchestrates the complete software development lifecycle pipeline. Guides users through all 7 stages: product design, architecture, evaluation, architecture review, functional specs, technical specs, and deployment specs.
model_invoked: true
triggers:
  - iniciar proyecto
  - flujo completo de desarrollo
  - pipeline de desarrollo
  - sdlc
  - comenzar desarrollo de
  - quiero construir
  - nueva iniciativa
  - start new project
  - development pipeline
  - full sdlc
---

# SDLC Orchestrator

## Purpose
The sdlc-orchestrator is the master skill that guides users through the complete software development lifecycle. It maintains state across 7 sequential stages, invokes specialized skills at each stage, and tracks progress.

## How It Works

### 1. Initialization
When triggered, ask the user:
- **Project Name:** e.g., "UserManagement", "OrderProcessing"
- **Brief Description:** 1-2 sentences about what the project does
- **Key Stakeholders:** e.g., "Engineering team, Product team, C-level execs"
- **Timeline/Scope:** Rough estimate of complexity (Small/Medium/Large)

### 2. Present the Pipeline
Display the 7-stage pipeline with visual status indicators:

```
📋 SOFTWARE DEVELOPMENT LIFECYCLE PIPELINE
═══════════════════════════════════════════════════════════

[1] ✓ Product Design          (PRD + Discovery)                [PENDING]
    └─ Output: [ProjectName]-prd.md
    └─ Skill: product-design

[2] ✓ Architecture (arc42)    (System Design)                  [PENDING]
    └─ Output: [ProjectName]-arc42.md
    └─ Skill: arc42-doc

[3] ✓ Evaluation (ATAM)       (Architecture Trade-offs)        [PENDING]
    └─ Output: [ProjectName]-atam-assessment.md
    └─ Skill: atam-facilitator

[4] ✓ Architecture Review     (Quality & Gaps)                 [PENDING]
    └─ Output: [ProjectName]-arch-review.md
    └─ Skill: arch-review

[5] ✓ Functional Specs        (Feature Specifications)         [PENDING]
    └─ Output: [ProjectName]-functional-specs.md
    └─ Skill: functional-specs

[6] ✓ Technical Specs         (Code-Ready Specifications)      [PENDING]
    └─ Output: [ProjectName]-technical-specs.md
    └─ Skill: technical-specs

[7] ✓ Deployment Specs        (Cloud Infrastructure & CI/CD)   [PENDING]
    └─ Output: [ProjectName]-[cloud]-deployment-spec.md
    └─ Skill: deployment-specs

═══════════════════════════════════════════════════════════
```

### 3. Sequential Execution
After presenting the pipeline, ask the user:
- "Ready to begin with Stage 1: Product Design?" (Yes / Skip to [X] / Cancel)
- If Yes → Invoke `product-design` skill
- If Skip → Ask which stage to start with
- If Cancel → Exit orchestrator, save progress

### 4. Stage Completion and Tracking
After each skill completes:
- Mark stage as `[COMPLETED]` in the pipeline display
- Save the output reference (PRD, spec, etc.)
- Show the next stage
- Ask: "Continue to Stage [X]?" (Yes / Review Previous / Adjust / Exit)

### 5. Progress Context
Maintain a running context block showing:
```
📊 PROJECT PROGRESS
Project: UserManagement
Created: 2026-07-01
Completed Stages: 1/7

Documents Generated:
  ✓ usermanagement-prd.md
  ○ usermanagement-arc42.md
  ○ usermanagement-atam-assessment.md
  ○ usermanagement-arch-review.md
  ○ usermanagement-functional-specs.md
  ○ usermanagement-technical-specs.md
  ○ usermanagement-[cloud]-deployment-spec.md

Next: Architecture (arc42)
```

## Behavior Rules

### Flexibility
- Users can skip stages if they have existing documentation
- Users can revisit previous stages to regenerate outputs
- Users can exit and resume later (context preserved in conversation)

### Stage Details

#### Stage 1: Product Design
- **Purpose:** Define what to build (vision, personas, features, requirements)
- **Inputs:** Project concept, stakeholders, success criteria
- **Outputs:** Product Requirements Document (PRD)
- **Skill:** `product-design`
- **Time estimate guidance:** User supplies context of scope

#### Stage 2: Architecture (arc42)
- **Purpose:** Design the high-level solution architecture
- **Inputs:** Product requirements from Stage 1
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

#### Stage 6: Technical Specifications
- **Purpose:** Code-ready specifications (API contracts, data models, component designs)
- **Inputs:** Functional specs + architecture + reference standards
- **Outputs:** Technical specifications (React components, Golang services)
- **Skill:** `technical-specs`
- **Scope:** Generates specs per feature/component, references security-rules.md and clean-architecture.md

#### Stage 7: Deployment Specs
- **Purpose:** Generate cloud-specific deployment infrastructure, CI/CD pipelines, secrets management strategy, and rollback plans
- **Inputs:** Technical specs from Stage 6 (app type, ports, health endpoints, env vars)
- **Outputs:** Deployment specification(s) with Terraform HCL, native IaC (Bicep/CloudFormation), GitHub Actions workflows, Azure DevOps pipelines, and deployment checklists
- **Skill:** `deployment-specs`
- **Cloud targets:** Azure (Terraform + Bicep), AWS (Terraform + CloudFormation), DigitalOcean (Terraform only), or Multi-cloud
- **Note:** References cloud-standards.md for naming conventions, tagging, and secrets management patterns

## Exit Conditions

### Successful Completion
- User completes all 7 stages → Offer to export full project documentation bundle
- Display summary: "Project [X] development specifications complete. Ready for implementation and deployment."

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
**Dependencies:** product-design, functional-specs, technical-specs, deployment-specs skills + existing arc42-doc, arch-review, atam-facilitator
