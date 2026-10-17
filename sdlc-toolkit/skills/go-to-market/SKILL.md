---
name: go-to-market
description: Crea la estrategia de Go-to-Market y el plan de lanzamiento — ICP, posicionamiento (April Dunford), messaging framework, pricing y packaging, modelo de venta (PLG / sales-led / partner-led), canales, plan de lanzamiento por fases (alpha, beta, GA) con timeline y checklist, sales & support enablement, y KPIs de lanzamiento. Úsalo siempre que el usuario hable de lanzar un producto o feature, salir al mercado, definir precios o planes, posicionamiento, propuesta de valor comercial, estrategia comercial, beta privada o anuncio de lanzamiento — incluso si no dice "GTM". Produces a launch-ready GTM plan.
model_invoked: true
triggers:
  - go to market
  - go-to-market
  - gtm
  - estrategia de lanzamiento
  - plan de lanzamiento
  - launch plan
  - lanzar el producto
  - salir al mercado
  - posicionamiento
  - positioning
  - messaging
  - propuesta de valor comercial
  - pricing
  - precios
  - planes y precios
  - packaging
  - estrategia comercial
  - ideal customer profile
  - icp
  - beta privada
  - product launch
---

# Go-to-Market Skill

## Purpose

A product that's built but not launched deliberately usually gets a quiet release, a few signups, and a slow death. This skill turns the validated product into a market plan: **who exactly we sell to, why they should pick us, how much it costs, how they find and buy it, and how we launch it** without breaking support or operations.

It produces a GTM Plan with:
- Ideal Customer Profile (ICP) and buyer/user roles
- Positioning (competitive alternatives → unique attributes → value → target → category)
- Messaging framework per persona
- Pricing & packaging with rationale
- Sales motion and channel strategy
- Phased launch plan (alpha → beta → GA) with timeline, owners and go/no-go criteria
- Enablement for sales, support and operations
- Launch KPIs tied to the measurement plan

Write the output in the user's language.

## Workflow

### 1. Gather context

Read upstream artifacts if they exist: `*-discovery-brief.md` (segments, competitors, alternatives), `*-prd.md` (personas, features, MVP scope), `*-measurement-plan.md` (NSM, funnel metrics), `*-deployment-spec.md` (release mechanics, feature flags). Then ask only what's missing:

