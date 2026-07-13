# Technical Specification: [Feature Name] (React Frontend)

**Version:** 1.0
**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Status:** Draft / In Review / Approved

---

## 1. Component Tree & Atomic Design

**Atomic Design Structure:**
```
┌─ Pages
│  └─ [FeatureName]Page
│     └─ [FeatureName]Layout (Template)
│        └─ [FeatureName]Container (Organism)
│           ├─ [Component]Organism
│           │  └─ [Component]Molecule (plural)
│           │     └─ [Component]Atom (plural)
│           └─ [Component]Organism
│              └─ [Component]Molecule
│                 └─ [Component]Atom
└─ Components
   ├─ atoms/
   │  ├─ Button.tsx
   │  ├─ Input.tsx
   │  ├─ Label.tsx
   │  └─ [OtherAtom].tsx
   ├─ molecules/
   │  ├─ FormField.tsx
   │  ├─ [Component]Molecule.tsx
   │  └─ [OtherMolecule].tsx
   ├─ organisms/
   │  ├─ [Feature]Form.tsx
   │  ├─ [Feature]List.tsx
   │  └─ [OtherOrganism].tsx
   └─ templates/
      └─ [Feature]Layout.tsx
```

**Component Hierarchy:**

| Level | Name | Props | Purpose |
|-------|------|-------|---------|
| Atom | Button | `{label, onClick, variant?, disabled?}` | Reusable UI element |
| Atom | Input | `{value, onChange, type, placeholder}` | Form input field |
| Atom | Label | `{text, htmlFor}` | Form label |
| Molecule | FormField | `{label, value, onChange, error?}` | Label + Input combo |
| Organism | LoginForm | `{onSubmit}` | Complete login form |
| Page | LoginPage | `{}` | Routed page component |

---

## 2. Component Specifications

### Component 1: [ComponentName]

**File Location:** `src/components/[level]/[ComponentName].tsx`

**Atomic Level:** [Atom / Molecule / Organism / Template / Page]

**Purpose:**
[What does this component do? What user problem does it solve?]

**Props Interface:**
```typescript
interface [ComponentName]Props {
  // Required props
  requiredProp: string;
  onEventHandler: (value: string) => void;

  // Optional props with defaults
  optionalProp?: boolean;
  variant?: 'primary' | 'secondary' | 'danger';

  // Children if compound component
  children?: React.ReactNode;
}
```

**State Management:**
```typescript
// Internal state (useState)
const [isOpen, setIsOpen] = useState(false);
const [selectedTab, setSelectedTab] = useState<'overview' | 'details'>('overview');

// No global state needed for this component
```

**Hooks Used:**
- `useState`: For isOpen (UI state)
- `useCallback`: For event handlers passed to children
- `useEffect`: For side effects (optional)
- Custom hook: `use[Domain]` (if applicable)

**Styling Approach:**
- [ ] CSS Modules (`[ComponentName].module.css`)
- [ ] Tailwind Classes (`className="p-4 bg-blue-500"`)
- [ ] styled-components
- [ ] Emotion

**Example Styling:**
```tsx
export const [ComponentName] = ({ requiredProp }: [ComponentName]Props) => {
  return (
    <div className="component-wrapper">
      <h2>{requiredProp}</h2>
      <button className="primary-button">Click me</button>
    </div>
  );
};
```

**Accessibility (WCAG 2.1 AA):**
- [ ] Semantic HTML (button, input, form, etc.)
- [ ] Proper heading hierarchy (h1 > h2 > h3, etc.)
- [ ] Form labels with `htmlFor` attribute
- [ ] Error messages linked with `aria-describedby`
- [ ] Focus visible (focus-visible CSS)
- [ ] Color not sole means of conveying info
- [ ] Text contrast ≥ 4.5:1

**Example with Accessibility:**
```tsx
<label htmlFor="email-input">Email Address *</label>
<input
  id="email-input"
  type="email"
  aria-required="true"
  aria-describedby={error ? "email-error" : undefined}
/>
{error && <span id="email-error" className="error">{error}</span>}
```

---

### Component 2: [ComponentName]

[Same structure as Component 1]

---

### Component 3: [ComponentName]

[Same structure as Component 1]

---

## 3. Custom Hooks

**Business logic extracted into reusable hooks:**

