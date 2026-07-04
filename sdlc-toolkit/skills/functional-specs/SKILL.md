---
name: functional-specs
description: Creates detailed functional specifications for individual features. Includes flow diagrams, acceptance criteria in Gherkin/BDD format, wireframes, and dependencies.
model_invoked: true
triggers:
  - specs funcionales
  - functional specs
  - especificación de feature
  - spec del feature
  - historias de usuario detalladas
  - criterios de aceptación
  - bdd
  - gherkin
  - feature specification
  - detailed specifications
  - user story details
---

# Functional Specs Skill

## Purpose
Generate detailed functional specifications for individual features. This skill takes a feature from the PRD and expands it into:
- End-to-end user flows (happy path + edge cases)
- Detailed acceptance criteria (BDD/Gherkin format)
- UI wireframes (ASCII diagrams)
- Business rules and constraints
- Inter-service dependencies

## Workflow

### 1. Feature Selection
Ask the user to specify which feature to document:
- "Which feature from the product roadmap would you like to detail?" (provide feature list if from prior PRD)
- Or: "What is the feature name/description?" (if starting fresh)

### 2. Gather Context
Ask clarifying questions:
- "What user personas use this feature?" (Ref: PRD personas)
- "What's the happy path?" (Best-case user flow, 5-7 steps)
- "What are edge cases?" (Error scenarios, boundary conditions)
- "What business rules apply?" (Validation, constraints, permissions)
- "What external systems does it integrate with?" (APIs, databases, services)

### 3. Specification Generation
Generate a comprehensive functional spec using the template at `assets/feature-spec-template.md`.

The spec includes:
1. **Overview** — feature name, purpose, user impact
2. **User Flow Diagrams** — PlantUML sequence diagrams (happy path + edge cases)
3. **User Stories** — detailed stories from the PRD for this feature
4. **Acceptance Criteria** — Gherkin format (Given/When/Then) or BDD checklist
5. **UI Wireframes** — ASCII art mockups showing screens and interactions
6. **Business Rules** — explicit logic and constraints
7. **Data Flow** — entities created/modified, relationships
8. **API/Service Dependencies** — external calls, integrations
9. **Performance Requirements** — load targets, latency expectations
10. **Security Considerations** — auth, data sensitivity, compliance

### 4. File Output
Generate filename: `[feature-name]-functional-spec.md`
Save to: `/sessions/[session-id]/mnt/outputs/`

### 5. Validation & Iteration
After generating the spec:
- Show a quick summary (overview + acceptance criteria)
- Ask: "Does this match your vision of the feature? Any adjustments?"
- Offer to refine specific sections (flow, wireframes, edge cases, etc.)

## Template Structure

The functional spec is organized for developer handoff:

```markdown
# Functional Specification: [Feature Name]

## 1. Overview
- Feature: [name]
- Status: [Draft / Review / Approved]
- Personas Impacted: [who uses this]
- Priority: [P0 / P1 / P2]

## 2. User Flow Diagrams

### Happy Path (Main Success Scenario)
[PlantUML sequence diagram showing actors, systems, interactions]

### Edge Cases & Error Scenarios
[Additional diagrams for: validation errors, network failures, permissions denied, etc.]

## 3. User Stories (from PRD)
[Repeat relevant user stories, each with acceptance criteria]

## 4. Acceptance Criteria (Gherkin / BDD)

### Scenario 1: [Happy Path]
```gherkin
Given [initial state]
When [user action]
Then [expected outcome]
And [additional assertion]
```

### Scenario 2: [Edge Case]
```gherkin
Given [initial state with edge condition]
When [user action]
Then [expected behavior]
And [error handling]
```

## 5. UI Wireframes

### Screen 1: [Screen Name]
[ASCII art mockup]

### Screen 2: [Screen Name]
[ASCII art mockup]

## 6. Business Rules & Constraints

- **Rule 1:** [Explicit logic, e.g., "Only admins can delete users"]
- **Rule 2:** [Validation, e.g., "Email must be unique per organization"]
- **Rule 3:** [Permissions, e.g., "User can only edit own profile"]

## 7. Data Model & Relationships

[Entity diagrams, field requirements, relationships]

## 8. API/Service Dependencies

[External calls, microservices involved, integration points]

## 9. Performance Requirements

[Load targets, latency SLAs, throughput expectations]

## 10. Security & Compliance

[Auth requirements, data sensitivity, regulatory constraints]
```

## Detailed Guidelines

### User Flow Diagrams (PlantUML)

**Happy Path Example (User Registration):**
```
@startuml
participant User
participant Frontend
participant Backend
participant EmailService

User -> Frontend: Click "Sign Up"
Frontend -> User: Show registration form
User -> Frontend: Fill form + click "Register"
Frontend -> Backend: POST /auth/register (email, password, name)
note over Backend: Validate input, hash password
Backend -> Backend: Check if email exists
alt Email already exists
  Backend -> Frontend: 409 Conflict
  Frontend -> User: "Email already registered"
else
  Backend -> Backend: Create user record
  Backend -> EmailService: Send verification email
  EmailService -> User: Email with verification link
  Backend -> Frontend: 201 Created
  Frontend -> User: "Check your email to verify"
end
@enduml
```

**Edge Case Example (Payment Failure):**
```
@startuml
participant User
participant Frontend
participant Backend
participant PaymentProvider

User -> Frontend: Click "Complete Purchase"
Frontend -> Backend: POST /checkout (amount, card_token)
Backend -> PaymentProvider: Charge card
PaymentProvider -> Backend: Payment declined
Backend -> Frontend: 402 Payment Required
Frontend -> User: "Payment failed. Try another card."
User -> Frontend: Click "Retry"
Frontend -> Backend: POST /checkout (amount, new_token)
...
@enduml
```

