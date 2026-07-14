# Security Validation Skill — OWASP Integration Guide

## Overview

The **security-validation** skill is now fully integrated into the SDLC Toolkit pipeline, providing OWASP Top 10 2024 validation at critical junctures throughout the development lifecycle.

## Integration Points

### 1. Technical Specifications (Stage 6)
**Location:** technical-specs/SKILL.md → Step 5.5 Security Checkpoint

**When:** After technical spec generation, before proceeding to next stages

**Quick Check Performed:**
- ✅ Authentication: Endpoints requiring auth have JWT/Bearer validation?
- ✅ Input Validation: All endpoints validate input (length, type, format)?
- ✅ Injection Prevention: Using parameterized queries (SQL)? Safe JSON handling (React)?
- ✅ Secrets: No hardcoded credentials, all via env vars?
- ✅ CORS: Specific origins whitelisted (not *)?
- ✅ Rate Limiting: Sensitive endpoints (auth, API) rate-limited?
- ✅ Error Handling: Errors don't expose internal details?
- ✅ Logging: Plan to log security events (no PII)?

**User Action:** If any items fail, user offered to invoke full security-validation skill

---

### 2. SDLC Orchestrator Pipeline
**Location:** sdlc-orchestrator/SKILL.md → Dependencies

**Recommendation:** Security-Validation is now CRITICAL path (not optional)

**Recommended Sequence:**
```
Stage 6: Technical Specs
        ↓
        → SECURITY VALIDATION (NEW)
        ↓
Stage 7: Test Strategy (includes security tests)
        ↓
Stage 8: Deployment Specs
```

**Full recommended flow:**
```
[1] Product Design
[2] Architecture (arc42)
[3] Evaluation (ATAM)
[4] Architecture Review
[5] Functional Specs
[6] Technical Specs
    └─ Step 5.5: Security Checkpoint
    └─ Option A: Invoke security-validation → DEEP OWASP REVIEW
[7] Test Strategy
    └─ Includes security test cases
    └─ OWASP vulnerability patterns
[8] Deployment Specs
    └─ Infrastructure security configuration
```

---

## Security Validation Workflow

### Invoke Point
After technical-specs approval, user asked:
> "Should I invoke `security-validation` skill for deep OWASP review before proceeding?"

### Input Artifacts
1. **technical-specs.md** — API design, architecture, data model
2. **functional-specs.md** — Feature requirements
3. **architecture.md** — System design decisions

### Validation Scope (10 OWASP Categories)

**A01: Broken Access Control**
- Role-based access control (RBAC) implementation
- Resource ownership verification
- API endpoint authorization checks

**A02: Cryptographic Failures**
- TLS 1.3 enforcement
- Secret management (no hardcoded credentials)
- Password hashing (bcrypt, not MD5/SHA)
- Encryption at rest strategy

**A03: Injection**
- SQL injection prevention (parameterized queries)
- Command injection prevention (no shell exec with user input)
- Code injection prevention (no eval/exec of user code)

**A04: Insecure Design**
- Threat modeling (STRIDE methodology)
- Security requirements documented
- Secure design patterns applied

**A05: Security Misconfiguration**
- Default credentials removed
- Error messages don't expose internals
- CORS properly configured
- Security headers set

**A06: Vulnerable & Outdated Components**
- Dependency audit (go mod audit, npm audit)
- No known CVEs in dependencies
- Component update strategy

**A07: Authentication Failures**
- JWT implementation (RS256, token expiration)
- Password policy (12+ chars, complexity)
- Session management (httpOnly cookies, SameSite)
- Rate limiting (login: max 5 attempts/5min)

**A08: Data Integrity Failures**
- Input validation (type, length, format, range)
- Output encoding (HTML escape, URL validation)
- Database constraints (NOT NULL, UNIQUE, CHECK, FK)

**A09: Logging & Monitoring Failures**
- Security event logging (auth, authz, data changes)
- No PII in logs (passwords, tokens, email)
- Audit trail maintained
- Alerting configured

**A10: SSRF (Server-Side Request Forgery)**
- URL validation (whitelist hosts, block private IPs)
- Protocol validation (http/https only)
- No fetch of internal resources

---

## Output Artifacts

### Main Report
**File:** `[project-name]-security-validation.md`

**Contains:**
- Executive summary (findings by severity)
- Detailed findings per OWASP category
- Risk assessment per finding
- Remediation guidance (code examples)
- Compliance mapping (GDPR, HIPAA, SOC2, PCI-DSS)
- Implementation roadmap (priorities and timeline)
- Re-validation schedule

### Supporting Checklists
**Language-Specific:**
- `golang-security-checklist.md` — Golang-specific validation
- `react-security-checklist.md` — React-specific validation

**Use in:**
- technical-specs generation
- implementation-scaffolding
- test-strategy (security test cases)

---

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| 🔴 **Critical** | Immediate exploitation risk | Fix before merge |
| 🟠 **High** | Likely exploitable | Fix before release |
| 🟡 **Medium** | Moderate risk | Fix in current sprint |
| 🔵 **Low** | Minor issue | Document for future fix |

---

## Integration with Other Skills

### With technical-specs
- Validates API contracts against OWASP
- Checks security requirements present
- Suggests security improvements to design

