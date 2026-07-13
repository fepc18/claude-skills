# Test Strategy: [Feature Name] (React)

## 1. Testing Pyramid

Recommended distribution for React applications:

```
          /\           E2E Tests (10%)
         /  \          └─ Critical user journeys
        /    \
       /      \        Integration Tests (30%)
      /        \       └─ Component flows + API mocking
     /          \
    /____________\     Unit Tests (60%)
    Components + Hooks
```

**Breakdown:**
- **Unit Tests (60%):** Components and custom hooks in isolation
- **Integration Tests (30%):** Multi-component user flows with MSW mocks
- **E2E Tests (10%):** Critical happy paths in real browser (Playwright)

---

## 2. Unit Tests — Components

Usando Vitest + React Testing Library. Focus: rendering, props, event handling.

```typescript
// src/components/[Component]/[Component].test.tsx
import { render, screen, userEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { [Component], [Component]Props } from './[Component]';

describe('[Component]', () => {
    it('renders with required props', () => {
        const props: [Component]Props = {
            [prop1]: 'value1',
            [prop2]: 'value2',
        };

        render(<[Component] {...props} />);

        expect(screen.getByRole('[role]', { name: '[expected name]' })).toBeInTheDocument();
    });

    it('renders with optional props', () => {
        const props: [Component]Props = {
            [prop1]: 'value1',
            [optional]: 'optional value',
        };

        render(<[Component] {...props} />);

        expect(screen.getByText('optional value')).toBeInTheDocument();
    });

    it('calls onSubmit with valid data', async () => {
        const user = userEvent.setup();
        const onSubmit = vi.fn();

        const props: [Component]Props = {
            [prop1]: 'initial',
            onSubmit,
        };

        render(<[Component] {...props} />);

        const input = screen.getByLabelText('[input label]');
        await user.clear(input);
        await user.type(input, 'new value');

        const button = screen.getByRole('button', { name: /submit/i });
        await user.click(button);

        expect(onSubmit).toHaveBeenCalledWith({
            [field]: 'new value',
        });
        expect(onSubmit).toHaveBeenCalledTimes(1);
    });

    it('shows validation error on empty submit', async () => {
        const user = userEvent.setup();

        const props: [Component]Props = {
            [required]: '',
        };

        render(<[Component] {...props} />);

        const submitButton = screen.getByRole('button', { name: /submit/i });
        await user.click(submitButton);

        expect(screen.getByText('[validation error message]')).toBeInTheDocument();
    });

    it('disables submit button while loading', async () => {
        const props: [Component]Props = {
            [prop1]: 'value',
            isLoading: true,
        };

        render(<[Component] {...props} />);

        const submitButton = screen.getByRole('button', { name: /submit/i });
        expect(submitButton).toBeDisabled();
    });

    it('displays error message on error state', () => {
        const props: [Component]Props = {
            [prop1]: 'value',
            error: '[Error message]',
        };

        render(<[Component] {...props} />);

        expect(screen.getByText('[Error message]')).toBeInTheDocument();
    });

    it('calls onChange prop on input change', async () => {
        const user = userEvent.setup();
        const onChange = vi.fn();

        const props: [Component]Props = {
            [prop1]: 'initial',
            onChange,
        };

        render(<[Component] {...props} />);

        const input = screen.getByLabelText('[label]');
        await user.type(input, 'x');

        expect(onChange).toHaveBeenCalled();
    });
});
```

---

## 3. Unit Tests — Custom Hooks