### Gherkin / BDD Scenarios

**Example: Login Feature**

```gherkin
Feature: User Authentication

  Scenario: Successful login with valid credentials
    Given I am on the login page
    And my account exists with email "user@example.com" and password "SecurePass123"
    When I enter email "user@example.com"
    And I enter password "SecurePass123"
    And I click "Sign In"
    Then I should see the dashboard
    And my session should be valid

  Scenario: Login with incorrect password
    Given I am on the login page
    And my account exists with email "user@example.com"
    When I enter email "user@example.com"
    And I enter password "WrongPassword"
    And I click "Sign In"
    Then I should see error message "Invalid email or password"
    And I should NOT be logged in

  Scenario: Login attempt is rate-limited after 5 failures
    Given I am on the login page
    And I have failed to login 5 times in the last 2 minutes
    When I attempt to login again
    Then I should see error message "Too many login attempts. Try again in 5 minutes."
    And the login button should be disabled for 5 minutes

  Scenario: Login with 2FA enabled
    Given I am on the login page
    And my account has 2FA enabled
    When I enter valid email and password
    Then I should see the "Enter 2FA Code" screen
    And I should receive a code via SMS
    When I enter the 2FA code
    Then I should see the dashboard
```

### UI Wireframes (ASCII Art)

**Example: User Profile Edit Screen**

```
┌─────────────────────────────────────────────────────┐
│  MyApp  👤 Account  ☰ Menu                           │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Edit Profile                                        │
│  ═══════════════════════════════════════════════    │
│                                                      │
│  [Avatar: Click to upload]                          │
│                                                      │
│  Full Name: [__________________________] *required  │
│                                                      │
│  Email: [user@example.com]                          │
│  (Cannot edit - contact support to change)          │
│                                                      │
│  Phone: [+1 (555) 123-4567]  [Optional]             │
│                                                      │
│  Bio: [_________________________________]           │
│        [_________________________________]           │
│        [Markdown supported - preview ▼] (100 chars) │
│                                                      │
│  Timezone: [America/New_York] ▼                     │
│                                                      │
│  ☑ Subscribe to product updates                     │
│  ☑ Allow team members to see my status              │
│                                                      │
│  ┌─────────────────────────────────────────────┐   │
│  │ [Cancel] [Save Changes] [Delete Account]     │   │
│  └─────────────────────────────────────────────┘   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Business Rules Example

```markdown
## Business Rules

1. **User Creation Rules**
   - Email must be unique per workspace
   - Username must contain 3-20 alphanumeric characters
   - Password must be ≥ 12 characters with uppercase, lowercase, number, symbol
   - New users start with "viewer" role (can be upgraded by admin)

2. **Workspace Permissions**
   - Only "admin" role can invite users
   - "editor" role can modify content but not settings
   - "viewer" role is read-only
   - Minimum 1 admin per workspace must remain

3. **Data Retention**
   - Deleted user data retained for 30 days before permanent deletion
   - User can request data export anytime
   - Workspace can only be deleted if no active projects

4. **API Rate Limits**
   - Per-user limit: 1000 requests per hour
   - Anonymous API: 100 requests per hour
   - Burst limit: 50 requests per minute (reset after 1 minute)
```

## Interaction Examples

### Example 1: E-commerce Checkout
**Feature:** "Complete Purchase with Multiple Payment Methods"

**User Asks:** "I need detailed specs for our checkout flow"

**Functional Spec Includes:**
- Happy path: Select items → Enter shipping → Choose payment → Confirm → Success
- Edge cases: Insufficient stock, payment decline, promo code validation, address validation
- Gherkin scenarios: Successful purchase, invalid card, expired promo, shipping to unsupported country
- Wireframes: Shopping cart, shipping form, payment method selection, order confirmation
- Business rules: Promo code limits, free shipping thresholds, tax calculation by region
- API dependencies: Payment processor (Stripe), shipping (FedEx), tax service (TaxJar)

### Example 2: Real-Time Collaboration
**Feature:** "Live Cursor & Presence Indicators"

**Functional Spec Includes:**
- Happy path: User A joins document → User B joins → Both see each other's cursors → Real-time updates
- Edge cases: Network disconnect, user leaves, document deleted while editing
- Gherkin: User joins collaborative document, sees active users, sees cursor movement
- Wireframes: Document with presence sidebar, cursor labels with user names
- Business rules: Only document collaborators see presence, cursors disappear 30 seconds after user leaves
- API dependencies: WebSocket for real-time updates, presence service for user state

## Quality Checklist

Before returning the spec to the user:

- ✅ Feature name and purpose are clear
- ✅ User flow diagrams show happy path + at least 2 edge cases
- ✅ All acceptance criteria are in Gherkin format (Given/When/Then)
- ✅ Gherkin scenarios are testable and specific (not vague)
- ✅ UI wireframes are included for all screens (ASCII or description)
- ✅ Business rules are explicit (no hidden assumptions)
- ✅ Performance requirements are measurable (latency, load)
- ✅ Security considerations are addressed (auth, data sensitivity)
- ✅ External dependencies are clearly listed (APIs, services, databases)
- ✅ Data model is documented (entities, fields, relationships)

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 5), can be used independently
**Feeds into:** technical-specs (technical design uses functional specs as input)
**References:** PRD (for personas, priorities), security-rules.md (for auth, validation)

**Output location:** `/sessions/[session-id]/mnt/outputs/[feature-name]-functional-spec.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with embedded Gherkin and PlantUML
