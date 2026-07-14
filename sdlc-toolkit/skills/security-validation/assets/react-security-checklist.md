# React Security Validation Checklist

**Project:** [Project Name]
**Date:** [Date]
**Reviewer:** [Name/Tool]

---

## A01: Broken Access Control

### Authentication & Authorization
- [ ] Authentication required for protected routes
- [ ] JWT tokens verified before API calls
- [ ] User can only access own data
- [ ] Admin routes protected
- [ ] Roles/permissions enforced client-side AND server-side

**Vulnerable:**
```typescript
// ❌ NEVER: Trust only client-side auth
if (user.role === 'admin') {
  return <AdminPanel />
}
```

**Secure:**
```typescript
// ✅ ALWAYS: Verify on server, also validate on client
function AdminRoute({ children }) {
  const { user } = useAuth()

  if (!user || user.role !== 'admin') {
    return <Redirect to="/login" />
  }

  return children
}

// Server must also validate:
// GET /api/admin/users
// → 403 Forbidden if user.role !== 'admin'
```

### Route Protection
- [ ] Protected routes require auth
- [ ] Unauthenticated users redirected to login
- [ ] Expired sessions detected and handled
- [ ] Token refresh automatic
- [ ] Logout clears all session data

**Secure Pattern:**
```typescript
function useAuth() {
  const [user, setUser] = useState(null)

  useEffect(() => {
    const token = localStorage.getItem('authToken')
    if (token) {
      verifyToken(token)
        .then(u => setUser(u))
        .catch(() => logout())
    }
  }, [])

  return { user }
}

function ProtectedRoute({ children }) {
  const { user } = useAuth()
  return user ? children : <Navigate to="/login" />
}
```

---

## A02: Cryptographic Failures

### Secure Storage
- [ ] Sensitive data NOT in localStorage
- [ ] Session tokens in httpOnly cookies (server-set)
- [ ] No sensitive data in sessionStorage
- [ ] No sensitive data in component state (logs)
- [ ] Encryption for stored PII

**Vulnerable:**
```typescript
// ❌ NEVER
localStorage.setItem('token', jwt)
localStorage.setItem('password', password)
sessionStorage.setItem('creditCard', cardNumber)
```

**Secure:**
```typescript
// ✅ ALWAYS: Let server manage auth via httpOnly cookie
// Browser automatically sends in requests
// JS cannot access (safe from XSS)

// If client-side storage needed:
const encrypted = CryptoJS.AES.encrypt(sensitiveData, encryptionKey)
sessionStorage.setItem('temp_data', encrypted)
```

### HTTPS Enforcement
- [ ] All API calls use HTTPS
- [ ] Mixed content warnings resolved
- [ ] Certificate validation enabled
- [ ] No downgrade to HTTP

**Secure:**
```typescript
const API_URL = 'https://api.example.com'

const apiClient = axios.create({
  baseURL: API_URL,
  httpsAgent: new https.Agent({ rejectUnauthorized: true })
})
```

### Password Handling
- [ ] Passwords never logged
- [ ] Passwords never stored client-side
- [ ] Password strength indicator shown
- [ ] Password confirmation required

**Vulnerable:**
```typescript
// ❌ NEVER
console.log('Password:', password)
setState({ password: userInput })
```

**Secure:**
```typescript
// ✅ ALWAYS
const [passwordStrength, setPasswordStrength] = useState(0)

function handlePasswordChange(e) {
  const pwd = e.target.value
  setPasswordStrength(calculateStrength(pwd))
  // Don't store in state
}

function calculateStrength(pwd) {
  let score = 0
  if (pwd.length >= 12) score++
  if (/[A-Z]/.test(pwd)) score++
  if (/[0-9]/.test(pwd)) score++
  if (/[!@#$%^&*]/.test(pwd)) score++
  return score
}
```

---

## A03: Injection

### XSS Prevention (Cross-Site Scripting)

#### Safe React Rendering
- [ ] Never use dangerouslySetInnerHTML
- [ ] User input rendered as text, not HTML
- [ ] Third-party HTML sanitized with DOMPurify
- [ ] Content-Security-Policy header set