```typescript
// src/hooks/use[Feature]/use[Feature].test.ts
import { renderHook, act, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { use[Feature] } from './use[Feature]';

// Wrapper con QueryClient para hooks que usan React Query
const createWrapper = () => {
    const queryClient = new QueryClient({
        defaultOptions: {
            queries: { retry: false },
            mutations: { retry: false },
        },
    });

    return ({ children }: { children: React.ReactNode }) => (
        <QueryClientProvider client={queryClient}>
            {children}
        </QueryClientProvider>
    );
};

describe('use[Feature]', () => {
    it('returns initial state', () => {
        const { result } = renderHook(() => use[Feature](), {
            wrapper: createWrapper(),
        });

        expect(result.current.[state]).toBe([initialValue]);
        expect(result.current.[loading]).toBe(false);
        expect(result.current.[error]).toBeUndefined();
    });

    it('updates state on [action]', async () => {
        const { result } = renderHook(() => use[Feature](), {
            wrapper: createWrapper(),
        });

        act(() => {
            result.current.[action]([args]);
        });

        await waitFor(() => {
            expect(result.current.[state]).toBe([expectedValue]);
        });
    });

    it('sets error on [action] failure', async () => {
        const { result } = renderHook(() => use[Feature](), {
            wrapper: createWrapper(),
        });

        act(() => {
            result.current.[action]([invalidArgs]);
        });

        await waitFor(() => {
            expect(result.current.[error]).toBeDefined();
        });
    });

    it('clears error when retrying successful action', async () => {
        const { result } = renderHook(() => use[Feature](), {
            wrapper: createWrapper(),
        });

        // Fail first
        act(() => {
            result.current.[action]([invalidArgs]);
        });

        await waitFor(() => {
            expect(result.current.[error]).toBeDefined();
        });

        // Then succeed
        act(() => {
            result.current.[action]([validArgs]);
        });

        await waitFor(() => {
            expect(result.current.[error]).toBeUndefined();
            expect(result.current.[state]).toBe([expectedValue]);
        });
    });
});
```

---

## 4. Integration Tests — User Flows

```typescript
// src/features/[Feature]/[Feature].integration.test.tsx
import { render, screen, userEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, beforeAll, afterEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { server } from '../../mocks/server';
import { http, HttpResponse } from 'msw';
import { [Feature]Page } from './[Feature]Page';

// MSW server setup (beforeAll in vitest.config.ts)

const createWrapper = () => {
    const queryClient = new QueryClient({
        defaultOptions: { queries: { retry: false } },
    });

    return ({ children }: { children: React.ReactNode }) => (
        <QueryClientProvider client={queryClient}>
            {children}
        </QueryClientProvider>
    );
};

describe('[Feature] User Flow Integration', () => {
    afterEach(() => {
        // Reset MSW handlers after each test
        server.resetHandlers();
    });

    it('completes [happy path flow]', async () => {
        const user = userEvent.setup();

        // Mock successful API response
        server.use(
            http.post('/api/[entities]', async ({ request }) => {
                const body = await request.json() as Record<string, string>;
                return HttpResponse.json({
                    id: '123',
                    ...body,
                }, { status: 201 })
            })
        );

        render(<[Feature]Page />, { wrapper: createWrapper() });

        // User fills form
        const nameInput = screen.getByLabelText('[field label]');
        await user.type(nameInput, 'Test Value');

        const emailInput = screen.getByLabelText('[email label]');
        await user.type(emailInput, 'test@example.com');

        // User submits form
        const submitButton = screen.getByRole('button', { name: /submit/i });
        await user.click(submitButton);

        // Verify success message appears
        await waitFor(() => {
            expect(screen.getByText('[success message]')).toBeInTheDocument();
        });

        // Verify redirect or state change
        expect(screen.queryByText('[error message]')).not.toBeInTheDocument();
    });

    it('shows error when API fails', async () => {
        const user = userEvent.setup();

        // Mock failed API response
        server.use(
            http.post('/api/[entities]', () => {
                return HttpResponse.json(
                    { error: 'Server error' },
                    { status: 500 }
                );
            })
        );

        render(<[Feature]Page />, { wrapper: createWrapper() });

        const input = screen.getByLabelText('[field label]');
        await user.type(input, 'value');

        const submitButton = screen.getByRole('button', { name: /submit/i });
        await user.click(submitButton);

        await waitFor(() => {
            expect(screen.getByText('[error message]')).toBeInTheDocument();
        });
    });

    it('shows validation error before API call', async () => {
        const user = userEvent.setup();

        // Don't even mock the API - validation should fail first
        render(<[Feature]Page />, { wrapper: createWrapper() });

        const submitButton = screen.getByRole('button', { name: /submit/i });
        await user.click(submitButton);

        // Validation error appears
        expect(screen.getByText('[validation error]')).toBeInTheDocument();
    });

    it('handles loading state during API call', async () => {
        const user = userEvent.setup();

        server.use(
            http.post('/api/[entities]', async () => {
                // Simulate slow network
                await new Promise(resolve => setTimeout(resolve, 100));
                return HttpResponse.json({ id: '123' }, { status: 201 });
            })
        );

        render(<[Feature]Page />, { wrapper: createWrapper() });

        const input = screen.getByLabelText('[field label]');
        await user.type(input, 'value');

        const submitButton = screen.getByRole('button', { name: /submit/i });
        await user.click(submitButton);

        // Button should be disabled/show loading state
        expect(submitButton).toBeDisabled();

        // Then success appears
        await waitFor(() => {
            expect(screen.getByText('[success]')).toBeInTheDocument();
        });
    });

    it('prevents duplicate submissions', async () => {
        const user = userEvent.setup();
        let callCount = 0;

        server.use(
            http.post('/api/[entities]', async () => {
                callCount++;
                return HttpResponse.json({ id: '123' }, { status: 201 });
            })
        );

        render(<[Feature]Page />, { wrapper: createWrapper() });

        const input = screen.getByLabelText('[field label]');
        await user.type(input, 'value');

        const submitButton = screen.getByRole('button', { name: /submit/i });

        // Click multiple times quickly
        await user.click(submitButton);
        await user.click(submitButton);
        await user.click(submitButton);

        await waitFor(() => {
            // Should only call API once due to button disabled state
            expect(callCount).toBe(1);
        });
    });
});
```

