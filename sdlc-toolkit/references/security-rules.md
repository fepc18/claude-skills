# Security Rules and Standards

Security is a shared responsibility across all layers. This document establishes binding rules for all features, specs, and technical designs in the sdlc-toolkit.

## OWASP Top 10 Compliance

### 1. Broken Authentication
**Rule:** All authentication must use JWT with signed claims. No session cookies in microservices.
- **React:** OAuth2 / OpenID Connect for third-party auth. Store JWT in `httpOnly` cookies or secure memory.
- **Golang:** JWT validation middleware. Claims extraction must validate `iss`, `aud`, `exp`, `iat`.
- **Violation example:** Storing auth tokens in localStorage → vulnerable to XSS.
- **Requirement:** Token rotation every 15 minutes. Refresh token expiry: 7 days.

### 2. Broken Access Control
**Rule:** Implement Role-Based Access Control (RBAC) with explicit permission checks at domain layer.
- **React:** Every action must check user permissions before API call. Double-check on backend.
- **Golang:** Use context to propagate user claims. Domain service methods must enforce permissions.
- **Violation example:** Assuming frontend validation is enough.
- **Requirement:** Deny by default. Grant specific permissions explicitly.

### 3. Injection (SQL, NoSQL, Command)
**Rule:** Never concatenate user input into queries. Always use parameterized queries.
- **Golang:** Use `sqlx` with named parameters or ORM with prepared statements. NEVER use string concatenation.
  ```go
  // Good
  db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", userID)

  // BAD - SQL Injection
  db.QueryRowContext(ctx, fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID))
  ```
- **React:** Sanitize all user input before display. Use DOMPurify for HTML content.
- **Requirement:** Input validation must happen at API boundary (backend). Frontend validation is UX only.

### 4. Insecure Design
**Rule:** Define threat model and security architecture before implementation.
- Every feature spec must include threat analysis.
- Identify: authentication gates, sensitive data flows, external integrations.
- **Golang:** Design error handling to not expose internals. Log errors, return generic messages.
- **React:** Never expose API keys or secrets in frontend code.

### 5. Security Misconfiguration
**Rule:** No hardcoded secrets. All configuration via environment variables or vault.
- **Golang:** Use env vars for DB URL, API keys, service endpoints. Never commit `.env`.
- **React:** Build-time env vars via `VITE_*` (Vite) or `REACT_APP_*` (CRA). Public URLs only.
- **Requirement:** Secrets rotation policy. Audit trail for secrets access.

### 6. Vulnerable and Outdated Components
**Rule:** Regular dependency scanning. Proactive patching.
- **Golang:** Run `go mod tidy && go list -u -m all` monthly. Use Dependabot on CI/CD.
- **React:** `npm audit` in CI/CD. Update major versions quarterly after testing.
- **Requirement:** Lock file committed. No version ranges (e.g., `^1.2.3`).

### 7. Identification and Authentication Failures
**Rule:** Implement multi-factor authentication (MFA) for sensitive operations.
- **Rate limiting:** Max 5 login attempts per minute per IP. Exponential backoff.
- **Golang:** Use `time.Sleep` with exponential backoff. Log all auth failures.
- **React:** Show generic error message "Invalid credentials" regardless of reason (no user enumeration).

### 8. Software and Data Integrity Failures
**Rule:** Sign all data transfers. Verify signatures on receipt.
- **TLS/HTTPS:** Mandatory for all communication. Certificate pinning for sensitive APIs.
- **Golang:** Use `crypto/hmac` for data signing. Verify before processing.
- **React:** No code injection from external sources. CSP headers required.

### 9. Logging and Monitoring Failures
**Rule:** All security events must be logged. Zero PII in logs.
- **Golang:** Use structured logging (zerolog). Include: timestamp, user_id, action, result, IP.
  ```json
  {"level":"warn","msg":"failed_auth","user_id":"user123","ip":"192.168.1.1","ts":"2026-07-01T10:00:00Z"}
  ```
- **React:** Client-side error logging to observability platform. No sensitive data in error messages.
- **Requirement:** Logs retained for 90 days. Alerting on suspicious patterns.