**Vulnerable:**
```typescript
// ❌ NEVER
<div dangerouslySetInnerHTML={{ __html: userInput }} />
<div>{userInput}</div> // IF userInput contains HTML
<img src={'javascript:alert("xss")'} />
```

**Secure:**
```typescript
// ✅ ALWAYS: React escapes by default
<div>{userInput}</div> // Safe, React escapes

// For HTML content, sanitize:
import DOMPurify from 'dompurify'
const cleanHTML = DOMPurify.sanitize(userHTML)
<div dangerouslySetInnerHTML={{ __html: cleanHTML }} />

// Safe URLs only
<a href={sanitizeURL(userUrl)}>Link</a>

function sanitizeURL(url) {
  try {
    const parsed = new URL(url, window.location.origin)
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return '#'
    }
    return parsed.toString()
  } catch {
    return '#'
  }
}
```

#### Event Handler Security
- [ ] No eval() in event handlers
- [ ] No inline script execution
- [ ] Event handlers validated

**Vulnerable:**
```typescript
// ❌ NEVER
<div onClick={() => eval(userCode)} />
<button onClick={new Function(userCode)} />
```

**Secure:**
```typescript
// ✅ ALWAYS
<div onClick={() => handleTaskComplete(taskId)} />

function handleTaskComplete(taskId) {
  // Predefined actions only
  updateTask(taskId, { status: 'done' })
}
```

### CSRF Prevention
- [ ] CSRF token included in forms
- [ ] SameSite=Strict cookies
- [ ] POST/PUT/DELETE requires CSRF token
- [ ] Preflight requests validated

**Secure:**
```typescript
// Server sends CSRF token
const [csrfToken, setCsrfToken] = useState('')

useEffect(() => {
  getCsrfToken().then(setCsrfToken)
}, [])

// Include in requests
const createTask = async (data) => {
  return axios.post('/api/tasks', data, {
    headers: {
      'X-CSRF-Token': csrfToken
    }
  })
}
```

### Template Injection
- [ ] No template eval with user input
- [ ] Template variables validated
- [ ] Mustache/template libraries used safely

**Vulnerable:**
```typescript
// ❌ NEVER
const template = `Hello ${userName}`
eval(template)
```

**Secure:**
```typescript
// ✅ ALWAYS
<div>Hello {userName}</div>
```

---

## A04: Insecure Design

### Threat Modeling for Frontend
- [ ] User flows documented
- [ ] Attack vectors identified per flow
- [ ] Mitigations implemented
- [ ] Security requirements documented

### Security by Design
- [ ] Input validation required
- [ ] Output encoding required
- [ ] Authentication required for sensitive operations
- [ ] Authorization checks enforced
- [ ] Audit logging enabled

---

## A05: Security Misconfiguration

### CSP Header
- [ ] Content-Security-Policy configured
- [ ] script-src restricted
- [ ] style-src restricted
- [ ] img-src restricted

**Secure:**
```typescript
// In .htaccess or nginx config:
// Content-Security-Policy:
//   default-src 'self';
//   script-src 'self' trusted-cdn.com;
//   style-src 'self' 'unsafe-inline';
//   img-src 'self' data:;
```

### CORS Configuration
- [ ] Only trusted origins allowed
- [ ] Credentials not exposed unnecessarily
- [ ] Preflight requests validated
- [ ] Server enforces CORS

**Secure:**
```typescript
const apiClient = axios.create({
  baseURL: 'https://api.example.com',
  withCredentials: false, // Unless needed
  headers: {
    'Content-Type': 'application/json'
  }
})
```

### Environment Variables
- [ ] No secrets in .env.example
- [ ] .env.local in .gitignore
- [ ] API URLs configurable per environment
- [ ] Debug mode disabled in production

**Vulnerable:**
```bash
# ❌ NEVER
VITE_API_KEY=sk_live_1234567890abcdef
```

**Secure:**
```bash
# ✅ ALWAYS (.env.example)
VITE_API_URL=https://api.example.com
# Actual API key configured at deployment time

# .gitignore
.env.local
.env.*.local
```

### Error Boundaries
- [ ] Error Boundary wraps app
- [ ] Errors logged securely
- [ ] User-friendly error messages shown
- [ ] Stack traces not exposed to user

