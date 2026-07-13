# Implementation Scaffolding: [ProjectName] (React)

## Overview

Choose your preferred folder structure below. All options include the same configuration files (vite.config.ts, package.json, tsconfig.json, testing setup).

---

# OPTION A: Atomic Design (Recommended for Medium-Large Projects)

Best for: Medium to large projects with many components, design systems, multi-team development.

## Directory Tree

```
[project-name]/
├── src/
│   ├── components/
│   │   ├── atoms/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Input.test.tsx
│   │   │   ├── Badge.tsx
│   │   │   └── Badge.css
│   │   ├── molecules/
│   │   │   ├── FormField.tsx
│   │   │   ├── FormField.test.tsx
│   │   │   ├── ProductCard.tsx
│   │   │   ├── ProductCard.test.tsx
│   │   │   ├── UserProfile.tsx
│   │   │   └── UserProfile.css
│   │   ├── organisms/
│   │   │   ├── Header.tsx
│   │   │   ├── Header.test.tsx
│   │   │   ├── ProductList.tsx
│   │   │   ├── ProductList.test.tsx
│   │   │   ├── Checkout.tsx
│   │   │   └── Checkout.css
│   │   └── pages/
│   │       ├── HomePage.tsx
│   │       ├── HomePage.test.tsx
│   │       ├── ProductPage.tsx
│   │       ├── CheckoutPage.tsx
│   │       └── NotFoundPage.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useAuth.test.ts
│   │   ├── useProducts.ts
│   │   ├── useCart.ts
│   │   └── useForm.ts
│   ├── services/
│   │   ├── api.ts
│   │   ├── productApi.ts
│   │   ├── orderApi.ts
│   │   └── authApi.ts
│   ├── types/
│   │   ├── domain.ts
│   │   ├── api.ts
│   │   └── forms.ts
│   ├── mocks/
│   │   ├── server.ts
│   │   └── handlers.ts
│   ├── stores/
│   │   └── authStore.ts
│   ├── utils/
│   │   ├── formatters.ts
│   │   └── validators.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── e2e/
│   ├── smoke.spec.ts
│   └── [feature].spec.ts
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.ts
├── vitest.config.ts
├── playwright.config.ts
├── .env.example
├── .gitignore
├── README.md
└── index.html
```

## Why Atomic Design?

- **Scalable:** Organize components by reusability level
- **Team-friendly:** Clear hierarchy makes it easy for multiple devs
- **Design System:** Perfect for building and maintaining component libraries
- **Documentation:** Self-documenting via folder structure

---

# OPTION B: Feature-Based (Domain-Driven Development)

Best for: Domain-driven projects with clear feature boundaries, easier parallel team work.

## Directory Tree

```
[project-name]/
├── src/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   └── LogoutButton.tsx
│   │   │   ├── hooks/
│   │   │   │   └── useAuth.ts
│   │   │   ├── services/
│   │   │   │   └── authApi.ts
│   │   │   ├── types/
│   │   │   │   └── auth.ts
│   │   │   └── store.ts
│   │   ├── products/
│   │   │   ├── components/
│   │   │   │   ├── ProductList.tsx
│   │   │   │   ├── ProductCard.tsx
│   │   │   │   └── ProductDetail.tsx
│   │   │   ├── hooks/
│   │   │   │   └── useProducts.ts
│   │   │   ├── services/
│   │   │   │   └── productApi.ts
│   │   │   ├── types/
│   │   │   │   └── product.ts
│   │   │   └── store.ts
│   │   └── orders/
│   │       ├── components/
│   │       ├── hooks/
│   │       ├── services/
│   │       └── types/
│   ├── shared/
│   │   ├── components/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── Navigation.tsx
│   │   ├── hooks/
│   │   │   └── useNotification.ts
│   │   ├── services/
│   │   │   └── http.ts
│   │   └── types/
│   │       └── common.ts
│   ├── mocks/
│   │   ├── server.ts
│   │   └── handlers.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── e2e/
│   ├── smoke.spec.ts
│   └── [feature].spec.ts
├── package.json
├── vite.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
├── .env.example
├── .gitignore
├── README.md
└── index.html
```

