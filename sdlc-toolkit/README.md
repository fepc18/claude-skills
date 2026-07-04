# SDLC Toolkit Plugin

A comprehensive Software Development Lifecycle (SDLC) plugin for Claude that guides development projects from concept to code-ready specifications.

## Overview

The **sdlc-toolkit** plugin provides an orchestrated pipeline for developing software products, covering:

1. **Product Design** — PRD creation with personas, features, user stories
2. **Architecture Documentation** — arc42 system design documents
3. **Architecture Evaluation** — ATAM quality attribute trade-off analysis
4. **Architecture Review** — Gap identification and improvement recommendations
5. **Functional Specifications** — Feature specs with flows, acceptance criteria, wireframes
6. **Technical Specifications** — Code-ready specs (API contracts, component designs, database schemas)

## Features

### Skills Included

- **`sdlc-orchestrator`** — Master skill that guides you through the complete pipeline
- **`product-design`** — Creates comprehensive Product Requirements Documents
- **`functional-specs`** — Generates detailed feature specifications
- **`technical-specs`** — Produces code-ready technical designs

### Reused Skills

- **`arc42-doc`** — Architecture documentation (existing)
- **`arch-review`** — Architecture evaluation (existing)
- **`atam-facilitator`** — ATAM quality attribute workshop (existing plugin)

### Shared References

All skills reference these shared standards:
- **`security-rules.md`** — OWASP Top 10, JWT auth, input validation, secrets management
- **`clean-architecture.md`** — Layer separation, dependency injection, design patterns
- **`react-standards.md`** — TypeScript, hooks, Atomic Design, testing, accessibility
- **`golang-standards.md`** — Package structure, middleware, error handling, testing

## Quick Start

### Start a New Project

Say to Claude Code:
```
I want to build a user management system. Let's start the development process.
```

Or trigger the orchestrator directly:
```
sdlc
```

Claude will guide you through:
1. Gathering project context (name, description, stakeholders)
2. Presenting the 6-stage pipeline
3. Invoking skills sequentially (or letting you jump to any stage)
4. Tracking progress and saving outputs

### Individual Skills

You can also invoke skills independently:

**Product Design:**
```
Create a PRD for our e-commerce platform
```

**Functional Specifications:**
```
Generate functional specs for the user registration feature
```

**Technical Specifications:**
```
Design the technical specs for the payment processing microservice
```

## Documentation Structure

```
sdlc-toolkit/
├── README.md                      ← This file
├── .claude-plugin/
│   └── plugin.json
├── references/                    ← Shared by all skills
│   ├── security-rules.md         ← OWASP, auth, validation, logging
│   ├── clean-architecture.md     ← Design patterns, layer separation
│   ├── react-standards.md        ← Frontend best practices
│   └── golang-standards.md       ← Backend best practices
└── skills/
    ├── sdlc-orchestrator/         ← Master pipeline orchestration
    │   └── SKILL.md
    ├── product-design/            ← PRD creation
    │   ├── SKILL.md
    │   └── assets/
    │       └── prd-template.md
    ├── functional-specs/          ← Feature specifications
    │   ├── SKILL.md
    │   └── assets/
    │       └── feature-spec-template.md
    └── technical-specs/           ← Code-ready designs
        ├── SKILL.md
        └── assets/
            ├── react-component-spec.md
            └── golang-service-spec.md
```

## Usage Examples

### Example 1: Complete SDLC Pipeline

```
User: "Start a new project to build an online marketplace for handmade goods"

Claude:
1. Gathers context (problem, personas, timeline)
2. Generates [marketplace]-prd.md
3. Guides through arc42 architecture
4. Runs ATAM evaluation
5. Generates [marketplace]-functional-specs.md
6. Produces [marketplace]-technical-specs.md

Output: Complete project documentation ready for implementation
```

### Example 2: PRD Only

```
User: "Create a PRD for a real-time collaboration tool"

Claude:
- Product Design skill generates [tool]-prd.md
- Includes: vision, personas (3), features/epics, user stories, KPIs, constraints
```

### Example 3: Feature Spec from Existing PRD

```
User: "I have a PRD for a project management tool. Now detail the 'Kanban Board' feature"

Claude:
- Functional Specs skill generates [feature]-functional-spec.md
- Includes: flows, acceptance criteria (Gherkin), wireframes, business rules, API deps
```

### Example 4: Backend Technical Design

```
User: "Design the technical specs for a Go microservice that handles user authentication"

Claude:
- Technical Specs skill for Golang generates [service]-technical-spec.md
- Includes: package structure, OpenAPI contract, domain/app/infra design, middleware, testing
```

## Compliance & Standards

### Security
All technical specs enforce:
- JWT-based authentication
- Input validation at API boundary
- Parameterized SQL queries (no injection)
- Rate limiting on sensitive endpoints
- Error messages that don't leak system details
- No hardcoded secrets (env vars only)
- Structured logging without PII