---

## 5. MSW Mock Setup

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
    // GET list
    http.get('/api/[entities]', () => {
        return HttpResponse.json({
            data: [
                {
                    id: '1',
                    name: '[Entity] 1',
                    email: 'entity1@example.com',
                },
                {
                    id: '2',
                    name: '[Entity] 2',
                    email: 'entity2@example.com',
                },
            ],
        });
    }),

    // POST create
    http.post('/api/[entities]', async ({ request }) => {
        const body = await request.json() as Record<string, unknown>;

        // Simple validation
        if (!body.name || !body.email) {
            return HttpResponse.json(
                { error: 'Missing required fields' },
                { status: 400 }
            );
        }

        return HttpResponse.json({
            id: 'new-uuid',
            ...body,
        }, { status: 201 });
    }),

    // GET single
    http.get('/api/[entities]/:id', ({ params }) => {
        if (params.id === 'invalid') {
            return HttpResponse.json(
                { error: 'Not found' },
                { status: 404 }
            );
        }

        return HttpResponse.json({
            id: params.id,
            name: '[Entity] ' + params.id,
            email: `entity${params.id}@example.com`,
        });
    }),

    // PUT update
    http.put('/api/[entities]/:id', async ({ params, request }) => {
        const body = await request.json();

        return HttpResponse.json({
            id: params.id,
            ...body,
            updatedAt: new Date().toISOString(),
        });
    }),

    // DELETE
    http.delete('/api/[entities]/:id', () => {
        return HttpResponse.json({}, { status: 204 });
    }),

    // Auth endpoint
    http.post('/api/auth/login', async ({ request }) => {
        const body = await request.json() as Record<string, unknown>;

        if (body.email === 'test@example.com' && body.password === 'password123') {
            return HttpResponse.json({
                token: 'valid.jwt.token',
                user: { id: '1', email: 'test@example.com' },
            });
        }

        return HttpResponse.json(
            { error: 'Invalid credentials' },
            { status: 401 }
        );
    }),
];