## Why Feature-Based?

- **Domain-focused:** Each feature self-contained
- **Parallel work:** Teams work on features independently
- **Clear boundaries:** Component, hook, service per feature
- **Easy to maintain:** Delete feature = delete folder

---

# OPTION C: Page-Based (Simple Structure)

Best for: Small to medium projects, straightforward page layouts.

## Directory Tree

```
[project-name]/
├── src/
│   ├── pages/
│   │   ├── HomePage.tsx
│   │   ├── ProductPage.tsx
│   │   ├── CheckoutPage.tsx
│   │   └── NotFoundPage.tsx
│   ├── components/
│   │   ├── shared/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── Navigation.tsx
│   │   ├── ProductCard.tsx
│   │   ├── ProductList.tsx
│   │   └── CheckoutForm.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useProducts.ts
│   │   └── useCart.ts
│   ├── services/
│   │   ├── api.ts
│   │   └── auth.ts
│   ├── types/
│   │   ├── domain.ts
│   │   └── api.ts
│   ├── mocks/
│   │   ├── server.ts
│   │   └── handlers.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── e2e/
│   ├── smoke.spec.ts
│   └── [feature].spec.ts
├── package.json
├── vite.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
├── .env.example
├── .gitignore
├── README.md
└── index.html
```

---

# OPTION D: Flat Structure (MVP/Prototype)

Best for: Prototypes, MVPs, quick experiments.

## Directory Tree

```
[project-name]/
├── src/
│   ├── components/
│   │   ├── Header.tsx
│   │   ├── ProductList.tsx
│   │   ├── ProductCard.tsx
│   │   └── CheckoutForm.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useProducts.ts
│   │   └── useCart.ts
│   ├── services/
│   │   ├── api.ts
│   │   └── auth.ts
│   ├── types/
│   │   └── domain.ts
│   ├── utils/
│   │   ├── formatters.ts
│   │   └── validators.ts
│   ├── mocks/
│   │   ├── server.ts
│   │   └── handlers.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── e2e/
│   └── smoke.spec.ts
├── package.json
├── vite.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
├── .env.example
├── .gitignore
├── README.md
└── index.html
```

---

# COMMON FILES (ALL STRUCTURES)

## package.json

```json
{
  "name": "[project-name]",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "coverage": "vitest --coverage",
    "lint": "eslint src --ext ts,tsx",
    "type-check": "tsc --noEmit",
    "e2e": "playwright test",
    "e2e:ui": "playwright test --ui",
    "e2e:smoke": "playwright test e2e/smoke.spec.ts"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@tanstack/react-query": "^5.32.0",
    "zustand": "^4.4.1",
    "axios": "^1.6.2"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@types/node": "^20.10.5",
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.8",
    "typescript": "^5.3.3",
    "vitest": "^1.1.0",
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.1.5",
    "@testing-library/user-event": "^14.5.1",
    "jsdom": "^23.0.1",
    "msw": "^2.0.11",
    "@playwright/test": "^1.40.1",
    "playwright": "^1.40.1",
    "tailwindcss": "^3.3.6",
    "postcss": "^8.4.32",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0"
  }
}
```

## vite.config.ts

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: process.env.VITE_API_URL || 'http://localhost:8080',
        changeOrigin: true,
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  }
})
```

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "esModuleInterop": true,
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "jsx": "react-jsx",
    "resolveJsonModule": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

## vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'dist/']
    }
  }
})
```

## playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

## src/test-setup.ts

```typescript
import '@testing-library/jest-dom'
import { expect, afterEach, vi } from 'vitest'
import { cleanup } from '@testing-library/react'
import { server } from './mocks/server'

// MSW
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

// RTL cleanup
afterEach(() => cleanup())
```

## src/mocks/server.ts