**Secure:**
```typescript
class ErrorBoundary extends React.Component {
  componentDidCatch(error, errorInfo) {
    // Log securely (server-side)
    logError(error, errorInfo)
    // Show generic message to user
  }

  render() {
    if (this.state.hasError) {
      return <div>Something went wrong</div>
    }
    return this.props.children
  }
}
```

---

## A06: Vulnerable & Outdated Components

### Dependency Management
- [ ] package.json reviewed quarterly
- [ ] `npm audit` passing
- [ ] No critical vulnerabilities
- [ ] Dependencies updated safely

**Regular Audits:**
```bash
npm audit
npm outdated
npm update
```

### Common Vulnerable Packages
- [ ] jQuery (deprecated, use vanilla JS)
- [ ] lodash (minimize usage)
- [ ] moment.js (use date-fns/dayjs)
- [ ] eval() packages
- [ ] dynamic require packages

### Build Security
- [ ] Source maps not deployed to production
- [ ] .env files not committed
- [ ] Secrets not in bundle
- [ ] Bundle size monitored

---

## A07: Authentication Failures

### JWT Token Handling
- [ ] Tokens obtained securely (HTTPS)
- [ ] Tokens stored securely (httpOnly cookie)
- [ ] Token expiration checked
- [ ] Refresh token flow implemented
- [ ] Logout clears session

**Secure:**
```typescript
function useAuth() {
  const [user, setUser] = useState(null)

  const login = async (email, password) => {
    const response = await axios.post('/auth/login',
      { email, password },
      { withCredentials: true } // Sends httpOnly cookie
    )
    setUser(response.data.user)
  }

  const logout = async () => {
    await axios.post('/auth/logout', {}, { withCredentials: true })
    setUser(null)
  }

  return { user, login, logout }
}
```

### MFA Support
- [ ] MFA option offered (TOTP, SMS)
- [ ] MFA required for sensitive operations
- [ ] Recovery codes provided

### Session Timeout
- [ ] Session timeout configured (15-30min)
- [ ] Idle timeout detected
- [ ] Logout warning shown
- [ ] Automatic logout enforced

**Secure:**
```typescript
function useSessionTimeout() {
  useEffect(() => {
    let timeout
    let warningTimeout

    const resetTimeout = () => {
      clearTimeout(timeout)
      clearTimeout(warningTimeout)

      // Warn after 14 min
      warningTimeout = setTimeout(() => {
        showWarning('Session expires in 1 minute')
      }, 14 * 60 * 1000)

      // Logout after 15 min
      timeout = setTimeout(() => {
        logout()
      }, 15 * 60 * 1000)
    }

    window.addEventListener('mousemove', resetTimeout)
    window.addEventListener('keypress', resetTimeout)

    resetTimeout()

    return () => {
      clearTimeout(timeout)
      clearTimeout(warningTimeout)
      window.removeEventListener('mousemove', resetTimeout)
      window.removeEventListener('keypress', resetTimeout)
    }
  }, [])
}
```

---

## A08: Data Integrity Failures

### Input Validation
- [ ] All form inputs validated
- [ ] Type validation enforced (string, number, email)
- [ ] Length validation enforced
- [ ] Format validation (email, URL, phone)
- [ ] Range validation (dates, numbers)

**Secure Pattern:**
```typescript
import { z } from 'zod'

const CreateTaskSchema = z.object({
  title: z.string()
    .min(1, 'Required')
    .max(200, 'Too long')
    .nonempty(),
  priority: z.enum(['low', 'medium', 'high']),
  dueDate: z.date().min(new Date()),
})

function TaskForm() {
  const [errors, setErrors] = useState({})

  async function handleSubmit(e) {
    e.preventDefault()

    try {
      const data = CreateTaskSchema.parse(formData)
      await createTask(data)
    } catch (error) {
      if (error instanceof z.ZodError) {
        setErrors(error.flatten().fieldErrors)
      }
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <Input error={errors.title?.[0]} />
    </form>
  )
}
```

### Output Encoding
- [ ] User data rendered safely
- [ ] HTML entities escaped
- [ ] URLs validated before rendering
- [ ] JSON properly encoded