// src/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        globals: true,
        environment: 'jsdom',
        setupFiles: ['./src/test-setup.ts'],
    },
});

// src/test-setup.ts
import { server } from './mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

---

## 6. E2E Tests — Playwright

```typescript
// e2e/[feature].spec.ts
import { test, expect } from '@playwright/test';

test.describe('[Feature]', () => {
    test.beforeEach(async ({ page }) => {
        // Navigate to the feature page
        await page.goto('/[route]');
        // Wait for page to be fully loaded
        await page.waitForLoadState('networkidle');
    });

    test('happy path: [action]', async ({ page }) => {
        // Fill form
        await page.getByLabel('[field label]').fill('Test Value');
        await page.getByLabel('[email label]').fill('test@example.com');

        // Submit
        await page.getByRole('button', { name: /submit/i }).click();

        // Verify success
        await expect(page.getByText('[success message]')).toBeVisible();

        // Verify navigation or redirect
        await expect(page).toHaveURL('/[success-route]');
    });

    test('validation error on empty fields', async ({ page }) => {
        // Try to submit without filling required fields
        await page.getByRole('button', { name: /submit/i }).click();

        // Verify error messages appear
        await expect(page.getByText('[validation error]')).toBeVisible();

        // Should still be on same page
        await expect(page).toHaveURL('/[route]');
    });

    test('handles API errors gracefully', async ({ page }) => {
        // Intercept and mock API to return error
        await page.route('/api/[entities]', route => {
            route.abort('failed');
        });

        await page.getByLabel('[field label]').fill('Test');
        await page.getByRole('button', { name: /submit/i }).click();

        // Should show error message
        await expect(page.getByText(/error|failed/i)).toBeVisible();
    });

    test('loading state during submission', async ({ page }) => {
        // Slow down network to see loading state
        await page.route('/api/[entities]', route => {
            setTimeout(() => route.continue(), 500);
        });

        await page.getByLabel('[field label]').fill('Test');
        const button = page.getByRole('button', { name: /submit/i });

        await button.click();

        // Button should be disabled while loading
        await expect(button).toBeDisabled();

        // Wait for success
        await expect(page.getByText('[success]')).toBeVisible({ timeout: 5000 });
    });

    test('keyboard navigation', async ({ page }) => {
        // Start at first field
        const firstInput = page.getByLabel('[field label]');
        await firstInput.focus();
        expect(firstInput).toBeFocused();

        // Tab to next field
        await page.keyboard.press('Tab');
        const secondInput = page.getByLabel('[email label]');
        expect(secondInput).toBeFocused();

        // Tab to button
        await page.keyboard.press('Tab');
        const button = page.getByRole('button', { name: /submit/i });
        expect(button).toBeFocused();

        // Enter to submit
        await page.keyboard.press('Enter');

        // Verify submission worked
        await expect(page.getByText('[success]')).toBeVisible();
    });

    test('is responsive on mobile', async ({ page }) => {
        // Set mobile viewport
        await page.setViewportSize({ width: 375, height: 667 });

        await page.getByLabel('[field label]').fill('Test');

        // Form should still be usable on mobile
        await expect(page.getByRole('button', { name: /submit/i })).toBeVisible();
        await expect(page.getByRole('button', { name: /submit/i })).toHaveCSS('width', /.*px/);
    });
});
```

---

## 7. Accessibility Tests