### Hook 1: `use[DomainLogic]`

**File Location:** `src/hooks/use[DomainLogic].ts`

**Purpose:**
[What problem does this hook solve? Why extract it?]

**Return Interface:**
```typescript
interface Use[DomainLogic]Return {
  data: DataType;
  isLoading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
  // Other methods...
}
```

**Implementation:**
```typescript
export const use[DomainLogic] = (): Use[DomainLogic]Return => {
  const [data, setData] = useState<DataType | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const refetch = useCallback(async () => {
    setIsLoading(true);
    try {
      const result = await api.fetchData();
      setData(result);
      setError(null);
    } catch (err) {
      setError(err as Error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    refetch();
  }, [refetch]);

  return { data, isLoading, error, refetch };
};
```

**Usage in Component:**
```typescript
const { data, isLoading, error } = use[DomainLogic]();

if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorMessage error={error} />;
return <div>{/* Render data */}</div>;
```

---

## 4. Data Fetching (React Query)

**Server State Management with React Query:**

### Query: `use[Entity]Query`

**Purpose:** Fetch [entity] data from API

**Implementation:**
```typescript
import { useQuery } from '@tanstack/react-query';
import * as api from '../services/api';

export const use[Entity]Query = (id?: string) => {
  return useQuery({
    queryKey: ['[entity]', id], // Unique key for caching
    queryFn: async () => {
      if (!id) throw new Error('ID required');
      return api.fetch[Entity](id);
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 10 * 60 * 1000, // 10 minutes
    enabled: !!id, // Only run if ID exists
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  });
};
```

**Usage:**
```typescript
const { data, isLoading, error } = use[Entity]Query(entityId);
```

### Mutation: `use[Action][Entity]Mutation`

**Purpose:** Create/Update/Delete [entity]

**Implementation:**
```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export const use[Action][Entity]Mutation = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: Create[Entity]Input) => {
      return api.[action][Entity](input);
    },
    onSuccess: (newEntity) => {
      // Invalidate related queries to refetch
      queryClient.invalidateQueries({ queryKey: ['[entity]s'] });

      // Or update cache directly
      queryClient.setQueryData(
        ['[entity]', newEntity.id],
        newEntity
      );
    },
    onError: (error) => {
      console.error('Operation failed:', error);
      // Show toast notification
    },
  });
};
```

**Usage:**
```typescript
const { mutate, isPending } = use[Action][Entity]Mutation();

const handleSubmit = (data: CreateInput) => {
  mutate(data);
};

<button disabled={isPending}>
  {isPending ? 'Loading...' : 'Submit'}
</button>
```

---

## 5. Global State Management (Zustand)

**Client-side state for features used across multiple pages:**

### Store: `[DomainName]Store`

**File Location:** `src/stores/[DomainName]Store.ts`

**Purpose:**
[What global state needs to be shared?]

**Implementation:**
```typescript
import { create } from 'zustand';

interface [DomainName]State {
  // State
  [entity]: [EntityType][];
  selectedId: string | null;
  filters: FilterOptions;

  // Actions
  set[Entity]s: (items: [EntityType][]) => void;
  select: (id: string) => void;
  updateFilters: (filters: Partial<FilterOptions>) => void;
}

export const use[DomainName]Store = create<[DomainName]State>((set) => ({
  // State
  [entity]: [],
  selectedId: null,
  filters: {},

  // Actions
  set[Entity]s: (items) => set({ [entity]: items }),
  select: (id) => set({ selectedId: id }),
  updateFilters: (filters) =>
    set((state) => ({
      filters: { ...state.filters, ...filters },
    })),
}));
```

**Usage in Components:**
```typescript
const { [entity], selectedId, select } = use[DomainName]Store();

return (
  <button onClick={() => select(item.id)}>
    {item.name}
  </button>
);
```

---

## 6. Services (API Clients & Utilities)

**API Integration:**

### File: `src/services/api.ts`

```typescript
import axios, { AxiosError } from 'axios';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 10000,
});

// Request interceptor for auth
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response.data,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Token expired, redirect to login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Entity endpoints
export const fetch[Entity] = (id: string) =>
  apiClient.get<[EntityType]>(`/[entities]/${id}`);

export const create[Entity] = (data: Create[Entity]Input) =>
  apiClient.post<[EntityType]>('/[entities]', data);

export const update[Entity] = (id: string, data: Update[Entity]Input) =>
  apiClient.put<[EntityType]>(`/[entities]/${id}`, data);

export const delete[Entity] = (id: string) =>
  apiClient.delete(`/[entities]/${id}`);
```

