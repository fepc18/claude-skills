# Golang Security Validation Checklist

**Project:** [Project Name]
**Date:** [Date]
**Reviewer:** [Name/Tool]

---

## A01: Broken Access Control

### Input Validation
- [ ] All endpoints validate Authorization header (Bearer token)
- [ ] JWT token claims verified (exp, iss, sub)
- [ ] Role-based access control (RBAC) implemented per endpoint
- [ ] User can only access their own resources
- [ ] Admin endpoints protected with elevated privileges
- [ ] No hardcoded roles in code

**Test Cases:**
```go
func TestEndpoint_RequiresAuth(t *testing.T) {
  req := httptest.NewRequest("GET", "/api/protected", nil)
  // No Authorization header
  w := httptest.NewRecorder()
  handler.ServeHTTP(w, req)
  assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestEndpoint_VerifiesRoles(t *testing.T) {
  // User token
  req := httptest.NewRequest("DELETE", "/api/admin/users", nil)
  req.Header.Set("Authorization", "Bearer "+userToken)
  w := httptest.NewRecorder()
  handler.ServeHTTP(w, req)
  assert.Equal(t, http.StatusForbidden, w.Code)
}
```

**Secure Pattern:**
```go
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
  // Extract token
  token, err := extractBearerToken(r.Header.Get("Authorization"))
  if err != nil {
    respondError(w, http.StatusUnauthorized, "invalid token")
    return
  }

  // Verify token
  claims, err := jwt.Verify(token, jwtSecret)
  if err != nil {
    respondError(w, http.StatusUnauthorized, "token invalid")
    return
  }

  // Check permissions
  if !hasPermission(claims.UserID, "create:tasks") {
    respondError(w, http.StatusForbidden, "insufficient permissions")
    return
  }

  // Proceed with action
  // ...
}
```

---

## A02: Cryptographic Failures

### TLS/HTTPS
- [ ] TLS 1.3 enforced (minimum 1.2)
- [ ] Strong cipher suites configured
- [ ] Certificate validation enabled
- [ ] HSTS header set
- [ ] No mixed HTTP/HTTPS content

**Secure Pattern:**
```go
server := &http.Server{
  Addr:      ":8080",
  Handler:   router,
  TLSConfig: &tls.Config{
    MinVersion:   tls.VersionTLS13,
    CipherSuites: []uint16{
      tls.TLS_AES_256_GCM_SHA384,
      tls.TLS_CHACHA20_POLY1305_SHA256,
      tls.TLS_AES_128_GCM_SHA256,
    },
  },
}
server.ListenAndServeTLS("cert.pem", "key.pem")
```

### Secrets Management
- [ ] No secrets in code (git history checked)
- [ ] No secrets in logs
- [ ] Secrets stored in vault (environment variables, Key Vault)
- [ ] Secret rotation enabled
- [ ] Database passwords use strong characters

**Vulnerable:**
```go
// ❌ NEVER
const DBPassword = "postgres123"
const JWTSecret = "my-secret-key"
```

**Secure:**
```go
// ✅ ALWAYS
dbPassword := os.Getenv("DB_PASSWORD")
if dbPassword == "" {
  log.Fatal("DB_PASSWORD not set")
}

jwtSecret := os.Getenv("JWT_SECRET")
if len(jwtSecret) < 32 {
  log.Fatal("JWT_SECRET must be >= 32 characters")
}
```

### Password Hashing
- [ ] bcrypt used (not MD5, SHA1, SHA256)
- [ ] Work factor >= 12
- [ ] Passwords never stored in plaintext

**Vulnerable:**
```go
// ❌ NEVER
hash := md5.Sum([]byte(password))
```

**Secure:**
```go
// ✅ ALWAYS
hashed, err := bcrypt.GenerateFromPassword([]byte(password), 12)
if err != nil {
  return err
}

// Verify
err = bcrypt.CompareHashAndPassword(hashed, []byte(password))
```

---

## A03: Injection

### SQL Injection Prevention
- [ ] Parameterized queries exclusively (no string formatting)
- [ ] sqlx or prepared statements used
- [ ] Input validation before queries
- [ ] No dynamic WHERE clauses
- [ ] SQL comments validated