```typescript
// src/components/[Component]/[Component].a11y.test.tsx
import { render } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { axe, toHaveNoViolations } from 'jest-axe';
import { [Component] } from './[Component]';

expect.extend(toHaveNoViolations);

describe('[Component] - Accessibility', () => {
    it('has no WCAG 2.1 AA violations', async () => {
        const { container } = render(
            <[Component]
                [prop1]="value"
                [prop2]="value"
            />
        );

        const results = await axe(container, {
            rules: {
                'color-contrast': { enabled: true },
                'image-alt': { enabled: true },
            },
        });

        expect(results).toHaveNoViolations();
    });

    it('has semantic HTML structure', () => {
        const { container } = render(
            <[Component] [prop]="value" />
        );

        // Check for semantic elements
        expect(container.querySelector('form')).toBeInTheDocument();
        expect(container.querySelector('label')).toBeInTheDocument();
        expect(container.querySelector('button')).toBeInTheDocument();
    });

    it('has proper heading hierarchy', () => {
        const { container } = render(
            <[Component] [prop]="value" />
        );

        const h1 = container.querySelector('h1');
        const h2 = container.querySelectorAll('h2');

        expect(h1).toBeInTheDocument();
        expect(h2.length).toBeGreaterThan(0);
    });

    it('has associated labels for form inputs', () => {
        const { container } = render(
            <[Component] [prop]="value" />
        );

        const inputs = container.querySelectorAll('input, textarea, select');
        inputs.forEach(input => {
            const label = container.querySelector(`label[for="${input.id}"]`);
            expect(label).toBeInTheDocument();
        });
    });

    it('provides error messages linked to fields', () => {
        const { container } = render(
            <[Component] error="[Field error]" />
        );

        const errorMessage = container.querySelector('[role="alert"]');
        expect(errorMessage).toBeInTheDocument();
        expect(errorMessage).toHaveTextContent('[Field error]');
    });
});

// e2e/accessibility.spec.ts (in Playwright)
import { test, expect } from '@playwright/test';
import { injectAxe, checkA11y } from 'axe-playwright';

test('page has no accessibility violations', async ({ page }) => {
    await page.goto('/[feature-page]');
    await injectAxe(page);
    await checkA11y(page, null, {
        detailedReport: true,
        detailedReportOptions: {
            html: true,
        },
    });
});
```

---

## 8. Security Test Cases

```typescript
// src/components/[Component]/[Component].security.test.tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import DOMPurify from 'dompurify';
import { [Component] } from './[Component]';

describe('[Component] - Security', () => {
    it('sanitizes user input before rendering (XSS prevention)', async () => {
        const xssPayload = '<script>alert("xss")</script>';

        render(
            <[Component]
                [userContentProp]={xssPayload}
            />
        );

        // Script tag should not be in DOM
        expect(document.querySelector('script')).not.toBeInTheDocument();

        // Content should be visible but script tags removed
        const display = screen.queryByText(xssPayload);
        if (display) {
            // DOMPurify removed the script tags
            expect(display.innerHTML).not.toContain('<script>');
        }
    });

    it('does not expose sensitive data in DOM or localStorage', () => {
        const sensitiveUser = {
            id: '123',
            email: 'user@test.com',
            password: 'super-secret-password',
            apiKey: 'sk_live_123456789',
        };

        render(<[Component] user={sensitiveUser} />);

        // Password should not be in DOM
        expect(document.body.innerHTML).not.toContain(sensitiveUser.password);

        // API key should not be in DOM
        expect(document.body.innerHTML).not.toContain(sensitiveUser.apiKey);

        // localStorage should not contain sensitive data
        expect(localStorage.getItem('user-password')).toBeNull();
        expect(localStorage.getItem('api-key')).toBeNull();
    });

    it('sanitizes URLs to prevent javascript: protocol', () => {
        const maliciousUrl = 'javascript:alert("xss")';

        render(
            <[Component]
                linkUrl={maliciousUrl}
            />
        );

        const link = screen.getByRole('link') as HTMLAnchorElement;
        expect(link.href).not.toContain('javascript:');
    });

    it('properly escapes HTML attributes', () => {
        const userInput = '"/><script>alert("xss")</script><div class="';

        render(
            <[Component]
                title={userInput}
            />
        );

        const element = screen.getByTitle('');
        // Attribute should be properly escaped
        expect(element.getAttribute('title')).not.toContain('script');
    });

    it('enforces CSRF token for form submissions', () => {
        render(<[Component] />);

        const form = document.querySelector('form');
        const csrfToken = form?.querySelector('input[name="_csrf"]');

        expect(csrfToken).toBeInTheDocument();
        expect(csrfToken).toHaveValue(/^[a-z0-9]+$/i);
    });

    it('never exposes JWT tokens in localStorage (use secure cookies)', () => {
        // This test verifies that tokens are not stored in localStorage
        const tokenInLocalStorage = localStorage.getItem('auth_token');
        const tokenInSessionStorage = sessionStorage.getItem('auth_token');

        expect(tokenInLocalStorage).toBeNull();
        expect(tokenInSessionStorage).toBeNull();

        // Tokens should only be in httpOnly cookies
        // (cannot be directly tested from browser JS, but verified via cookie inspection)
    });
});
```