---

## 7. Testing Strategy

**Testing with Vitest + React Testing Library:**

### Unit Tests: Components

**File:** `src/components/atoms/Button.test.tsx`

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  it('should render with label', () => {
    render(<Button label="Click me" onClick={() => {}} />);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('should call onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button label="Click" onClick={handleClick} />);

    await userEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledOnce();
  });

  it('should be disabled when disabled prop is true', () => {
    render(<Button label="Click" onClick={() => {}} disabled={true} />);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

### Unit Tests: Hooks

**File:** `src/hooks/use[DomainLogic].test.ts`

```typescript
import { renderHook, act, waitFor } from '@testing-library/react';
import { use[DomainLogic] } from './use[DomainLogic]';

describe('use[DomainLogic]', () => {
  it('should return initial state', () => {
    const { result } = renderHook(() => use[DomainLogic]());
    expect(result.current.data).toBeNull();
    expect(result.current.isLoading).toBe(true);
  });

  it('should load data successfully', async () => {
    const { result } = renderHook(() => use[DomainLogic]());

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.data).toBeDefined();
    expect(result.current.error).toBeNull();
  });

  it('should handle errors', async () => {
    vi.mock('../services/api', () => ({
      fetchData: vi.fn().mockRejectedValue(new Error('API Error')),
    }));

    const { result } = renderHook(() => use[DomainLogic]());

    await waitFor(() => {
      expect(result.current.error).toBeDefined();
    });
  });
});
```

### Integration Tests

**File:** `src/pages/[Feature]Page.test.tsx`

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { [Feature]Page } from './[Feature]Page';
import * as api from '../services/api';

vi.mock('../services/api');

describe('[Feature]Page', () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  it('should display loaded data', async () => {
    vi.mocked(api.fetch[Entity]).mockResolvedValue({
      id: '1',
      name: 'Test',
    });

    render(
      <QueryClientProvider client={queryClient}>
        <[Feature]Page />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Test')).toBeInTheDocument();
    });
  });

  it('should handle form submission', async () => {
    vi.mocked(api.create[Entity]).mockResolvedValue({ id: '2', name: 'New' });

    render(
      <QueryClientProvider client={queryClient}>
        <[Feature]Page />
      </QueryClientProvider>
    );

    await userEvent.type(screen.getByLabelText(/name/i), 'New');
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(api.create[Entity]).toHaveBeenCalledWith({ name: 'New' });
    });
  });
});
```

### E2E Tests (Playwright/Cypress)

```typescript
import { test, expect } from '@playwright/test';

test.describe('[Feature] User Flow', () => {
  test('should complete [feature] workflow', async ({ page }) => {
    await page.goto('http://localhost:3000/[feature]');

    // Step 1: See initial state
    await expect(page.getByText(/welcome/i)).toBeVisible();

    // Step 2: Fill form
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'SecurePass123');

    // Step 3: Submit
    await page.click('button:has-text("Submit")');

    // Step 4: Verify success
    await expect(page.getByText(/success/i)).toBeVisible();
    await expect(page.url()).toContain('/[feature]/success');
  });
});
```

---

## 8. Performance Considerations

**Optimization Strategies:**

### Code Splitting
```typescript
import { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('./HeavyComponent'));