**Secure:**
```typescript
// React escapes by default
<div>{userComment}</div> // Safe

// URLs validated
const isSafeUrl = (url) => {
  try {
    const parsed = new URL(url)
    return ['https:', 'http:'].includes(parsed.protocol)
  } catch {
    return false
  }
}

<a href={isSafeUrl(userUrl) ? userUrl : '#'}>Link</a>
```

---

## A09: Logging & Monitoring Failures

### Error Logging
- [ ] Errors logged to server (not console)
- [ ] Sensitive data not logged
- [ ] Error context captured (user ID, timestamp, URL)
- [ ] Error tracking integrated (Sentry, etc.)

**Secure:**
```typescript
import * as Sentry from '@sentry/react'

Sentry.init({
  dsn: process.env.VITE_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  integrations: [
    new Sentry.Replay({
      maskAllText: true, // Don't record user input
      blockAllMedia: true,
    }),
  ],
  denyUrls: [
    // Browser extensions
    /extensions\//i,
    /^chrome:\/\//i,
  ],
})

// In error boundary
componentDidCatch(error, errorInfo) {
  Sentry.captureException(error, { contexts: { react: errorInfo } })
}
```

### User Activity Logging
- [ ] Important actions logged (create, delete, export)
- [ ] No sensitive data logged
- [ ] Timestamps accurate
- [ ] User ID captured

**Secure:**
```typescript
async function deleteTask(taskId) {
  await api.delete(`/tasks/${taskId}`)

  // Log server-side:
  // event_type: "task_deleted"
  // user_id: current_user
  // task_id: taskId
  // timestamp: now
  // ip_address: client_ip
}
```

### Performance Monitoring
- [ ] Page load time monitored
- [ ] API response time monitored
- [ ] Error rates monitored
- [ ] Alerts configured

---

## A10: SSRF (Server-Side Request Forgery)

### Link Validation
- [ ] User-provided URLs validated
- [ ] Internal IPs blocked (127.0.0.1, 192.168.*, etc.)
- [ ] Localhost blocked
- [ ] Protocol validated (http/https only)

**Secure:**
```typescript
function validateLink(url) {
  try {
    const parsed = new URL(url)

    // Only http/https
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      return false
    }

    // Block localhost
    const host = parsed.hostname
    if (host === 'localhost' || host === '127.0.0.1') {
      return false
    }

    // Block private IPs
    const privateRanges = [
      /^192\.168\./,
      /^10\./,
      /^172\.(1[6-9]|2\d|3[01])\./,
      /^fc00:/,
      /^::1$/,
    ]

    if (privateRanges.some(range => range.test(host))) {
      return false
    }

    return true
  } catch {
    return false
  }
}
```

---

## Security Testing

### Unit Tests
- [ ] Auth validation tested
- [ ] Input validation tested
- [ ] XSS prevention tested
- [ ] Safe URL rendering tested

**Example:**
```typescript
import { render, screen } from '@testing-library/react'

describe('XSS Prevention', () => {
  it('escapes user input', () => {
    const xssPayload = '<script>alert("xss")</script>'
    render(<TaskCard title={xssPayload} />)
    expect(screen.queryByText('alert')).not.toBeInTheDocument()
  })
})
```

### Integration Tests
- [ ] Auth flow tested
- [ ] Protected routes tested
- [ ] CSRF token validated
- [ ] API errors handled gracefully

### Security Scanning
```bash
npm audit
npm audit fix
npm outdated
npx snyk test
```

---

## Deployment Checklist

**Before Production Deployment:**
- [ ] All inputs validated
- [ ] No XSS vulnerabilities
- [ ] No secrets in code/config
- [ ] HTTPS enforced
- [ ] CSP header configured
- [ ] CORS configured properly
- [ ] Authentication implemented
- [ ] Session timeout configured
- [ ] Error boundaries in place
- [ ] Error logging secure
- [ ] Dependency audit passing
- [ ] Build output verified
- [ ] Source maps removed
- [ ] .env.local not committed
- [ ] Security headers set

---

**Status:** ✅ Checklist Complete
**Next Step:** Address any failed items before deployment
