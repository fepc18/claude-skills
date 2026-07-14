---
name: security-validation
description: Valida especificaciones, código y configuraciones contra OWASP Top 10 y mejores prácticas de seguridad. Genera reportes de vulnerabilidades, sugerencias de fixes, y compliance checklist. Integrable en cualquier etapa del SDLC.
model_invoked: true
triggers:
  - security validation / validación de seguridad
  - owasp / owasp top 10 / owasp checklist
  - security audit / auditoría de seguridad
  - vulnerability assessment / evaluación de vulnerabilidades
  - security review / revisión de seguridad
  - penetration testing / pruebas de penetración
  - secure code review / revisión segura de código
  - security hardening / endurecimiento de seguridad
  - threat modeling / modelado de amenazas
  - security compliance / cumplimiento de seguridad
---

# Security Validation Skill

## Purpose

Validates applications, specifications, and infrastructure configurations against OWASP Top 10, CWE/SANS Top 25, and industry security best practices. Provides actionable findings, remediation guidance, and compliance reporting.

## Critical References

- `../../references/security-rules.md` — Project security standards
- OWASP Top 10 2024 — Current vulnerability categories
- CWE/SANS Top 25 — Most dangerous software weaknesses
- NIST Cybersecurity Framework — Security controls

---

## Workflow (7 Steps)

### Step 1: Scope & Asset Identification
"What would you like to validate?"
- A) Specification document (technical-specs.md, functional-specs.md)
- B) Codebase (Golang backend / React frontend / Full-stack)
- C) Infrastructure configuration (Terraform, deployment-specs.md)
- D) API design (OpenAPI contract)
- E) All of the above

**Output:** Scope statement and assets to review

---

### Step 2: Technology & Compliance Context
"Tell me about your project:"
- Primary language/framework (Go, React, Python, etc.)
- Data sensitivity (public, internal, PII, financial, health)
- Compliance requirements (GDPR, HIPAA, SOC2, PCI-DSS, none)
- Threat model (low-risk MVP, medium-risk SaaS, high-risk fintech)

**Output:** Custom validation profile

---

### Step 3: OWASP Top 10 Validation
Analyze each of 10 risk categories:

1. **Broken Access Control** — Role-based access, authorization checks
2. **Cryptographic Failures** — Encryption, secrets management, TLS
3. **Injection** — SQL injection, command injection, code injection prevention
4. **Insecure Design** — Threat modeling, secure design patterns
5. **Security Misconfiguration** — Default credentials, verbose errors, CORS
6. **Vulnerable & Outdated Components** — Dependency scanning, updates
7. **Authentication Failures** — Password policies, MFA, session management
8. **Data Integrity Failures** — Input validation, data sanitization
9. **Logging & Monitoring Failures** — Audit trails, intrusion detection
10. **SSRF** — Server-side request forgery prevention

**Output:** Detailed findings per category (Critical/High/Medium/Low)

---

### Step 4: Generate Report
Structure:
- **Executive Summary** (finding count by severity)
- **Detailed Findings** (per OWASP category)
  - Vulnerability description
  - Risk level (Critical/High/Medium/Low)
  - Affected code/config
  - Proof of concept (if applicable)
  - Remediation recommendation
- **Compliance Checklist** (based on regulations)
- **Quick Wins** (easy fixes to implement first)

**Output:** Markdown report + actionable checklist

---

### Step 5: Remediation Guidance
For each critical/high finding:
- Secure code pattern (before/after)
- Dependency update (if applicable)
- Configuration hardening
- Testing verification

**Output:** Implementation-ready fixes

---

### Step 6: Continuous Security
Offer integration:
- A) Add security tests to test-strategy
- B) Add security checklist to harness-setup
- C) Configure CI/CD security scanning
- D) Schedule periodic re-validation

---

### Step 7: Technical Debt Management (NEW)

After findings are documented, offer:

**"How would you like to manage these findings?"**

#### Option A: Implement Fixes Now
- User: "Implementa los fixes ahora"
- Claude: Provides implementation support
  - Code review: what needs to change
  - Step-by-step implementation guide
  - Test verification for each fix
  - Deployment checklist