**Vulnerable:**
```go
// ❌ NEVER
userID := r.URL.Query().Get("id")
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Query(query)
```

**Secure:**
```go
// ✅ ALWAYS
userID := r.URL.Query().Get("id")
var user User
err := db.Get(&user, "SELECT * FROM users WHERE id = ?", userID)
```

### Command Injection Prevention
- [ ] exec.Command with argument array (not shell)
- [ ] User input not used in shell commands
- [ ] os.Exec validates input
- [ ] No os.system() calls

**Vulnerable:**
```go
// ❌ NEVER
cmd := fmt.Sprintf("convert %s -quality 85 %s", input, output)
exec.Command("bash", "-c", cmd)
```

**Secure:**
```go
// ✅ ALWAYS
cmd := exec.Command("convert", input, "-quality", "85", output)
output, err := cmd.Output()
```

### Code Injection Prevention
- [ ] No eval/exec of user input
- [ ] No template injection (html/template not text/template)
- [ ] No reflection with user input

**Vulnerable:**
```go
// ❌ NEVER
userCode := r.URL.Query().Get("filter")
t, _ := template.New("t").Parse("SELECT * FROM users WHERE " + userCode)
```

**Secure:**
```go
// ✅ ALWAYS
// Use parameterized queries
status := r.URL.Query().Get("status")
db.Select(&users, "SELECT * FROM users WHERE status = ?", status)
```

**Test:**
```go
func TestSQLInjection_Rejected(t *testing.T) {
  injection := "'; DROP TABLE users; --"
  req := httptest.NewRequest("GET", "/api/tasks?status="+injection, nil)
  w := httptest.NewRecorder()
  handler.ServeHTTP(w, req)
  // Should not execute SQL
  assert.Equal(t, http.StatusBadRequest, w.Code)
}
```

---

## A04: Insecure Design

### Threat Modeling
- [ ] STRIDE threat model documented
- [ ] Data flow diagram created
- [ ] Trust boundaries identified
- [ ] Threats per boundary listed
- [ ] Controls assigned per threat

**Minimum Threats to Model:**
- Spoofing: Can attacker fake identity? (auth)
- Tampering: Can attacker modify data? (integrity)
- Repudiation: Can attacker deny action? (audit log)
- Info Disclosure: Can attacker read data? (encryption)
- Denial of Service: Can attacker disable service? (rate limit)
- Elevation of Privilege: Can attacker gain admin? (authz)

### Security Requirements
- [ ] Authentication requirement documented
- [ ] Authorization requirement documented
- [ ] Data protection requirement documented
- [ ] Audit logging requirement documented
- [ ] Rate limiting requirement documented

---

## A05: Security Misconfiguration

### Default Credentials
- [ ] No default admin credentials
- [ ] Database doesn't use default password
- [ ] API doesn't expose default endpoints
- [ ] No debug mode in production

**Vulnerable:**
```go
// ❌ NEVER
if password == "admin123" {
  isAdmin = true
}
```

### Error Messages
- [ ] No stack traces exposed
- [ ] No sensitive info in error messages
- [ ] Generic error messages to users
- [ ] Detailed logs server-side only

**Vulnerable:**
```go
// ❌ NEVER
respondError(w, 500, fmt.Sprintf("Database error: %v", err))
```

**Secure:**
```go
// ✅ ALWAYS
logger.Error().Err(err).Msg("database error")
respondError(w, 500, "internal server error")
```

### CORS Configuration
- [ ] Not allowing all origins (*)
- [ ] Whitelist specific domains
- [ ] Credentials flag conditional
- [ ] Preflight requests validated

**Vulnerable:**
```go
// ❌ NEVER
w.Header().Set("Access-Control-Allow-Origin", "*")
w.Header().Set("Access-Control-Allow-Credentials", "true")
```

**Secure:**
```go
// ✅ ALWAYS
allowedOrigins := []string{"https://example.com"}
origin := r.Header.Get("Origin")
if contains(allowedOrigins, origin) {
  w.Header().Set("Access-Control-Allow-Origin", origin)
}
```

### Security Headers
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY
- [ ] Strict-Transport-Security
- [ ] Content-Security-Policy