### 10. Server-Side Request Forgery (SSRF)
**Rule:** Validate all URLs before making requests. Whitelist trusted hosts.
- **Golang:** Use `net.url.Parse` and validate scheme (http/https only). Block private IPs.
  ```go
  u, _ := url.Parse(userProvidedURL)
  if !isAllowedHost(u.Host) {
    return fmt.Errorf("host not allowed")
  }
  ```
- **React:** Proxy all external API calls through backend to control allowed hosts.

## Authentication: JWT Implementation

### Token Structure
```
Header: {"alg":"HS256","typ":"JWT"}
Payload: {
  "sub":"user-id",
  "iss":"https://auth.example.com",
  "aud":"api.example.com",
  "exp":1719833880,
  "iat":1719833580,
  "roles":["admin","user"]
}
```

### Validation Checklist (Golang)
- [ ] Signature valid with public key
- [ ] `exp` in future (not expired)
- [ ] `iat` in past (not issued in future)
- [ ] `iss` matches expected issuer
- [ ] `aud` contains API audience
- [ ] Claim-based role check (not in token blacklist)

### Token Rotation
- **Access token:** 15 minutes expiry
- **Refresh token:** 7 days expiry
- **Blacklist on logout:** Store revoked token IDs in Redis with expiry = token.exp
- **Golang:** Check blacklist in middleware before processing claims

### Secrets Management
- **Shared secret key:** ≥ 256 bits, rotate quarterly
- **Public/Private key pair (RS256):** Private key in vault only. Public key in code.
- **Golang:** Load from env `JWT_SECRET` or vault. Never log token content.
- **React:** Access token in `httpOnly` cookie (not accessible to JS). Refresh token with `Secure` flag.

## Input Validation

### React (Frontend)
- **Immediate validation:** Real-time as user types. Show feedback.
- **Pre-submission validation:** Prevent API calls if invalid.
- **Validation rules:**
  - Email: RFC 5322 regex or `HTML5 <input type="email">`
  - URL: `new URL(input)` then validate protocol
  - Phone: Country-specific format
  - Text: Length limits, alphanumeric/allowed chars only
  - Numbers: Type coercion to number, min/max bounds

```jsx
// Example: Email validation
const isValidEmail = (email) => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};
```

### Golang (Backend)
- **Canonical validation:** All validation happens here. Frontend validation is UX only.
- **Struct validation:** Use `encoding/json` with struct tags, validate after unmarshal.

```go
type CreateUserRequest struct {
  Email string `json:"email" validate:"required,email"`
  Age   int    `json:"age" validate:"required,min=18,max=120"`
}

// Use validator.v10 library
v := validator.New()
if err := v.Struct(req); err != nil {
  // Return 400 Bad Request with validation errors
}
```

- **Custom validators:** Implement for business logic (e.g., username not reserved).
- **Error response:** Return 400 with `{"field":"email","error":"invalid format"}` (not detailed internals).

## Secrets and Environment Variables

### Golang (.env or vault)
```
JWT_SECRET=your-256-bit-secret-key
DATABASE_URL=postgresql://user:pass@localhost/db
REDIS_URL=redis://localhost:6379
EXTERNAL_API_KEY=***
LOG_LEVEL=info
CORS_ORIGIN=https://frontend.example.com
```

### React (Build-time only)
```
VITE_API_URL=https://api.example.com
VITE_LOG_LEVEL=error
```
- **Rule:** Never hardcode API keys. Never expose in frontend.
- **External services:** Always proxy through backend.

## Rate Limiting and Throttling

### Golang Implementation
- **Per-endpoint limits:** e.g., `/auth/login` max 5 reqs/min per IP
- **Middleware:** Use `github.com/go-chi/chi/middleware` or custom rate limiter
- **Strategy:** Fixed window or sliding window (prefer sliding)
- **Response:** HTTP 429 (Too Many Requests) with `Retry-After` header

