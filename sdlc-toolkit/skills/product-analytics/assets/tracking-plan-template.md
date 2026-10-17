# Measurement Plan: [Project Name]

**Version:** 1.0 · **Date:** [YYYY-MM-DD] · **Owner:** [PM / Data lead]
**Analytics stack:** [PostHog / Mixpanel / Amplitude / Segment → warehouse / GA4]

---

## 1. North Star Metric

**NSM:** [e.g., "Weekly active accounts that issue ≥1 accepted invoice"]
**Why this metric:** [captures delivered value; leads revenue; team can influence]
**What it deliberately excludes:** [vanity metrics it replaces]
**Current baseline:** [value or "no baseline — pre-launch"] · **Target:** [value by date]

### Metric tree

```
NSM: [ ... ]
├── Breadth:    [# active accounts]
├── Depth:      [# value actions per account]
├── Frequency:  [% accounts active ≥ N days/week]
└── Efficiency: [time-to-value / success rate of core action]
```

## 2. Lifecycle Metrics (AARRR)

| Stage | Metric | Formula | Target | Source | Owner |
|---|---|---|---|---|---|
| Acquisition | Visitor → signup rate | signups / unique visitors | | | |
| Activation | % new accounts reaching value moment in 7 days | accounts with `[Value Event]` ≤7d / new accounts | | | |
| Retention | Week-4 account retention | accounts active in W4 / cohort size | | | |
| Referral | Invites sent per active account | `Invite Sent` / active accounts | | | |
| Revenue | Trial → paid conversion; ARPA; NRR | | | | |

**Activation definition validation:** [how we'll check it correlates with long-term retention]

### HEART (key features)

| Feature | Happiness | Engagement | Adoption | Retention | Task success |
|---|---|---|---|---|---|
| | CSAT after use | uses/week | % accounts using | % still using after 30d | completion rate, errors |

## 3. Identity & Global Properties

- `user_id` — opaque internal ID (never email/document number)
- `account_id` / `tenant_id` — B2B grouping
- `platform` (web/ios/android/api), `app_version`, `environment`
- Identify on login; alias anonymous → known on signup; reset on logout

## 4. Event Catalog

**Naming convention:** [`Object Action` past tense, Title Case] · **Total events:** [n]

| Event | Trigger (exact moment) | Side | Properties (name: type — description) | Funnel/metric |
|---|---|---|---|---|
| `Account Created` | Signup form submitted & account persisted | server | `plan: string`, `signup_source: string` | Acquisition |
| `Onboarding Step Completed` | User finishes a step | client | `step_name: string`, `step_index: int` | Activation |
| `[Value Event]` | [core action succeeds] | server | | NSM, Activation |
| `Checkout Started` | | client | `plan`, `billing_period` | Revenue |
| `Payment Succeeded` / `Payment Failed` | Provider webhook confirmed | server | `amount`, `currency`, `failure_reason` | Revenue |
| `Invite Sent` | | server | `channel` | Referral |

## 5. Instrumentation

### React (typed wrapper)

```ts
// src/shared/analytics/events.ts
export type AnalyticsEvents = {
  'Onboarding Step Completed': { step_name: string; step_index: number };
  'Checkout Started': { plan: 'basic' | 'pro'; billing_period: 'monthly' | 'yearly' };
};

// src/shared/analytics/useTrack.ts
export function useTrack() {
  const { hasConsent } = useConsent();
  return <E extends keyof AnalyticsEvents>(event: E, props: AnalyticsEvents[E]) => {
    if (!hasConsent) return;
    analyticsClient.capture(event, { ...props, app_version: APP_VERSION });
  };
}
```

### Golang (port + adapter)

```go
// internal/domain/ports/event_publisher.go
type ProductEvent struct {
    Name       string
    UserID     string
    AccountID  string
    Properties map[string]any
    OccurredAt time.Time
}

type EventPublisher interface {
    Publish(ctx context.Context, e ProductEvent) error
}

// internal/infrastructure/analytics/posthog_publisher.go — adapter, async, non-blocking.
// Publish AFTER the DB transaction commits; failures are logged, never returned to the user.
```

### Testing
- Unit: mock `EventPublisher`, assert `Publish` called with expected name/props
- Staging: live event debugger; checklist per release

## 6. Dashboards

| Dashboard | Charts | Audience | Cadence |
|---|---|---|---|
| Executive / NSM | NSM trend, input metrics, MRR | Leadership | Weekly |
| Activation funnel | Signup → step 1…n → value moment, drop-off by segment | Product | Weekly |
| Retention | Weekly cohort heatmap, by plan/segment | Product, CS | Monthly |
| Feature adoption | HEART per feature | Product, Design | Per release |

## 7. Governance & Privacy

- No PII in event properties (names, emails, phone, document IDs, clinical data)
- Consent: [banner / opt-out / legal basis]
- Retention: raw events [n] months; aggregated indefinitely
- Access: [roles]
- Change process: tracking plan updated in the same PR that adds/changes the event