- Supports iterative implementation (one fix at a time or all at once)
- Direct code changes in project repository

#### Option B: Register as Technical Debt
- User: "Registra como deuda técnica"
- Claude: Creates structured technical debt tracking system
- **Output Structure:**
  ```
  project-root/technical-debt/
  ├── README.md                      (overview and progress tracking)
  ├── SECURITY_DEBT_TRACKER.md       (all findings organized by priority)
  ├── PRIORITY_1_FIXES.md            (critical fixes with code examples)
  ├── PRIORITY_2_IMPROVEMENTS.md     (high-priority improvements)
  └── PRIORITY_3_ENHANCEMENTS.md     (backlog items)
  ```
- **Contents per Priority Document:**
  - Finding ID and OWASP category
  - Severity level and effort estimate
  - Complete code examples (before/after)
  - Unit test patterns
  - Database migrations (if applicable)
  - Implementation verification steps
  - Testing checklist
- **Tracking Features:**
  - Risk assessment summary
  - Deployment readiness status
  - Milestone timeline with estimated hours
  - Progress tracking table (owner, status, % complete)
  - Implementation workflow (step-by-step)
  - Jira/GitHub issue templates

#### Option C: Hybrid Approach
- User: "Implementa P1 ahora, registra P2 y P3 como deuda"
- Claude:
  1. Implements Priority 1 fixes immediately
  2. Creates technical debt folder for P2 and P3
  3. Provides deployment checklist for P1 only
  4. Creates backlog items for P2/P3

#### Option D: No Action (Just Report)
- User: "Solo documenta, no implementes"
- Claude: Keeps findings in OWASP validation report only
- Team can reference findings later

**Output:** Structured technical debt files + tracking infrastructure

---

## Template Structure

### `owasp-validation-template.md`

**Sections:**
1. Validation Scope & Profile
2. Executive Summary
3. OWASP Top 10 Findings (per category)
4. CWE/SANS Top 25 Cross-reference
5. Compliance Status (GDPR/HIPAA/SOC2/PCI-DSS)
6. Quick Wins (prioritized fixes)
7. Implementation Roadmap
8. Re-validation Schedule

### `golang-security-checklist.md`

**Coverage:**
- Input validation & sanitization
- SQL injection prevention (sqlc, parameterized queries)
- Authentication (JWT, session management)
- Authorization (role-based access control)
- Encryption (TLS 1.3, key management)
- Secrets management (environment variables, vaults)
- Error handling (no sensitive data in errors)
- Logging (zero PII)
- Dependency security (go mod audit)
- OWASP-specific patterns

### `react-security-checklist.md`

**Coverage:**
- XSS prevention (DOMPurify, sanitization)
- CSRF protection (token validation)
- Input validation & sanitization
- Secure storage (localStorage vs sessionStorage)
- API security (Bearer tokens, CORS validation)
- Component security (props validation)
- Dependency security (npm audit)
- Error boundary implementation
- Secure defaults (CSP headers)
- OWASP-specific patterns

---

## Quality Checklist (Internal)

- ✅ All 10 OWASP categories analyzed
- ✅ CWE cross-referenced
- ✅ Risk levels assigned (CVSS scoring if applicable)
- ✅ Proof of concept provided for critical findings
- ✅ Remediation is specific and actionable
- ✅ Secure code patterns included (not just "don't do this")
- ✅ Dependency versions checked
- ✅ Compliance requirements addressed
- ✅ Testing verification steps included
- ✅ False positives eliminated (context-aware review)

---

## Interaction Examples

### Example 1: Validating Technical Specs

**User:** "Valida la spec técnica en 04-technical-specs.md contra OWASP"

**Claude Response:**
```
Analizando 04-technical-specs.md contra OWASP Top 10...

FINDINGS RESUMEN:
- Critical (1): Missing rate limiting on auth endpoints
- High (3): No input validation specs, secrets handling unclear
- Medium (5): CORS policy too permissive, error messages expose internals
- Low (2): Logging doesn't specify PII exclusion

Quick Wins to fix immediately:
1. Add rate limiting config to API spec
2. Define input validation rules per endpoint
3. Tighten CORS policy
```

### Example 2: Code Review