**Secure Middleware:**
```go
func SecurityHeaders(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("X-Content-Type-Options", "nosniff")
    w.Header().Set("X-Frame-Options", "DENY")
    w.Header().Set("X-XSS-Protection", "1; mode=block")
    w.Header().Set("Strict-Transport-Security", "max-age=31536000")
    next.ServeHTTP(w, r)
  })
}
```

---

## A06: Vulnerable & Outdated Components

### Dependency Management
- [ ] go.mod maintained and reviewed
- [ ] No packages with known CVEs
- [ ] `go mod audit` passes
- [ ] Dependencies updated quarterly
- [ ] Breaking changes evaluated

**Regular Audits:**
```bash
go mod audit
go list -m all | sort
go mod tidy
```

### Dependency Security
- [ ] Production vs. dev dependencies separated
- [ ] No test dependencies in production
- [ ] GitHub alerts enabled
- [ ] Dependabot configured

---

## A07: Authentication Failures

### JWT Implementation
- [ ] RS256 signing (asymmetric, not HS256)
- [ ] Token expiration set (15min access, 7day refresh)
- [ ] Refresh token rotation implemented
- [ ] Token claims validated (exp, iss, aud)
- [ ] No sensitive data in JWT payload

**Vulnerable:**
```go
// ❌ NEVER
token, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(secret)
```

**Secure:**
```go
// ✅ ALWAYS
token, _ := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{
  "sub": userID,
  "exp": time.Now().Add(15 * time.Minute).Unix(),
  "iss": "taskmanager",
  "aud": "taskmanager-api",
}).SignedString(privateKey)
```

### Password Policies
- [ ] Minimum 12 characters required
- [ ] Complexity rules enforced (uppercase, number, special)
- [ ] Password expiration (if required)
- [ ] Password history (no reuse of last 5)
- [ ] Breach database checked

### Session Management
- [ ] Session tokens httpOnly (no JS access)
- [ ] Secure flag set (HTTPS only)
- [ ] SameSite=Strict
- [ ] Session timeout configured (15-30min)
- [ ] No session fixation

**Secure:**
```go
http.SetCookie(w, &http.Cookie{
  Name:     "session_id",
  Value:    sessionToken,
  MaxAge:   900, // 15 minutes
  HttpOnly: true,
  Secure:   true,
  SameSite: http.SameSiteLaxMode,
  Path:     "/",
})
```

### Rate Limiting (Auth Endpoints)
- [ ] Login: max 5 attempts per 5 minutes per IP
- [ ] Password reset: max 3 attempts per 1 hour per email
- [ ] Account lockout after failures
- [ ] Exponential backoff implemented

**Secure:**
```go
func RateLimitLogin(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    ip := getClientIP(r)
    attempts := cache.Get("login_attempts_" + ip).(int)

    if attempts > 5 {
      respondError(w, http.StatusTooManyRequests, "too many attempts")
      return
    }

    cache.Set("login_attempts_"+ip, attempts+1, 5*time.Minute)
    next.ServeHTTP(w, r)
  })
}
```

---

## A08: Data Integrity Failures

### Input Validation
- [ ] All user input validated
- [ ] Type validation enforced
- [ ] Length validation enforced
- [ ] Format validation (email, URL, etc.)
- [ ] Range validation (dates, numbers)
- [ ] No empty/null bypasses

**Secure Pattern:**
```go
type CreateTaskInput struct {
  Title       string `json:"title" validate:"required,min=1,max=200"`
  Description string `json:"description" validate:"max=5000"`
  Priority    string `json:"priority" validate:"required,oneof=low medium high"`
  DueDate     *time.Time `json:"dueDate" validate:"gtfield=Now"`
}

// Validate using validator library
validate := validator.New()
err := validate.Struct(input)
```

### Output Encoding
- [ ] HTML output escaped
- [ ] JSON output properly encoded
- [ ] No raw user input in responses
- [ ] Content-Type headers correct

**Vulnerable:**
```go
// ❌ NEVER
fmt.Fprintf(w, "Hello "+userInput)
```

**Secure:**
```go
// ✅ ALWAYS
type Response struct {
  Message string `json:"message"`
}
w.Header().Set("Content-Type", "application/json")
json.NewEncoder(w).Encode(Response{Message: userInput})
```