### With test-strategy
- Security test cases auto-generated from findings
- OWASP attack patterns included in test suite
- Compliance validation tests defined

### With implementation-scaffolding
- Security guidelines integrated in CLAUDE.md
- Protected paths defined (security-critical code)
- Development conventions include security patterns

### With harness-setup
- CLAUDE.md includes OWASP guardrails
- PreToolUse hook validates against known patterns
- PostToolUse hook runs security tests

### With deployment-specs
- Infrastructure security configuration (TLS, secrets management)
- Security groups/firewall rules
- Monitoring for security incidents
- Compliance checklist

---

## Quick Reference: OWASP Finding Categories

### By Risk Level (Quick Wins First)
```
PRIORITY 1 (Critical) — Fix immediately:
├─ A03: SQL Injection (parameterized queries)
├─ A07: Auth Failures (JWT, rate limiting)
├─ A02: Secrets hardcoded (move to env vars)
└─ A01: Missing authorization checks

PRIORITY 2 (High) — Fix this sprint:
├─ A05: CORS too permissive
├─ A08: No input validation
├─ A09: Insufficient logging
└─ A10: SSRF protection missing

PRIORITY 3 (Medium) — Fix next sprint:
├─ A04: No threat model
├─ A06: Outdated dependencies
└─ A02: Weak password policy
```

---

## Compliance Mapping

The skill maps findings to regulatory requirements:

| Regulation | Focus Areas | OWASP Categories |
|-----------|------------|------------------|
| **GDPR** | Encryption, access control, audit logs | A01, A02, A09 |
| **HIPAA** | Encryption, authentication, audit trail | A02, A07, A09 |
| **SOC2** | Access control, change management, logging | A01, A05, A09 |
| **PCI-DSS** | Encryption, access control, secrets | A02, A01, A07 |

---

## Usage Examples

### Example 1: Validating a REST API Spec

**Input:** technical-specs.md with API endpoints

**Security Validation Checks:**
```
POST /api/tasks
├─ A01: Authentication required? (JWT Bearer token?)
├─ A03: SQL injection protected? (Parameterized query?)
├─ A07: Rate limiting? (Prevent brute force?)
├─ A08: Input validation? (Title length, priority enum?)
├─ A05: Error messages safe? (Don't expose DB details?)
└─ A09: Audit logging? (Log who created task?)
```

**Output:** Findings + fixes for each category

---

### Example 2: Validating React Component

**Input:** React component accessing /api/user/profile

**Security Validation Checks:**
```
<UserProfile>
├─ A01: Authorization verified? (Check user.id vs. URL param?)
├─ A02: Sensitive data in localStorage? (JWT in httpOnly cookie?)
├─ A03: XSS prevention? (DOMPurify for HTML content?)
├─ A08: Input validation? (Form validation on save?)
└─ A09: Audit logging? (Log profile view server-side?)
```

**Output:** Findings + React-specific secure patterns

---

## Integration Checklist

### For Project Teams
- [ ] Run security-validation after technical-specs
- [ ] Remediate Critical findings before implementation
- [ ] Include security tests from OWASP patterns
- [ ] Document compliance status before deployment
- [ ] Schedule re-validation quarterly

### For Implementation
- [ ] Golang devs use golang-security-checklist.md
- [ ] React devs use react-security-checklist.md
- [ ] Follow secure code patterns from remediation
- [ ] Implement security test cases from findings
- [ ] Verify checks in harness PreToolUse hook

### For Deployment
- [ ] Infrastructure security hardening (TLS, secrets)
- [ ] Monitoring alerts configured for security events
- [ ] Compliance requirements verified
- [ ] Security incidents response plan documented

---

## Key Files

### Core Skill
- `skills/security-validation/SKILL.md` — Main skill definition

### Validation Templates
- `skills/security-validation/assets/owasp-validation-template.md` — Report template with all 10 categories
- `skills/security-validation/assets/golang-security-checklist.md` — Backend validation checklist
- `skills/security-validation/assets/react-security-checklist.md` — Frontend validation checklist

### Integrated References
- `skills/technical-specs/SKILL.md` — Step 5.5 Security Checkpoint
- `skills/sdlc-orchestrator/SKILL.md` — Updated pipeline + dependencies
- `references/security-rules.md` — Project security standards

---

## Next Steps

1. **Run security-validation after technical-specs**
   ```
   Invoke: security-validation skill
   Scope: Full application (Golang API + React frontend)
   Output: Remediation roadmap
   ```

2. **Implement Critical findings**
   - SQL injection prevention (parameterized queries)
   - JWT implementation with expiration
   - Input validation on all endpoints
   - Move hardcoded secrets to env vars

3. **Add security tests**
   - Run test-strategy skill (includes security test cases)
   - Implement OWASP attack patterns
   - Verify tests pass before merge

4. **Deploy with security hardening**
   - Run deployment-specs with security config
   - Enable TLS 1.3, security headers
   - Configure monitoring alerts

5. **Re-validate quarterly**
   - Update dependencies
   - Check for new CVEs
   - Verify compliance status

---

**Status:** ✅ Security-Validation skill integrated
**Next:** Invoke after technical-specs generation

For detailed workflow, see `skills/security-validation/SKILL.md`