---

## 9. Test Data / Fixtures

```typescript
// src/test-utils/factories.ts
export interface [Entity] {
    id: string;
    name: string;
    email: string;
    createdAt: Date;
}

/**
 * Create a test [Entity] with default values
 */
export const create[Entity] = (overrides?: Partial<[Entity]>): [Entity] => ({
    id: 'test-id-1',
    name: 'Test [Entity]',
    email: 'test@example.com',
    createdAt: new Date('2026-01-01'),
    ...overrides,
});

/**
 * Create a list of test [Entity] instances
 */
export const create[Entity]List = (count: number, overrides?: Partial<[Entity]>): [Entity][] =>
    Array.from({ length: count }, (_, i) =>
        create[Entity]({
            id: `test-id-${i + 1}`,
            name: `Test [Entity] ${i + 1}`,
            email: `test${i + 1}@example.com`,
            ...overrides,
        })
    );

/**
 * Create an [Entity] with a specific email
 */
export const create[Entity]WithEmail = (email: string): [Entity] =>
    create[Entity]({ email });

/**
 * Create multiple [Entity] instances with sequential emails
 */
export const create[Entity]WithEmails = (...emails: string[]): [Entity][] =>
    emails.map((email, i) =>
        create[Entity]({
            id: `test-id-${i + 1}`,
            email,
        })
    );

// Usage in tests:
// const user = create[Entity]();
// const users = create[Entity]List(5);
// const customUser = create[Entity]({ name: 'Custom Name' });
// const withEmail = create[Entity]WithEmail('custom@test.com');
```

---

## 10. Coverage Targets

| Area | Target | Notes |
|------|--------|-------|
| Components (UI) | 80% | Button logic, form handling, conditionals |
| Custom Hooks | 90% | Business logic must be thoroughly tested |
| Utilities/Helpers | 95% | Pure functions should have near 100% |
| Critical User Flows | 100% | Payment, auth, data deletion flows |
| Accessibility | 100% (axe audit) | No color contrast, alt text, ARIA violations |
| **Global** | **80%** | Pre-merge requirement |

### Coverage Commands

```bash
# Run with coverage
npx vitest run --coverage

# View HTML report
open coverage/index.html

# View with NYC reporter
npx vitest run --coverage --reporter=html

# Fail if coverage below threshold
npx vitest run --coverage --coverage.lines=80 --coverage.functions=80
```

---

## 11. CI/CD Test Integration

Orden de ejecución en pipeline (GitHub Actions o Azure DevOps):