**User:** "Revisa el código Golang en backend/internal/interface/http/handler.go"

**Claude Response:**
```
Analizando handler.go...

FINDINGS:
✅ PASS: JWT auth implemented correctly
⚠️  MEDIUM: SQL queries use parameterized statements (good)
❌ HIGH: Error response exposes internal structure
❌ CRITICAL: No rate limiting on login endpoint
✅ PASS: Input validation present
```

### Example 3: Infrastructure Validation

**User:** "Valida la configuración de Terraform en deployment-specs.md"

**Claude Response:**
```
OWASP A05:2021 – Security Misconfiguration:

FINDINGS:
❌ CRITICAL: Database password in git history (check .gitignore)
❌ HIGH: TLS version not specified (should enforce 1.3)
✅ PASS: Encryption at rest enabled
⚠️  MEDIUM: Default CORS allowed all origins
```

---

## Refinement Workflow

1. **Initial Review** → Identify findings
2. **Deep Dive** (optional) → User asks "explain finding #3 with POC"
3. **Remediation Plan** → Generate step-by-step fixes
4. **Implementation Support** → Help implement fixes
5. **Re-validation** → Verify fixes worked

---

## Dependencies & Context

**Depends on:**
- technical-specs (API design validation)
- implementation-scaffolding (code structure validation)
- test-strategy (security test patterns)
- deployment-specs (infrastructure validation)

**Used by:**
- harness-setup (secure development guidelines)
- sdlc-orchestrator (security checkpoint in pipeline)
- CI/CD pipelines (automated security scanning)

**Related:**
- OWASP ASVS (Application Security Verification Standard)
- NIST SP 800-53 (Security Controls)
- CWE/SANS Top 25 (Dangerous weaknesses)

---

## Output Location

### Primary Output (Always Generated)
```
/sessions/[session-id]/mnt/outputs/
  ├── [project-name]-security-validation.md (main report)
  ├── [project-name]-owasp-findings.md (detailed)
  └── [project-name]-remediation-plan.md (implementation)
```

### Optional Output (If User Chooses Option B/C: Technical Debt)
```
project-root/technical-debt/
  ├── README.md                      (overview + progress tracking)
  ├── SECURITY_DEBT_TRACKER.md       (13 findings by priority + milestones)
  ├── PRIORITY_1_FIXES.md            (critical: code examples + tests, 13h)
  ├── PRIORITY_2_IMPROVEMENTS.md     (high: implementation guide + configs, 7h)
  └── PRIORITY_3_ENHANCEMENTS.md     (medium/low: backlog items, 6h)
```

### Git Changes (If User Chooses Option A: Implement Now)
- Direct commits to backend/ and frontend/ directories
- Database migrations applied
- Code changes with comprehensive test coverage
- CI/CD pipeline updated if needed

---

## Security Validation Checklist

**Before Report Generation:**
- [ ] Scope clearly defined
- [ ] All 10 OWASP categories reviewed
- [ ] False positives eliminated
- [ ] Severity levels assigned consistently
- [ ] Remediation is specific + actionable
- [ ] Code patterns follow OWASP guidelines
- [ ] Compliance requirements mapped
- [ ] Zero false positives

**Report Quality:**
- [ ] Executive summary is clear
- [ ] Findings are prioritized
- [ ] Each finding has: description, risk, fix, test verification
- [ ] Secure patterns included (code examples)
- [ ] Implementation roadmap provided
- [ ] Compliance status clear

**Technical Debt Output (If Option B/C Selected):**
- [ ] technical-debt/ folder created
- [ ] README.md contains overview and progress tracking
- [ ] SECURITY_DEBT_TRACKER.md organizes all findings by priority (P1/P2/P3)
- [ ] PRIORITY_1_FIXES.md includes complete code examples + tests
- [ ] PRIORITY_2_IMPROVEMENTS.md includes implementation guide + configs
- [ ] PRIORITY_3_ENHANCEMENTS.md includes backlog items
- [ ] Effort estimates provided per task
- [ ] Risk assessment and deployment readiness stated
- [ ] Milestones defined with timelines
- [ ] Progress tracking table included
- [ ] Jira/GitHub issue templates provided

---

**End of Security Validation Skill**