export const Page = () => (
  <Suspense fallback={<LoadingSpinner />}>
    <HeavyComponent />
  </Suspense>
);
```

### useMemo for Expensive Computations
```typescript
const expensiveList = useMemo(
  () => items.filter(item => item.category === selectedCategory)
    .sort((a, b) => a.name.localeCompare(b.name)),
  [items, selectedCategory]
);
```

### useCallback for Event Handlers
```typescript
const handleClick = useCallback((id: string) => {
  api.updateItem(id);
}, []);
```

### React.memo for List Items
```typescript
const ListItem = React.memo(({ item, onClick }: ListItemProps) => (
  <li onClick={() => onClick(item.id)}>{item.name}</li>
));
```

### Bundle Analysis
- Use `vite-plugin-visualizer` to analyze bundle size
- Target: < 200KB for critical path
- Lazy load routes, heavy libraries

---

## 9. Security Checklist

**Ref:** `../../references/security-rules.md` + `../../references/react-standards.md`

- [ ] **Auth:** JWT token stored in httpOnly cookie (not localStorage)
- [ ] **Input Validation:** All user inputs validated client-side + server-side
- [ ] **XSS Prevention:** No `dangerouslySetInnerHTML` without DOMPurify
- [ ] **CSRF:** CSRF token included in POST/PUT/DELETE requests
- [ ] **Content Security Policy:** CSP header set in backend (style-src, script-src, etc.)
- [ ] **Secrets:** No API keys, passwords, or secrets hardcoded (use env vars)
- [ ] **CORS:** Only allow trusted origins (avoid `*`)
- [ ] **HTTPS:** All requests to HTTPS (never HTTP in production)
- [ ] **Error Messages:** Generic error messages (don't expose system details)
- [ ] **Dependency Security:** Regular `npm audit` runs, no vulnerable packages

**Example DOMPurify Usage:**
```tsx
import DOMPurify from 'dompurify';

<div
  dangerouslySetInnerHTML={{
    __html: DOMPurify.sanitize(userGeneratedContent),
  }}
/>
```

---

## 10. Accessibility (WCAG 2.1 AA) Checklist

**Ref:** `../../references/react-standards.md`

- [ ] **Semantic HTML:** Use button, input, form, nav, main, aside, article
- [ ] **Heading Hierarchy:** h1 > h2 > h3, no skipped levels
- [ ] **Form Labels:** Every input has associated label with `htmlFor`
- [ ] **Error Messages:** Error text linked with `aria-describedby`
- [ ] **Focus Management:** Focus-visible visible, logical tab order
- [ ] **Focus Trap:** Modal traps focus inside, releases on close
- [ ] **ARIA Attributes:** `aria-required`, `aria-invalid`, `aria-live` where needed
- [ ] **Color Contrast:** Text/background ≥ 4.5:1 (normal) or 3:1 (large)
- [ ] **Icons:** Icon buttons have `aria-label` if no visible text
- [ ] **Alternative Text:** Images have meaningful `alt` text
- [ ] **Keyboard Navigation:** All interactive elements reachable via Tab
- [ ] **Screen Reader Testing:** Tested with NVDA/JAWS/VoiceOver

**Example Accessible Form:**
```tsx
<form onSubmit={handleSubmit}>
  <fieldset>
    <legend>Login Information</legend>

    <div className="form-group">
      <label htmlFor="email">Email Address *</label>
      <input
        id="email"
        type="email"
        required
        aria-required="true"
        aria-describedby={emailError ? "email-error" : undefined}
      />
      {emailError && (
        <span id="email-error" className="error">{emailError}</span>
      )}
    </div>

    <button type="submit" aria-busy={isLoading}>
      {isLoading ? 'Signing in...' : 'Sign In'}
    </button>
  </fieldset>
</form>
```

---

## 11. Environment Variables

**File:** `.env.example`

```
VITE_API_URL=https://api.example.com
VITE_API_TIMEOUT=10000
VITE_LOG_LEVEL=error
```

**Usage:**
```typescript
const apiUrl = import.meta.env.VITE_API_URL;

// Build-time only (Vite)
if (import.meta.env.DEV) {
  console.log('Development mode');
}
```

**Rules:**
- [ ] Never commit `.env` (add to `.gitignore`)
- [ ] Public URLs only (no secrets)
- [ ] Prefix with `VITE_` for Vite to expose
- [ ] Never use in string literal URLs (prevents injection)

---

## 12. Deployment Checklist

**Ref:** `../../references/security-rules.md` + `../../references/cloud-standards.md`

### 12.1 Pre-Build Checks

- [ ] TypeScript strict mode: `npx tsc --noEmit` (cero errores)
- [ ] Linting: `npm run lint` (cero warnings)
- [ ] Tests: `npm run test` (todos pasan)
- [ ] Security audit: `npm audit --audit-level=high` (sin vulnerabilidades HIGH/CRITICAL)

### 12.2 Build Configuration

```bash
# Build de producción
npm ci --prefer-offline
npm run build