```yaml
# .github/workflows/test.yml

# Stage 1: Type Check (PRs, all branches)
- name: Type Check
  run: npx tsc --noEmit

# Stage 2: Lint (PRs, all branches)
- name: Lint
  run: npm run lint

# Stage 3: Unit + Integration Tests (PRs, all branches)
- name: Run Unit & Integration Tests
  run: npx vitest run

# Stage 4: Coverage Check (bloqueante)
- name: Check Coverage
  run: |
    npx vitest run --coverage
    COVERAGE=$(npx c8 report-lines | grep lines | awk '{print $2}' | sed 's/%//')
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 80% threshold"
      exit 1
    fi

# Stage 5: Accessibility Audit (PRs)
- name: Accessibility Audit
  run: npx axe --exit

# Stage 6: Security Audit (PRs)
- name: Security Audit
  run: npm audit --audit-level=high

# Stage 7: E2E Tests (merge to main, staging environment)
- name: Run E2E Tests
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: npx playwright test
  env:
    APP_URL: ${{ secrets.STAGING_URL }}

# Stage 8: Security Scanning (PRs)
- name: Security Scanning
  run: npx semgrep scan --config=p/security-audit
  continue-on-error: true
```

---

## 12. Smoke Test Suite (para deployment-specs)

Suite de verificación ejecutada post-deployment en staging/producción.

```typescript
// e2e/smoke.spec.ts
// Run these tests immediately after deployment as final validation

import { test, expect } from '@playwright/test';

test.describe('Smoke Tests', () => {
    const appURL = process.env.APP_URL || 'http://localhost:3000';

    test.beforeEach(async ({ page }) => {
        // Set a reasonable timeout for smoke tests
        page.setDefaultTimeout(10000);
    });

    test('app loads and renders root route', async ({ page }) => {
        await page.goto(appURL);

        // Check page title
        await expect(page).toHaveTitle(/[Expected Title]/);

        // Check main content is visible
        const main = page.locator('main');
        await expect(main).toBeVisible();
    });

    test('API health endpoint accessible', async ({ request }) => {
        const response = await request.get(`${appURL}/api/health`);

        expect(response.ok()).toBeTruthy();
        expect(response.status()).toBe(200);

        const data = await response.json();
        expect(data.status).toBe('ok');
    });

    test('navigation works and routes are accessible', async ({ page }) => {
        await page.goto(appURL);

        // Click navigation link
        const navLink = page.getByRole('link', { name: /[nav link]/i });
        await expect(navLink).toBeVisible();
        await navLink.click();

        // Should navigate to expected route
        await expect(page).toHaveURL(/\/[expected-route]/);
    });

    test('authentication flow starts (login page loads)', async ({ page }) => {
        await page.goto(`${appURL}/login`);

        // Login form should be present
        const loginForm = page.locator('form');
        await expect(loginForm).toBeVisible();

        const emailInput = page.getByLabel(/email/i);
        const passwordInput = page.getByLabel(/password/i);

        await expect(emailInput).toBeVisible();
        await expect(passwordInput).toBeVisible();
    });

    test('error pages are accessible (404 page)', async ({ page }) => {
        await page.goto(`${appURL}/this-route-does-not-exist`);

        // 404 page should be shown
        await expect(page.getByText(/not found|404/i)).toBeVisible();
    });

    test('CSS and JavaScript are loaded', async ({ page }) => {
        await page.goto(appURL);

        // Check that at least one stylesheet is loaded
        const stylesheets = page.locator('link[rel="stylesheet"]');
        const count = await stylesheets.count();
        expect(count).toBeGreaterThan(0);

        // Check that scripts are loaded
        const scripts = page.locator('script');
        const scriptCount = await scripts.count();
        expect(scriptCount).toBeGreaterThan(0);
    });

    test('images load without 404 errors', async ({ page, request }) => {
        await page.goto(appURL);

        // Collect all image URLs
        const images = page.locator('img');
        const count = await images.count();

        if (count > 0) {
            for (let i = 0; i < Math.min(count, 5); i++) {
                const src = await images.nth(i).getAttribute('src');
                if (src && src.startsWith('http')) {
                    const response = await request.get(src);
                    expect(response.ok()).toBeTruthy();
                }
            }
        }
    });

    test('API endpoint responds within acceptable time', async ({ request }) => {
        const start = Date.now();
        await request.get(`${appURL}/api/[entities]`);
        const elapsed = Date.now() - start;

        // Should respond within 5 seconds
        expect(elapsed).toBeLessThan(5000);
    });

    test('no console errors on page load', async ({ page }) => {
        const errors: string[] = [];

        page.on('console', msg => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });

        await page.goto(appURL);
        await page.waitForLoadState('networkidle');

        // No critical errors should be logged
        const criticalErrors = errors.filter(e =>
            !e.includes('Unexpected token') // Parser errors might be from third-party
        );
        expect(criticalErrors).toHaveLength(0);
    });
});

// Run with: npx playwright test e2e/smoke.spec.ts
// Typically run after deployment in staging/prod as final validation
```

