---
name: product-analytics
description: Define cómo se mide el éxito del producto — North Star Metric, árbol de métricas (input metrics), framework AARRR/HEART, tracking plan con taxonomía de eventos y propiedades, especificación de instrumentación (Segment, Mixpanel, Amplitude, PostHog, GA4) con código para React y Golang, dashboards de producto y gobernanza de datos/privacidad. Úsalo siempre que el usuario hable de KPIs de producto, métricas de negocio, eventos, tracking, analítica, funnels, cohortes o "cómo sabremos si funciona" — incluso si no dice "analytics". Not for infrastructure monitoring (use observability-specs for that).
model_invoked: true
triggers:
  - product analytics
  - analítica de producto
  - north star metric
  - métrica norte
  - tracking plan
  - plan de tracking
  - eventos de producto
  - instrumentación
  - kpis de producto
  - métricas de producto
  - funnel
  - embudo de conversión
  - cohortes
  - aarrr
  - heart framework
  - mixpanel
  - amplitude
  - posthog
  - segment
  - google analytics
  - ga4
---

# Product Analytics Skill

## Purpose

`observability-specs` tells you whether the **system** is healthy (latency, errors, uptime). This skill tells you whether the **product** is working (are users getting value, converting, coming back). Without it, go-to-market and growth decisions are guesses.

It produces a Measurement Plan with:
- North Star Metric (NSM) and its input-metric tree
- Metrics per lifecycle stage (AARRR) and per-feature UX quality (HEART) where useful
- A tracking plan: event taxonomy, properties, identity, where each event fires
- Instrumentation spec with real code for React (client) and Golang (server-side events)
- Product dashboards and review cadence
- Data governance: PII rules, consent, retention

Write the output in the user's language.

## When to run it

In the orchestrator it's Stage 10, but **the earlier the better**: ideally run it right after `functional-specs` (Stage 5) so events are built into the technical specs and tested in Stage 8. Retrofitting tracking after launch means losing the launch-week data you most need. If the user is already past Stage 7, recommend adding the events as tickets to the current build.

## Workflow

### 1. Gather context

Read upstream docs if present (`*-discovery-brief.md`, `*-prd.md`, `*-functional-specs.md`). Then ask only what's missing:
- Business model: SaaS subscription, transactional/marketplace, usage-based, internal tool?
- What is the core "value moment"? (the action that means the user got what they came for — e.g., "invoice issued and accepted by DIAN", "clinical record signed")
- Analytics tool already in place or preferred? (PostHog, Mixpanel, Amplitude, Segment → warehouse, GA4). If none, recommend one with reasoning (e.g., PostHog for self-hosting/health data residency, GA4 only for marketing sites)
- Privacy constraints: health data (HIPAA / Ley 1581 de 2012 en Colombia), GDPR, consent requirements
- Multi-tenant? (B2B products need account-level as well as user-level analytics)

### 2. North Star Metric and metric tree

Pick **one** NSM that captures delivered customer value and leads revenue. Good NSMs are counts of value moments over time ("weekly invoices successfully issued"), not vanity metrics (signups, page views) or lagging financials (MRR). Explain why you chose it and what it deliberately excludes.

Decompose it into 3–5 input metrics the team can directly influence (breadth × depth × frequency × efficiency). These become the levers for `growth-strategy`.

### 3. Lifecycle metrics (AARRR)

For each stage — Acquisition, Activation, Retention, Referral, Revenue — define: metric, exact formula, target, data source. **Activation** deserves special care: define it as reaching the value moment within N days, and say how you'd validate the definition (correlation with 30/60-day retention).

Add HEART (Happiness, Engagement, Adoption, Retention, Task success) for key features when UX quality matters.

### 4. Tracking plan

Use the template at `assets/tracking-plan-template.md`. Conventions (explain them in the doc so the team keeps them):
- Event names: `Object Action` in past tense, Title Case or snake_case — pick one and be consistent (`Invoice Issued` / `invoice_issued`)
- Track **intent and outcome** for critical flows (`Checkout Started` → `Payment Succeeded` / `Payment Failed` with `failure_reason`)
- Prefer server-side events for anything that matters for revenue or compliance — client events get blocked by ad-blockers and can be spoofed
- Every event carries: `user_id`, `account_id`/`tenant_id` (B2B), `timestamp`, `platform`, `app_version`
- Keep the plan small: 15–30 well-defined events beat 200 auto-captured ones nobody trusts

### 5. Instrumentation spec

Generate real code consistent with `references/react-standards.md` and `references/golang-standards.md`:
- **React:** a typed `analytics` wrapper (TypeScript union of event names → property types) so typos fail at compile time; a hook like `useTrack()`; identify/reset on login/logout; consent gating
- **Golang:** a `domain`-level `EventPublisher` interface (clean architecture: business logic doesn't import the vendor SDK) with an adapter for the chosen tool; fire after the transaction commits; never block the request path (async/queue)
- **Testing:** how to assert events in unit tests (mock publisher) and validate in staging

### 6. Dashboards & rituals

Define 3–5 dashboards (Executive/NSM, Acquisition funnel, Activation funnel, Retention cohorts, Feature adoption) with the specific charts in each. Add a review cadence (weekly metrics review, monthly cohort deep-dive) and an owner per metric — a metric without an owner doesn't move.

### 7. Governance & privacy

Apply `references/security-rules.md`: no PII in event properties (no names, emails, document numbers, clinical data) — use opaque IDs; consent banner/opt-out where required; retention period; who can access raw data; process to add/change events (tracking plan is the source of truth, reviewed in PRs).

### 8. File output

Filename: `[project-name]-measurement-plan.md`, saved to the outputs directory (Cowork: `/sessions/[session-id]/mnt/outputs/`; Claude Code: project `docs/` folder unless told otherwise). Show the NSM, metric tree, and event count, then ask whether to proceed to `go-to-market`.

## Quality Checklist

- ✅ One NSM, justified, measuring delivered value (not vanity, not pure revenue)
- ✅ Input metrics are things the team can directly influence
- ✅ Every metric has an exact formula, data source, target and owner
- ✅ Activation is defined around the value moment with a time window
- ✅ Tracking plan events follow one naming convention and list required properties
- ✅ Revenue/compliance-critical events are server-side
- ✅ No PII in properties; consent and retention addressed
- ✅ Instrumentation code is typed and decoupled from the vendor SDK

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 10 — recommended to run alongside Stage 5–7)
**Inputs:** PRD success criteria, functional specs flows, discovery brief
**Feeds into:** `technical-specs` (events as requirements), `test-strategy` (event assertions), `go-to-market` (launch KPIs), `growth-strategy` (levers and experiment metrics)
**Complements:** `observability-specs` (system health) — keep them separate but link dashboards
**References:** security-rules.md, react-standards.md, golang-standards.md, clean-architecture.md
**Output:** `[project-name]-measurement-plan.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md)
