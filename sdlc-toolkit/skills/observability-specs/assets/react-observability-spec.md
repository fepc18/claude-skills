# Observability Specs: [ProjectName] (React)

## 1. Frontend Observability Strategy

### Why Frontend Observability Matters

Frontend errors are invisible to backend monitoring — users experience failures silently:
- JavaScript errors crash silently
- Network timeouts without visibility
- Performance degradation undetected
- User navigation flows unmeasured

### Frontend Observability Pillars

```
┌──────────────────────────────────────────────────────┐
│          FRONTEND OBSERVABILITY PILLARS              │
├──────────────────────────────────────────────────────┤
│                                                       │
│  1. ERROR TRACKING          2. PERFORMANCE METRICS   │
│     ├─ Unhandled errors        ├─ Page load time    │
│     ├─ React errors            ├─ Core Web Vitals   │
│     ├─ API failures            ├─ Interaction speed │
│     └─ Network errors          └─ Resource timing   │
│                                                       │
│  3. USER ANALYTICS          4. TRACING               │
│     ├─ Page views             ├─ Request traces     │
│     ├─ User flows             ├─ Component render   │
│     ├─ Feature usage          └─ Network timing    │
│     └─ Funnels (anonymous)                          │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### Recommended Stack

- **Error Reporting:** Sentry / Azure Application Insights / DataDog
- **Performance Metrics:** Google Analytics 4 / Mixpanel (anonymous)
- **Core Web Vitals:** web-vitals library + custom instrumentation
- **Tracing:** OpenTelemetry Web SDK + Backend correlation

---

## 2. Error Boundary Implementation

React Error Boundary to catch unhandled component errors:

```tsx
// src/components/error-boundary/ErrorBoundary.tsx
import React, { ReactNode } from 'react';
import * as Sentry from '@sentry/react';

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log to error tracking service
    Sentry.captureException(error, {
      contexts: {
        react: {
          componentStack: errorInfo.componentStack,
        },
      },
    });

    // Log to console in development
    if (process.env.NODE_ENV === 'development') {
      console.error('Error caught by boundary:', error, errorInfo);
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="max-w-md w-full bg-white rounded-lg shadow p-6">
            <h1 className="text-2xl font-bold text-red-600 mb-4">Something went wrong</h1>
            <p className="text-gray-600 mb-4">
              We've been notified about this error. Please refresh the page to try again.
            </p>
            {process.env.NODE_ENV === 'development' && (
              <details className="bg-gray-100 p-3 rounded mt-4 text-sm">
                <summary className="cursor-pointer font-mono font-bold">Error Details</summary>
                <pre className="mt-2 whitespace-pre-wrap break-words text-xs">
                  {this.state.error?.toString()}
                </pre>
              </details>
            )}
            <button
              onClick={() => window.location.href = '/'}
              className="mt-4 w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700"
            >
              Go Home
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default Sentry.withErrorBoundary(ErrorBoundary, {
  fallback: <div>An error occurred</div>,
});
```

### Usage in App

```tsx
// src/App.tsx
import ErrorBoundary from './components/error-boundary/ErrorBoundary';

function App() {
  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <div className="min-h-screen bg-white">
          {/* Your app routes */}
        </div>
      </QueryClientProvider>
    </ErrorBoundary>
  );
}

export default App;
```

---

## 3. React Query Error Handling

Error callbacks in React Query for centralized error tracking:

```tsx
// src/hooks/useApi.ts
import { UseQueryOptions, useQuery } from '@tanstack/react-query';
import * as Sentry from '@sentry/react';

function useApi<TData>(
  key: string[],
  fn: () => Promise<TData>,
  options?: Omit<UseQueryOptions<TData, Error>, 'queryKey' | 'queryFn'>
) {
  return useQuery({
    queryKey: key,
    queryFn: fn,
    retry: 2, // Retry failed requests twice
    retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000), // Exponential backoff
    onError: (error) => {
      // Log to error tracking
      Sentry.captureException(error, {
        tags: {
          query_key: key.join('.'),
          error_type: 'react_query_failure',
        },
      });

      // Log specific error types
      if (error instanceof TypeError) {
        console.error('[Network Error]', key, error.message);
      } else {
        console.error('[API Error]', key, error.message);
      }
    },
    ...options,
  });
}

// Usage
function ProductList() {
  const { data, isLoading, error } = useApi(
    ['products'],
    () => fetch('/api/products').then(r => r.json()),
    {
      onSuccess: (data) => {
        console.info('[Success]', 'products loaded', data.length);
      },
    }
  );

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  return <div>{data?.map(p => <div key={p.id}>{p.name}</div>)}</div>;
}
```

---

## 4. Core Web Vitals Tracking

Measure and track Google's Core Web Vitals using web-vitals library:

```tsx
// src/utils/web-vitals.ts
import { getCLS, getFID, getFCP, getLCP, getTTFB, Metric } from 'web-vitals';
import * as Sentry from '@sentry/react';