# Verificar salida
ls -lah dist/
# index.html debe ser < 5KB (solo referencias a assets)
# Assets deben tener hash en el nombre: main.abc123.js
```

**Variables de entorno para el build:**

```bash
# .env.production.local - NO commitear
VITE_API_URL=https://api.[domain].com
VITE_LOG_LEVEL=error

# Verificar que NO hay secrets:
grep -r "API_KEY\|SECRET\|PASSWORD\|TOKEN" src/ --include="*.ts" --include="*.tsx"
# Si devuelve resultados: mover esos valores al backend
```

### 12.3 Bundle Analysis

```bash
npm run build -- --report
# O con vite-plugin-visualizer:
# Targets:
# - Total bundle < 500KB gzipped
# - Vendor chunk separado (React, libss de UI)
# - Lazy loading para rutas pesadas
```

**Estrategia de code splitting requerida:**

```typescript
// router con lazy loading
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Reports = lazy(() => import('./pages/Reports'));

export function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/reports" element={<Reports />} />
      </Routes>
    </Suspense>
  );
}
```

### 12.4 Cloud Deployment por Target

La especificación completa de infraestructura se genera con el skill `deployment-specs`.

#### Azure Static Web Apps

- [ ] `staticwebapp.config.json` presente en la raiz del proyecto de build
- [ ] Fallback routing configurado para SPA
- [ ] Custom domain y HTTPS configurados

```json
// staticwebapp.config.json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/images/*.{png,jpg,gif}", "/css/*"]
  },
  "responseOverrides": {
    "400": {"rewrite": "/index.html", "statusCode": 200},
    "404": {"rewrite": "/index.html", "statusCode": 200}
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN"
  }
}
```

#### AWS S3 + CloudFront

- [ ] Bucket S3 con acceso público bloqueado (via OAC)
- [ ] `index.html` sin cache headers (`Cache-Control: no-cache`)
- [ ] Assets con cache largo (`Cache-Control: public, max-age=31536000`)
- [ ] CloudFront invalidation: `aws cloudfront create-invalidation --paths "/*"`
- [ ] Custom error response: 404 → 200 `/index.html`

#### DigitalOcean App Platform (Static Site)

- [ ] `output_dir` configurado: `/dist` para Vite
- [ ] `error_document` apunta a `index.html` (para SPA routing)
- [ ] Build command verificado: `npm ci && npm run build`

### 12.5 Security Headers

Verificar que el servidor (o CDN) retorna:

```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; script-src 'self'; ...
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### 12.6 Performance Budget (Core Web Vitals)

| Métrica | Target | Herramienta |
|---------|--------|-------------|
| LCP (Largest Contentful Paint) | < 2.5s | Lighthouse |
| INP (Interaction to Next Paint) | < 200ms | Lighthouse |
| CLS (Cumulative Layout Shift) | < 0.1 | Lighthouse |
| TTFB (Time to First Byte) | < 800ms | WebPageTest |
| Bundle total (gzipped) | < 500KB | rollup-plugin-visualizer |

```bash
# Verificar con Lighthouse CLI
npm i -g @lhci/cli
lhci autorun --collect.url=https://[staging-url]
```

### 12.7 Accessibility Final Check

- [ ] `axe-core` ejecutado: `npx axe [staging-url] --tags wcag2a,wcag2aa`
- [ ] Prueba manual con teclado (Tab, Enter, Escape, flechas)
- [ ] Color contrast ratio: texto normal >= 4.5:1, texto grande >= 3:1

### 12.8 Post-Deployment

- [ ] App carga correctamente en la URL de producción
- [ ] Rutas de React Router funcionan al hacer refresh directo (SPA routing OK)
- [ ] Network tab: no requests a HTTP (todo HTTPS)
- [ ] Console tab: cero errores en producción
- [ ] API requests llegan al backend correcto (verificar VITE_API_URL)
- [ ] Sentry o equivalente recibiendo eventos (si configurado)

---

**Para la spec completa de deployment:** Usar el skill `deployment-specs`.
Ver: `../../skills/deployment-specs/SKILL.md`

---

**Document Owner:** [Frontend Lead]
**Last Updated:** [YYYY-MM-DD]
**Review Cycle:** Quarterly