```typescript
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

## src/mocks/handlers.ts

```typescript
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/products', () => {
    return HttpResponse.json({
      data: [
        { id: '1', name: 'Product A', price: 99.99 },
        { id: '2', name: 'Product B', price: 149.99 },
      ]
    })
  }),

  http.post('/api/orders', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: '123', ...body }, { status: 201 })
  }),

  http.post('/api/auth/login', async ({ request }) => {
    const { email, password } = await request.json() as any
    if (email === 'test@example.com' && password === 'password') {
      return HttpResponse.json({
        token: 'valid-jwt-token',
        user: { id: '1', email }
      })
    }
    return HttpResponse.json({ error: 'Invalid credentials' }, { status: 401 })
  }),
]
```

## src/App.tsx

```typescript
import { useQuery } from '@tanstack/react-query'
import { useEffect } from 'react'

function App() {
  const { data, isLoading } = useQuery({
    queryKey: ['products'],
    queryFn: async () => {
      const res = await fetch('/api/products')
      return res.json()
    }
  })

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <nav className="max-w-7xl mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold">[ProjectName]</h1>
        </nav>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {isLoading ? (
          <p>Loading...</p>
        ) : (
          <div className="grid gap-4">
            {data?.data?.map((product: any) => (
              <div key={product.id} className="border p-4 rounded">
                <h2 className="text-lg font-semibold">{product.name}</h2>
                <p className="text-gray-600">${product.price}</p>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}

export default App
```

## src/main.tsx

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App.tsx'
import './index.css'

// Setup MSW in development
if (process.env.NODE_ENV === 'development') {
  const { worker } = await import('./mocks/browser')
  await worker.start()
}

const queryClient = new QueryClient()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>,
)
```

## tailwind.config.ts

```typescript
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

## .env.example

```env
VITE_API_URL=http://localhost:8080
VITE_LOG_LEVEL=info
```

## .gitignore

```
node_modules/
dist/
*.local
.env.local
.DS_Store
coverage/
.nyc_output/
dist-ssr/
*.log
```

## README.md

```markdown
# [ProjectName]

[Brief description of the React project]

## Project Structure

This project uses the **[SELECTED_STRUCTURE]** folder structure.

- Components, hooks, and services organized by...
- Easy to navigate and maintain
- Scalable as the project grows

## Setup

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env.local
# Edit .env.local with your API URL
```

### Development

```bash
# Start dev server
npm run dev
```

Visit `http://localhost:3000`

### Building

```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## Testing

```bash
# Run unit & integration tests
npm test

# With coverage
npm run coverage

# Watch mode
npm run test:watch

# UI mode
npm run test:ui
```

## E2E Testing

```bash
# Run E2E tests
npm run e2e

# UI mode
npm run e2e:ui

# Smoke tests only
npm run e2e:smoke
```

## Architecture

- **Components**: Reusable UI building blocks
- **Hooks**: Custom logic (useAuth, useProducts, etc.)
- **Services**: API communication (axios)
- **Types**: TypeScript interfaces
- **Mocks**: MSW for testing
- **Stores**: Zustand for client state

## First Steps

1. Open `src/App.tsx` and explore the starter code
2. Create new components using the structure pattern
3. Write tests alongside components (*.test.tsx)
4. Build features with type safety (strict TypeScript)

Happy building!
```

---

## Getting Started

1. **Choose your structure** (A, B, C, or D) based on project size
2. **Extract the scaffolding** to your machine
3. **Install dependencies:** `npm install`
4. **Start dev server:** `npm run dev`
5. **Begin building:** Open `src/App.tsx`

Your app will boot with:
- ✅ Vite (lightning-fast dev server)
- ✅ React 18 with TypeScript strict mode
- ✅ React Query for server state
- ✅ Zustand for client state (optional)
- ✅ Tailwind CSS for styling
- ✅ Vitest + RTL for unit tests
- ✅ Playwright for E2E tests
- ✅ MSW for API mocking
- ✅ CI/CD ready

Happy coding!