- Launch type: new product, major feature, new market/segment, or re-launch?
- Who buys vs. who uses? (in B2B they're often different — e.g., pharmacy owner buys, cashier uses)
- Current customer base and channels (existing customers to upsell? partners? none?)
- Budget and team for GTM (founder-led sales? marketing team? none?)
- Pricing constraints or ideas already on the table
- Target launch date and any hard deadline (regulatory dates are common — e.g., a resolution taking effect)

### 2. ICP and positioning

**ICP:** firmographics (industry, size, geography), technographics (current tools), triggers (events that make them buy *now*), and disqualifiers. A tight ICP beats a broad one: it's easier to expand from a beachhead than to recover from being "for everyone".

**Positioning** — follow April Dunford's sequence, because each step depends on the previous one:
1. Competitive alternatives (what they'd do if we didn't exist — from discovery)
2. Unique attributes (what we have that alternatives don't)
3. Value (what those attributes enable for the customer — with proof)
4. Target customers who care most about that value
5. Market category that makes the value obvious
6. Relevant trends (optional)

Then write a one-line positioning statement and a short elevator pitch.

### 3. Messaging framework

Per persona: headline, 3 value pillars (each with proof point: metric, testimonial, demo), objections and responses. Messages should talk about outcomes in the customer's words (reuse interview quotes from discovery), not feature lists.

### 4. Pricing & packaging

Reason from value, not cost: identify the **value metric** (what the customer pays per — users, invoices, locations, patients, API calls) that grows with the value they get. Then:
- Propose 2–4 tiers (good/better/best, optionally free or trial) with clear fences between them
- Price anchors: competitor pricing, willingness-to-pay data (Van Westendorp if available), cost floor
- Discounts policy (annual, nonprofit, early adopter) and how to grandfather beta users
- Local considerations: currency, taxes (e.g., IVA in Colombia), electronic invoicing for your own billing, payment methods (PSE, cards, transfers)

Flag clearly when prices are hypotheses that need validation in beta.

### 5. Sales motion and channels

Pick the primary motion and justify it from ACV (annual contract value) and buyer complexity:
- **Product-led (PLG):** low ACV, self-serve, user = buyer → onboarding and activation are the sales team
- **Sales-led:** high ACV, multiple stakeholders, compliance reviews → pipeline stages, demo, pilot, contract
- **Partner/channel-led:** distributors, integrators, associations, marketplaces (common for SMB in LatAm)
- **Hybrid:** PLG for entry, sales assist for expansion

Channels: list 3–5 candidates with expected cost, speed, and fit; recommend 1–2 to start (focus wins). Leave scaled channel experimentation to `growth-strategy`.

### 6. Launch plan

Use the template in `assets/gtm-plan-template.md`. Define the **launch tier** first — it sets how much effort is appropriate:
- **Tier 1** — new product / major market move: full campaign, PR, events
- **Tier 2** — significant feature: announcement, email, in-app, sales enablement
- **Tier 3** — minor improvement: changelog, in-app tooltip

Phases with explicit **go/no-go criteria** (numbers, not feelings):
- **Alpha** (internal / design partners): core flow works; critical bugs = 0
- **Private beta** (5–20 ICP customers): activation ≥ X%, NPS/CSAT ≥ Y, support tickets manageable
- **GA**: beta criteria met, docs/pricing/billing ready, support trained, monitoring and rollback in place (link to `deployment-specs` and `observability-specs`)

Timeline from T-8 weeks to T+4 weeks with owners. Include a post-launch review at T+30 days.

### 7. Enablement and readiness

- **Sales:** pitch deck outline, demo script, battlecards vs. top competitors, FAQ, pricing calculator
- **Support/CS:** help-center articles, macros, escalation path, known issues list
- **Operations/Legal:** terms of service, privacy policy (data protection law applies — e.g., Ley 1581 in Colombia), billing setup, contracts
- **Marketing assets:** landing page, launch email, social posts, case study from beta

### 8. Launch KPIs

Pull from the measurement plan when available; otherwise define: pipeline/signups, activation, trial→paid conversion, CAC by channel, early retention, support volume. Each with target and the dashboard where it's tracked.

### 9. File output

Filename: `[project-name]-gtm-plan.md`, saved to the outputs directory (Cowork: `/sessions/[session-id]/mnt/outputs/`; Claude Code: project `docs/` folder unless told otherwise). Show positioning statement, pricing tiers, and launch timeline summary; ask whether to proceed to `growth-strategy`.

If the user wants a deck for leadership or sales, offer to turn the plan into slides using whatever slide/deck skill or artifact type is available.

## Quality Checklist

- ✅ ICP is specific enough to build a prospect list from it (and has disqualifiers)
- ✅ Positioning follows alternatives → attributes → value → target → category, with proof
- ✅ Messaging speaks in customer outcomes, per persona, with objection handling
- ✅ Pricing has a value metric, tier fences, and is labeled hypothesis vs. validated
- ✅ Sales motion is justified by ACV and buyer complexity
- ✅ Launch tier chosen; each phase has measurable go/no-go criteria and owners
- ✅ Support, legal and billing readiness are covered — not just marketing
- ✅ Launch KPIs have targets and link to dashboards

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 10)
**Inputs:** discovery brief, PRD, measurement plan, deployment spec (release mechanics)
**Feeds into:** `growth-strategy` (post-launch scaling), back into `product-design` (beta feedback)
**Output:** `[project-name]-gtm-plan.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md)