```go
func rateLimitMiddleware(maxReq int, window time.Duration) func(http.Handler) http.Handler {
  limiter := rate.NewLimiter(rate.Every(window/time.Duration(maxReq)), 1)
  return func(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
      if !limiter.Allow() {
        w.Header().Set("Retry-After", "60")
        http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
        return
      }
      next.ServeHTTP(w, r)
    })
  }
}
```

### React Usage
- **Debounce API calls:** Use `_.debounce` or `setTimeout` (e.g., search inputs)
- **Button disable:** Disable submit button after click until response
- **Exponential backoff:** On retry, increase delay (500ms → 1s → 2s → 4s)

## CORS Configuration

### Golang
```go
c := cors.New(cors.Options{
  AllowedOrigins:   []string{os.Getenv("CORS_ORIGIN")},
  AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE"},
  AllowedHeaders:   []string{"Authorization", "Content-Type"},
  ExposedHeaders:   []string{"X-Total-Count"},
  AllowCredentials: true,
  MaxAge:           300,
})
```
- **Rule:** Never use `*` for AllowedOrigins in production.
- **Credentials:** Allow only if HTTPS in place.

## HTTPS/TLS Requirements

- **All traffic:** HTTPS only. Redirect HTTP → HTTPS.
- **Certificate:** Valid, not self-signed (use Let's Encrypt)
- **TLS version:** 1.2 minimum
- **Ciphers:** Strong ciphers only, disable weak ones
- **HSTS header:** Enforce HTTPS for 1 year:
  ```
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  ```

## React-Specific Security

### Content Security Policy (CSP)
```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
  font-src 'self';
  object-src 'none';
  base-uri 'self';
  form-action 'self'
">
```

### DOMPurify for HTML Content
```jsx
import DOMPurify from 'dompurify';

// When rendering user-provided HTML
<div dangerouslySetInnerHTML={{
  __html: DOMPurify.sanitize(htmlContent)
}} />
```

### XSS Prevention
- **Never use:** `dangerouslySetInnerHTML` without DOMPurify
- **Always escape:** Template literals for attribute values
- **React escapes by default:** `{}` expressions are safe (not raw HTML)

### Secure Cookie Handling
```jsx
// httpOnly prevents XSS from stealing token
// Secure flag ensures only HTTPS transmission
// SameSite prevents CSRF attacks
document.cookie = "token=...; httpOnly; Secure; SameSite=Strict; Path=/";
```

## Golang-Specific Security

### Error Handling (No Panic in Production)
```go
// Good: Explicit error handling
if err != nil {
  log.Errorf("database error: %v", err) // Safe to log
  w.WriteHeader(http.StatusInternalServerError)
  w.Write([]byte(`{"error":"Internal error"}`))
  return
}

// BAD: panic in request handler
panic(err) // Crashes server, info leak
```

### Context Cancellation
```go
// Propagate context down the call stack
func CreateUser(ctx context.Context, email string) error {
  select {
  case <-ctx.Done():
    return ctx.Err()
  default:
  }
  // Proceed with business logic
}
```

### Logging Without PII
```go
// Good: Log action, not data
log.Infof("user_created user_id=%s", userID) // Safe

// BAD: Logging sensitive data
log.Infof("user_created email=%s password=%s", email, password) // Breach!
```

## Security Checklist

### For Every Feature Spec
- [ ] Identify all users/roles with access
- [ ] Define authentication method (JWT, OAuth, etc.)
- [ ] List all data inputs and validation rules
- [ ] Identify sensitive data (PII, keys, tokens)
- [ ] Define data retention policy
- [ ] Identify external integrations and their auth
- [ ] Plan error handling (no details leaked)
- [ ] Plan logging strategy (no PII)

### For Every Technical Spec
- [ ] All passwords/secrets stored via env vars
- [ ] No hardcoded credentials anywhere
- [ ] HTTPS/TLS enforced
- [ ] Input validation at API boundary
- [ ] SQL queries parameterized
- [ ] JWT validation implemented
- [ ] Rate limiting configured
- [ ] CORS configured for specific origins
- [ ] Error messages don't reveal internals
- [ ] Logs don't contain sensitive data
- [ ] React components sanitize HTML
- [ ] Dependencies up-to-date (audit run)

---

**Last Updated:** 2026-07-01