### Database Constraints
- [ ] NOT NULL constraints where required
- [ ] UNIQUE constraints where required
- [ ] CHECK constraints for valid values
- [ ] Foreign key constraints

---

## A09: Logging & Monitoring Failures

### Security Event Logging
- [ ] Authentication attempts logged (success/failure)
- [ ] Authorization decisions logged
- [ ] Data modifications logged (create/update/delete)
- [ ] Security configuration changes logged
- [ ] Admin actions logged
- [ ] Timestamps in UTC
- [ ] Structured logging (JSON)

**Secure Pattern:**
```go
logger.Info().
  Str("event_type", "user_login").
  Str("user_id", userID).
  Str("ip_address", getClientIP(r)).
  Bool("success", success).
  Str("reason", failureReason). // if !success
  Time("timestamp", time.Now().UTC()).
  Msg("authentication event")

// Never log:
// - Passwords
// - Tokens
// - PII (email, SSN, phone)
// - Sensitive API responses
```

### Monitoring & Alerting
- [ ] Error rate monitored (alert if >1%)
- [ ] Unusual login patterns monitored
- [ ] Database query failures monitored
- [ ] Failed authentication attempts monitored
- [ ] Rate limit violations monitored
- [ ] Admin actions audited

### Log Retention
- [ ] Security logs retained 90 days minimum
- [ ] Access logs retained 30 days minimum
- [ ] Audit logs retained 1 year minimum
- [ ] Logs encrypted at rest
- [ ] Logs tamper-protected

---

## A10: SSRF (Server-Side Request Forgery)

### URL Validation
- [ ] Only whitelisted hosts allowed
- [ ] Internal IPs blocked (127.0.0.1, 192.168.*, etc.)
- [ ] Localhost blocked
- [ ] Private IP ranges blocked
- [ ] URL scheme validated (http/https only)

**Vulnerable:**
```go
// ❌ NEVER
url := r.URL.Query().Get("image_url")
resp, _ := http.Get(url)
```

**Secure:**
```go
// ✅ ALWAYS
url := r.URL.Query().Get("image_url")

// Parse URL
parsed, _ := url.Parse(url)

// Validate scheme
if parsed.Scheme != "http" && parsed.Scheme != "https" {
  respondError(w, 400, "invalid scheme")
  return
}

// Whitelist hosts
allowedHosts := []string{"cdn.example.com", "images.example.com"}
if !contains(allowedHosts, parsed.Host) {
  respondError(w, 400, "host not allowed")
  return
}

// Validate IP (block private ranges)
host := parsed.Hostname()
ip := net.ParseIP(host)
if ip != nil && isPrivateIP(ip) {
  respondError(w, 400, "private IPs not allowed")
  return
}

resp, _ := http.Get(url)
```

**Helper:**
```go
func isPrivateIP(ip net.IP) bool {
  return ip.IsLoopback() ||
    ip.IsPrivate() ||
    ip.IsLinkLocalUnicast() ||
    ip.IsLinkLocalMulticast()
}
```

---

## Security Testing

### Unit Tests
- [ ] Auth validation tested
- [ ] Input validation tested
- [ ] Injection attacks tested
- [ ] Access control tested

### Integration Tests
- [ ] End-to-end auth flow tested
- [ ] Database constraints enforced
- [ ] Error messages don't leak info

### Security Tests
```bash
# Dependency audit
go mod audit

# Static analysis
go vet ./...
golangci-lint run

# SAST scan (if available)
# sonarqube, semgrep, etc.
```

---

## Final Checklist

**Before Deployment:**
- [ ] All OWASP categories reviewed
- [ ] Security tests pass
- [ ] Code review completed by security team
- [ ] Vulnerability scan passing
- [ ] Dependencies audit passing
- [ ] No hardcoded secrets
- [ ] Logging doesn't expose PII
- [ ] Error handling secure
- [ ] Authentication implemented
- [ ] Authorization enforced
- [ ] Input validation complete
- [ ] SQL injection prevented
- [ ] Rate limiting configured
- [ ] Security headers set
- [ ] CORS properly configured
- [ ] TLS 1.3 enforced
- [ ] Monitoring enabled

---

**Status:** ✅ Checklist Complete
**Next Step:** Address any failed items before deployment