### Clean Architecture
All designs follow:
- **Golang:** cmd/ → internal/(domain/application/infrastructure/interface) → pkg/
- **React:** components/(atoms/molecules/organisms/templates/pages) + hooks/ + services/
- Dependency rule: inner layers independent of outer layers
- Interfaces as contracts between layers

### React Standards
- TypeScript strict mode
- Functional components with hooks only
- React Query for server state, Zustand for client state
- Atomic Design methodology
- WCAG 2.1 AA accessibility
- Vitest + React Testing Library for testing

### Golang Standards
- Explicit error handling (no panic in production)
- Context propagation in all functions
- Middleware stack for logging, auth, recovery
- Repository pattern for data access
- Structured logging (zerolog)
- Table-driven tests

## Workflow & Integration

### How Skills Work Together

```
1. sdlc-orchestrator (user entry point)
   ↓
2. product-design → outputs [project]-prd.md
   ↓
3. arc42-doc → inputs PRD, outputs [project]-arc42.md
   ↓
4. atam-facilitator → inputs arc42, outputs [project]-atam.md
   ↓
5. arch-review → inputs arc42 + ATAM, outputs [project]-arch-review.md
   ↓
6. functional-specs → inputs PRD + arch, outputs [feature]-functional-spec.md
   ↓
7. technical-specs → inputs functional-spec + standards, outputs [feature]-technical-spec.md
```

### Flexibility

- **Sequential:** Follow the 6-stage pipeline in order
- **Jumping:** Skip to any stage (e.g., "skip to functional specs")
- **Independent:** Use any skill standalone (don't need orchestrator)
- **Iteration:** Return to earlier stages to refine outputs

## Output Location

All generated documents are saved to:
```
/sessions/[session-id]/mnt/outputs/
```

File naming convention:
```
[project-name]-prd.md
[project-name]-arc42.md
[feature-name]-functional-spec.md
[feature-name]-react-technical-spec.md
[feature-name]-golang-technical-spec.md
```

## Reference Materials

### For Users

- **security-rules.md:** Learn OWASP compliance, JWT auth, input validation rules
- **clean-architecture.md:** Understand layer separation, design patterns, anti-patterns
- **react-standards.md:** React component patterns, hooks, state management, testing
- **golang-standards.md:** Go microservice structure, middleware, database access, testing

### For Developers

All reference materials include:
- Binding rules (MUST follow)
- Code examples (patterns to use)
- Anti-patterns (to avoid)
- Checklists (pre-submission validation)

## Tips for Best Results

### PRD Creation
1. Be specific about the problem being solved
2. Define 2-3 realistic user personas
3. Prioritize features (P0/P1/P2)
4. Include success metrics (KPIs)
5. List constraints and dependencies early

### Functional Specifications
1. Start with a clear happy path (main success scenario)
2. Think about edge cases (errors, boundary conditions)
3. Write acceptance criteria in Gherkin format
4. Draw wireframes for any UI changes
5. Be explicit about business rules

### Technical Specifications
1. Reference the relevant standards (security, clean arch, tech-specific)
2. Provide OpenAPI contracts for all APIs
3. Show the complete package/component structure
4. Include database schemas and migrations
5. Define error handling and status codes

## Troubleshooting

### "Skill not found"
- Make sure the plugin is installed: `/plugin add sdlc-toolkit`
- Or use full trigger phrase: "Design of product" instead of "prd"

### "Missing context"
- Provide more details in your initial prompt
- Example: Instead of "Create a PRD", try "Create a PRD for a real-time messaging app that helps distributed teams communicate asynchronously"

### "Outputs not saved"
- Check that `/sessions/[session-id]/mnt/outputs/` directory exists
- Or manually copy-paste outputs from Claude

## Contributing & Customization

### Extend the Standards

Edit the reference files to add your own patterns:
- Add company-specific security rules
- Include architectural patterns you prefer
- Update tech stack recommendations

### Add New Skills

Create new skills following the template:
1. Create `skills/[skill-name]/SKILL.md`
2. Add triggers and description
3. Update orchestrator to include in pipeline

### Customize Templates

Modify asset templates to match your style:
- `prd-template.md` — Add sections you need
- `feature-spec-template.md` — Adjust detail level
- `react-component-spec.md` — Remove unneeded sections
- `golang-service-spec.md` — Add infrastructure patterns

## Support & Feedback

For issues or feedback:
- Report at: https://github.com/anthropics/claude-code/issues
- Include: skill name, trigger phrase, what went wrong
- Attach: example input and expected output

## Version History

### v1.0.0 (2026-07-01)
- Initial release
- 4 new skills (orchestrator, product-design, functional-specs, technical-specs)
- 4 reference standards (security, architecture, react, golang)
- Full templates and examples

## License

Provided as part of Claude Code. Use freely for your projects.

---

**Last Updated:** 2026-07-01
**Maintained by:** Felipe Pabón
**Status:** Stable