---

## 13. Test Checklist

Use this checklist before marking the feature as testable:

- [ ] **Unit Tests**
  - [ ] All components have render tests
  - [ ] Props interfaces typed (no `any`)
  - [ ] Event handlers tested (onClick, onChange, onSubmit)
  - [ ] Conditional rendering tested (if/else branches)
  - [ ] Error states tested
  - [ ] Loading states tested

- [ ] **Custom Hooks**
  - [ ] Initial state tested
  - [ ] State updates tested
  - [ ] Error states tested
  - [ ] Used with QueryClientProvider wrapper for React Query hooks

- [ ] **Integration Tests**
  - [ ] Multi-component user flows tested
  - [ ] MSW handlers cover all API endpoints
  - [ ] API success paths tested
  - [ ] API error paths tested
  - [ ] Loading state during API call tested
  - [ ] Form validation + submission tested

- [ ] **E2E Tests**
  - [ ] Happy path journey works end-to-end
  - [ ] Validation error handling tested
  - [ ] Navigation works
  - [ ] Keyboard navigation tested
  - [ ] Mobile responsiveness tested

- [ ] **Accessibility**
  - [ ] axe-core scan runs without violations
  - [ ] Form labels associated with inputs
  - [ ] Color contrast meets WCAG AA
  - [ ] Keyboard navigation works
  - [ ] Screen reader friendly (semantic HTML)

- [ ] **Security**
  - [ ] User input sanitized (XSS prevention with DOMPurify)
  - [ ] No sensitive data in localStorage
  - [ ] No JWT tokens in localStorage (use httpOnly cookies)
  - [ ] Passwords/API keys not rendered
  - [ ] URLs escaped
  - [ ] HTML attributes escaped

- [ ] **Test Data**
  - [ ] Factory functions created for all entities
  - [ ] Factories have functional options for customization
  - [ ] Test fixtures consistent

- [ ] **Coverage**
  - [ ] `npx vitest run --coverage` shows >= 80% global
  - [ ] Components: >= 80%
  - [ ] Custom hooks: >= 90%
  - [ ] Critical flows: 100%
  - [ ] Coverage report generated

- [ ] **CI/CD Integration**
  - [ ] Type check: `npx tsc --noEmit` passes
  - [ ] Lint: `npm run lint` passes
  - [ ] Tests: `npx vitest run` passes
  - [ ] Coverage: >= 80% enforced
  - [ ] Accessibility audit runs
  - [ ] Security audit runs
  - [ ] E2E tests run on merge to main

- [ ] **Smoke Tests**
  - [ ] App loads on root route
  - [ ] Health endpoint accessible (`/api/health`)
  - [ ] Navigation works
  - [ ] Login page loads
  - [ ] 404 page works
  - [ ] Images load
  - [ ] No console errors
  - [ ] API responds within SLA

- [ ] **Documentation**
  - [ ] Test strategy documented (this file)
  - [ ] Run instructions provided (`npx vitest run`)
  - [ ] Coverage targets documented
  - [ ] MSW handlers documented
  - [ ] E2E test patterns documented

---

**Next Step:** After test strategy is approved, proceed to Stage 8: **Deployment Specifications** where the smoke test suite defined here will be integrated into CI/CD pipelines for Azure, AWS, or DigitalOcean.
