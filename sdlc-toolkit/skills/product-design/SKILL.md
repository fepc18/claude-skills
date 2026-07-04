---
name: product-design
description: Creates comprehensive Product Requirements Documents (PRD) including vision, personas, features, epics, user stories, and success criteria.
model_invoked: true
triggers:
  - diseño de producto
  - prd
  - product requirements document
  - documento de producto
  - discovery
  - definir el producto
  - vision del producto
  - product design
  - requirements document
  - product vision
  - feature planning
---

# Product Design Skill

## Purpose
Generate a comprehensive Product Requirements Document (PRD) that captures:
- Product vision and value proposition
- Target user personas
- Feature epics and roadmap
- User stories with acceptance criteria
- Success metrics and KPIs
- Constraints and dependencies

## Workflow

### 1. Gathering Information
Ask the user a series of questions to collect product context:

**Core Product Definition:**
- "What problem does your product solve?" (vision statement)
- "Who are the primary users?" (personas or user segments)
- "What are the 3-5 core features?" (high-level feature list)

**Business Context:**
- "What are your key success metrics/KPIs?" (measurable goals)
- "What's the time horizon?" (MVP in 3 months, full product in 1 year, etc.)
- "Are there technical or regulatory constraints?" (GDPR, healthcare, payment, etc.)

**User Context:**
- "Who are the key stakeholders?" (product, engineering, business)
- "What's the current state?" (greenfield, migration, enhancement)
- "Any known competitors or market context?" (optional)

### 2. PRD Generation
Once information is gathered, generate a comprehensive PRD using the template at `assets/prd-template.md`.

The PRD includes:
1. **Executive Summary** — one-paragraph vision statement
2. **Problem Statement** — what problem are we solving
3. **Value Proposition** — why customers should use this
4. **Success Criteria** — measurable KPIs (retention, conversion, engagement, etc.)
5. **User Personas** — 2-3 detailed persona profiles with goals and pain points
6. **Features & Epics** — organized feature list with epics, features, and stories
7. **User Stories** — detailed stories in "As [role], I want [action], so that [benefit]" format
8. **Acceptance Criteria** — testable criteria per story (in Given/When/Then or checklist format)
9. **Constraints & Dependencies** — technical limits, third-party integrations, regulatory requirements
10. **Out of Scope** — explicitly list what's NOT included (prevents scope creep)

### 3. File Output
Generate filename: `[project-name]-prd.md` (derived from user input)
Save to: `/sessions/[session-id]/mnt/outputs/`

### 4. Validation
After generating the PRD:
- Show the table of contents
- Ask: "Does this capture your product vision? Any adjustments needed?"
- Offer to refine specific sections (personas, epics, success criteria, etc.)

## Template Structure

The PRD is organized for both readability and handoff:

```markdown
# Product Requirements Document: [Project Name]

## 1. Executive Summary
[1-paragraph vision statement]

## 2. Problem Statement
- Current situation
- Pain points
- Why it matters

## 3. Value Proposition
- What makes us different
- Customer benefits
- Competitive advantage

## 4. Success Criteria (KPIs)
- User adoption rate
- Feature usage
- Customer retention
- Revenue/conversion (if applicable)

## 5. User Personas
### Persona 1: [Name]
- Background
- Goals
- Pain points
- Usage patterns

### Persona 2: [Name]
[Similar structure]

## 6. Feature Roadmap

### Epic 1: [Epic Name]
Description: ...

**Feature 1.1: [Feature]**
- Description: ...
- User impact: ...
- Priority: P0/P1/P2

**Feature 1.2: [Feature]**
[Similar structure]

### Epic 2: [Epic Name]
[Similar structure]

## 7. Detailed User Stories

### Epic 1: [Epic Name]

#### User Story 1.1
**As a** [role]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] User can...
- [ ] System validates...
- [ ] [Additional criteria...]

#### User Story 1.2
[Similar structure]

### Epic 2: [Epic Name]
[Similar structure]

## 8. Constraints & Dependencies
- Technical constraints
- Third-party integrations
- Regulatory/compliance requirements
- Resource limitations

## 9. Out of Scope
- Features explicitly NOT included in MVP/Phase 1
- Prevents scope creep

## 10. Timeline & Phases
- MVP: [Features] by [Date]
- Phase 2: [Features] by [Date]
- Phase 3: [Features] by [Date]
```

## Interaction Examples

### Example 1: E-commerce Product
**User Input:** "I want to build an online marketplace for handmade goods"

**Orchestrator Gathers:**
- Problem: Artisans struggle to reach customers; buyers want verified handmade goods
- Personas: Artisans (sellers), Collectors (buyers), Admin (marketplace operations)
- Core features: Product listing, buyer discovery, secure payment, seller ratings
- Success metrics: GMV, seller/buyer retention, transaction volume

**PRD Output:** Complete marketplace PRD with:
- Seller onboarding epic
- Product discovery epic
- Payment & checkout epic
- User stories with acceptance criteria for each feature

### Example 2: SaaS Analytics Tool
**User Input:** "Dashboard for real-time analytics of software team productivity"

**PRD Generated:**
- Executive summary about improving engineering visibility
- Personas: Engineering manager, CTO, HR partner
- Epics: Metrics ingestion, Dashboard visualization, Alerting, Integrations
- Success criteria: User adoption, feature usage, customer NPS

## Quality Checklist

Before returning the PRD to the user:

- ✅ Vision statement is clear and compelling (1-2 sentences)
- ✅ Personas have distinct goals and pain points (not generic)
- ✅ Features are prioritized (P0 MVP features clearly marked)
- ✅ User stories follow "As [role], I want..., so that..." format
- ✅ Acceptance criteria are testable and specific (not vague)
- ✅ Constraints and dependencies are realistic
- ✅ Success criteria are measurable (KPIs with targets)
- ✅ Out of scope section prevents scope creep
- ✅ Features map clearly to personas and use cases

## Refinement Workflow

If the user asks for adjustments:
- "Let's refine [section name]. What would you like to change?"
- Edit the relevant section and re-display updated PRD
- Ask: "Better? Any other adjustments?"
- Offer to move to next skill (arc42-doc for architecture)

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 1)
**Feeds into:** arc42-doc (architecture design uses PRD as input)
**References:** None (PRD is input to downstream specs)

**Output location:** `/sessions/[session-id]/mnt/outputs/[project-name]-prd.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md)