export function trackWebVitals() {
  // Largest Contentful Paint (LCP) — target: < 2.5s
  getLCP((metric: Metric) => {
    console.log('LCP:', metric.value);
    if (metric.value > 2.5) {
      Sentry.captureMessage('LCP threshold exceeded', {
        level: 'warning',
        contexts: { metric: { name: 'LCP', value: metric.value } },
      });
    }
  });

  // Interaction to Next Paint (INP) — target: < 200ms
  getFID((metric: Metric) => {
    console.log('FID:', metric.value);
    if (metric.value > 200) {
      Sentry.captureMessage('FID threshold exceeded', {
        level: 'warning',
        contexts: { metric: { name: 'FID', value: metric.value } },
      });
    }
  });

  // Cumulative Layout Shift (CLS) — target: < 0.1
  getCLS((metric: Metric) => {
    console.log('CLS:', metric.value);
    if (metric.value > 0.1) {
      Sentry.captureMessage('CLS threshold exceeded', {
        level: 'warning',
        contexts: { metric: { name: 'CLS', value: metric.value } },
      });
    }
  });

  // First Contentful Paint (FCP)
  getFCP((metric: Metric) => {
    console.log('FCP:', metric.value);
  });

  // Time to First Byte (TTFB)
  getTTFB((metric: Metric) => {
    console.log('TTFB:', metric.value);
  });
}
```

### Usage in main.tsx

```tsx
// src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { trackWebVitals } from './utils/web-vitals';
import App from './App';

// Track Core Web Vitals in production
if (process.env.NODE_ENV === 'production') {
  trackWebVitals();
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

---

## 5. Error Reporting Integration

### Sentry Setup

```tsx
// src/utils/sentry.ts
import * as Sentry from '@sentry/react';
import { BrowserTracing } from '@sentry/tracing';

export function initSentry() {
  Sentry.init({
    dsn: process.env.REACT_APP_SENTRY_DSN,
    environment: process.env.NODE_ENV,
    integrations: [
      new BrowserTracing({
        tracingOrigins: ['localhost', process.env.REACT_APP_API_URL, /^\//],
      }),
    ],
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    release: process.env.REACT_APP_VERSION,
  });
}

// Usage in main.tsx
import { initSentry } from './utils/sentry';
initSentry();
```

### Azure Application Insights Setup

```tsx
// src/utils/azure-insights.ts
import { ApplicationInsights } from '@microsoft/applicationinsights-web';
import { AngularPlugin } from '@microsoft/applicationinsights-angularplugin-js';

export function initAzureInsights() {
  const appInsights = new ApplicationInsights({
    config: {
      instrumentationKey: process.env.REACT_APP_INSTRUMENTATION_KEY!,
      disableFetchTracking: false,
      enableRequestHeaderTracking: true,
      enableResponseHeaderTracking: true,
      enableAutoRouteTracking: true,
      autoTrackPageVisitTime: true,
      samplingPercentage: 100,
      sessionRenewalMs: 1800000,
      sessionExpirationMs: 3600000,
    },
  });

  appInsights.loadAppInsights();
  appInsights.trackPageView();
  return appInsights;
}
```

### DataDog RUM (Real User Monitoring)

```tsx
// src/utils/datadog.ts
import { datadogRum } from '@datadog/browser-rum';

export function initDataDog() {
  datadogRum.init({
    applicationId: process.env.REACT_APP_DATADOG_APP_ID!,
    clientToken: process.env.REACT_APP_DATADOG_CLIENT_TOKEN!,
    site: 'datadoghq.com',
    service: '[service-name]',
    env: process.env.NODE_ENV,
    version: process.env.REACT_APP_VERSION,
    sessionSampleRate: 100,
    sessionReplaySampleRate: 20,
    trackUserInteractions: true,
    trackResources: true,
    trackLongTasks: true,
    defaultPrivacyLevel: 'mask-user-input',
  });

  datadogRum.startSessionReplayRecording();
}
```

---

## 6. User Analytics (Zero PII)

Anonymous user analytics without collecting PII:

```tsx
// src/utils/analytics.ts
import * as Sentry from '@sentry/react';

interface AnalyticsEvent {
  event_name: string;
  properties: Record<string, string | number | boolean>;
}

export function trackEvent(eventData: AnalyticsEvent) {
  // Never include: email, user_id, phone, credit_card, name
  const safeProperties = {
    ...eventData.properties,
    timestamp: new Date().toISOString(),
    user_session: sessionStorage.getItem('session_id'), // Anonymous session
    browser: navigator.userAgent.split('/')[0], // Browser type only
    device_type: /Mobile/.test(navigator.userAgent) ? 'mobile' : 'desktop',
  };

  // Send to analytics service
  console.log('[Analytics Event]', eventData.event_name, safeProperties);

  // Also log to Sentry for error correlation
  Sentry.captureMessage(eventData.event_name, {
    level: 'info',
    tags: { event_type: 'user_analytics' },
    contexts: { event: safeProperties },
  });
}

// Key Events to Track
export const analytics = {
  pageView: (path: string) =>
    trackEvent({ event_name: 'page_view', properties: { path } }),

  featureClick: (feature: string) =>
    trackEvent({ event_name: 'feature_click', properties: { feature } }),

  formSubmit: (formName: string, fields: number) =>
    trackEvent({ event_name: 'form_submit', properties: { form: formName, fields } }),

  apiError: (endpoint: string, status: number) =>
    trackEvent({ event_name: 'api_error', properties: { endpoint, status } }),

  funnel: (stage: string) =>
    trackEvent({ event_name: 'funnel_step', properties: { stage } }),
};
```

### Usage

```tsx
import { analytics } from './utils/analytics';

function Dashboard() {
  useEffect(() => {
    analytics.pageView('/dashboard');
  }, []);

  const handleFeatureClick = () => {
    analytics.featureClick('export_report');
  };

  return (
    <button onClick={handleFeatureClick}>
      Export Report
    </button>
  );
}
```

---

## 7. Console Log Management

Structured logging for development vs. production:

```tsx
// src/utils/logger.ts
export const logger = {
  debug: (message: string, data?: unknown) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug(`[DEBUG] ${message}`, data);
    }
  },

  info: (message: string, data?: unknown) => {
    if (process.env.NODE_ENV === 'development') {
      console.info(`[INFO] ${message}`, data);
    }
  },

  warn: (message: string, data?: unknown) => {
    console.warn(`[WARN] ${message}`, data);
  },

  error: (message: string, error: unknown) => {
    console.error(`[ERROR] ${message}`, error);

    // Also report to Sentry in production
    if (process.env.NODE_ENV === 'production') {
      import('@sentry/react').then(Sentry => {
        Sentry.captureException(error, {
          contexts: { log: { message } },
        });
      });
    }
  },
};

// Usage
logger.debug('Component mounted', { props });
logger.error('Failed to load data', error);
```

---

## 8. Frontend SLO

Service Level Objectives for React applications:

| Objective | Target | Threshold | Error Budget |
|-----------|--------|-----------|--------------|
| **Page Load Time** | < 2.0s | p75 < 2s, p99 < 5s | 5 minutes/month |
| **Error Rate** | < 0.1% | Errors / Total views | 2 errors/month per 1000 users |
| **Interaction Speed** | < 200ms | 95% interactions < 200ms | 5 minutes/month |
| **Core Web Vitals** | Good | LCP < 2.5s, INP < 200ms, CLS < 0.1 | 2 minutes/month |

### SLI Queries (in your analytics backend)

```sql
-- Page Load SLI: What % of pages load under 2 seconds?
SELECT
  COUNT(CASE WHEN page_load_ms < 2000 THEN 1 END) * 100.0 / COUNT(*) as load_sli_percent
FROM page_loads
WHERE timestamp > NOW() - INTERVAL 30 DAY

-- Error Rate SLI: What % of user sessions have NO errors?
SELECT
  COUNT(DISTINCT session_id) - COUNT(DISTINCT CASE WHEN error_count > 0 THEN session_id END)
  * 100.0 / COUNT(DISTINCT session_id) as error_free_sli_percent
FROM sessions
WHERE timestamp > NOW() - INTERVAL 30 DAY

-- Interaction SLI: What % of interactions complete under 200ms?
SELECT
  COUNT(CASE WHEN interaction_time_ms < 200 THEN 1 END) * 100.0 / COUNT(*) as interaction_sli_percent
FROM user_interactions
WHERE timestamp > NOW() - INTERVAL 30 DAY
```

---

## 9. Real User Monitoring (RUM)

Setup for Azure Application Insights RUM:

```tsx
// src/utils/rum-setup.ts
import { ApplicationInsights } from '@microsoft/applicationinsights-web';

export function initRUM() {
  const appInsights = new ApplicationInsights({
    config: {
      instrumentationKey: process.env.REACT_APP_INSTRUMENTATION_KEY,
      autoTrackPageVisitTime: true,
      enableAjaxErrorStatusText: true,
      enableAjaxXhrMonitoring: true,
      enableRequestHeaderTracking: true,
      enableResponseHeaderTracking: true,
      enableUnhandledPromiseRejectionTracking: true,
      samplingPercentage: 100, // 100% for comprehensive RUM
      customProperties: {
        environment: process.env.NODE_ENV,
        version: process.env.REACT_APP_VERSION,
      },
    },
  });

  appInsights.loadAppInsights();
  appInsights.trackPageView();

  // Track route changes (SPA)
  return appInsights;
}

// Track custom events
export function trackCustomEvent(
  name: string,
  properties?: { [key: string]: string | number | boolean }
) {
  const appInsights = ApplicationInsights.getInstance();
  appInsights?.trackEvent({ name }, undefined, properties);
}
```

### Route Change Tracking (React Router)

```tsx
// src/router.tsx
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { trackCustomEvent } from './utils/rum-setup';

export function RouteTracker() {
  const location = useLocation();

  useEffect(() => {
    trackCustomEvent('route_change', {
      path: location.pathname,
      search: location.search,
    });
  }, [location]);

  return null;
}

// Add to App.tsx
<RouteTracker />
```

---

## 10. CI/CD Integration

### Lighthouse CI (Performance Budgets)

```bash
# Install
npm install -g @lhci/cli@latest

# Create .lighthouserc.json
{
  "ci": {
    "collect": {
      "url": ["http://localhost:3000"],
      "numberOfRuns": 3,
      "settings": {
        "configPath": "./lighthouse.config.js"
      }
    },
    "upload": {
      "target": "temporary-public-storage"
    },
    "assert": {
      "preset": "lighthouse:recommended",
      "assertions": {
        "cumululative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "first-input-delay": ["error", { "maxNumericValue": 200 }]
      }
    }
  }
}
```

### Bundle Size Alerts (GitHub Actions)

```yaml
# .github/workflows/bundle-size.yml
name: Bundle Size Check

on: [pull_request]

jobs:
  bundle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - run: npm install && npm run build

      - name: Check Bundle Size
        run: |
          SIZE=$(du -sh dist | awk '{print $1}')
          if [ $(echo "$SIZE" | sed 's/M//') -gt 250 ]; then
            echo "Bundle too large: $SIZE (max 250M)"
            exit 1
          fi
          echo "✓ Bundle size OK: $SIZE"

      - name: Upload Build Artifact
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
```

### Performance Testing in CI

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on:
  pull_request:
    branches: [main]

jobs:
  perf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - run: npm install

      - name: Run Lighthouse CI
        run: |
          npm install -g @lhci/cli@latest
          lhci autorun

      - name: Run Vitest with Coverage
        run: npm run test:coverage

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

---

## 11. Frontend Observability Checklist

Before deploying to production:

**Error Tracking:**
- [ ] Sentry / App Insights / DataDog initialized
- [ ] Error Boundary component wraps main app
- [ ] React Query error callbacks configured
- [ ] Unhandled promise rejections tracked
- [ ] Console errors logged (in dev mode)

**Performance:**
- [ ] web-vitals library integrated
- [ ] Core Web Vitals tracked (LCP, INP, CLS)
- [ ] Page load timing measured
- [ ] Interaction timing measured (FID/INP)
- [ ] Performance budget set (JS < 200kb, CSS < 100kb)

**Analytics (Zero PII):**
- [ ] User analytics event tracking implemented
- [ ] No PII in any event properties (no emails, user IDs, etc.)
- [ ] Session ID generation (anonymous)
- [ ] Page view tracking on route changes
- [ ] Key funnel steps defined

**RUM (Real User Monitoring):**
- [ ] Application Insights RUM enabled
- [ ] Page view tracking enabled
- [ ] Route changes tracked
- [ ] Custom events defined
- [ ] Session recording enabled (if using DataDog)

**Console Logging:**
- [ ] logger utility prevents debug logs in production
- [ ] Console errors logged to error tracking service
- [ ] No sensitive data in console logs
- [ ] Structured logging format used

**SLO/SLI:**
- [ ] SLO targets documented (page load, error rate, interaction speed)
- [ ] SLI queries created in analytics backend
- [ ] SLO tracking dashboard created
- [ ] Error budget alerts configured

**CI/CD:**
- [ ] Lighthouse CI configured with performance budgets
- [ ] Bundle size checks in CI pipeline
- [ ] Coverage requirements enforced (> 80%)
- [ ] Performance tests run on every PR
- [ ] Artifacts uploaded (dist/, coverage/)

**Production Readiness:**
- [ ] All environment variables set (.env.production)
- [ ] Sentry/App Insights DSN configured
- [ ] API base URL points to production
- [ ] Console logging disabled
- [ ] Source maps uploaded to error tracking service
- [ ] User consent for analytics implemented (GDPR/CCPA)
