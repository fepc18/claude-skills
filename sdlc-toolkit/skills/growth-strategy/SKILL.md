---
name: growth-strategy
description: Diseña la estrategia de crecimiento post-lanzamiento — growth model (inputs → North Star), growth loops, optimización del funnel AARRR, onboarding y activación, retención y reducción de churn, monetización y expansión (upsell, NRR), referidos, backlog de experimentos priorizado con ICE/RICE, diseño de A/B tests con tamaño de muestra, y el ciclo de feedback hacia el roadmap. Úsalo siempre que el usuario quiera crecer usuarios o ingresos, mejorar conversión, activación o retención, bajar churn, hacer experimentos o A/B tests, product-led growth, o decidir qué construir después según datos — incluso si no dice "growth".
model_invoked: true
triggers:
  - growth
  - crecimiento
  - estrategia de crecimiento
  - growth strategy
  - growth loops
  - product led growth
  - plg
  - retención
  - retention
  - churn
  - activación
  - activation
  - onboarding
  - conversión
  - conversion rate
  - experimentos
  - a/b test
  - experimentation
  - upsell
  - expansión
  - referidos
  - referral program
  - qué construir después
---

# Growth Strategy Skill

## Purpose

Launch gets the first customers; growth is the repeatable system that gets the next thousand and keeps them. This skill is the last stage of the pipeline and also the start of the next loop: experiment results and customer feedback flow back into `product-discovery` and `product-design` for the next iteration.

It produces a Growth Plan with:
- Growth model: how inputs (traffic, activation, retention, expansion) compound into the North Star
- Diagnosis: where the funnel leaks most, using real data when available
- Growth loops (not just funnels) that make growth self-reinforcing
- Levers per stage: acquisition, activation/onboarding, retention/engagement, monetization/expansion, referral
- Prioritized experiment backlog (ICE or RICE) with properly designed tests
- Experimentation process and the feedback loop into the roadmap

Write the output in the user's language.

## Workflow

### 1. Gather context and data

Read upstream artifacts if present: `*-measurement-plan.md` (NSM, input metrics, events), `*-gtm-plan.md` (ICP, channels, pricing), `*-prd.md`. Then ask:

- Stage: pre-PMF (few customers, still learning), early growth, or scaling?
- Current numbers per funnel stage (even rough): visitors, signups, activated, retained W4/M3, paying, churn, ARPA, CAC
- What's been tried already and what happened?
- Team capacity for growth work (engineers/designers per sprint)
- Constraints: brand, regulation (health/financial data limits what can be personalized or emailed), sales cycle length

**Stage matters:** pre-PMF products should focus almost entirely on activation and retention — pouring acquisition into a leaky bucket wastes money. Say so explicitly if retention curves don't flatten. A useful PMF signal: retention cohort curve flattens above zero; or ≥ 40% of surveyed users "very disappointed" without the product (Sean Ellis test).

### 2. Growth model and diagnosis

Write the growth equation for this business (e.g., `New paying accounts = Visitors × Signup% × Activation% × Trial→Paid%`, plus `Net revenue = Existing MRR × (1 − churn) × (1 + expansion)`). Plug in current numbers and target numbers. Run a quick sensitivity: which single input improvement moves the NSM most? That's the focus area for the next quarter — focus beats spreading effort over every stage.

If there's no data yet, say so, set up the model with placeholders, and make "instrument and baseline" the first milestone (link to `product-analytics`).

### 3. Growth loops

Identify 1–3 loops where outputs of one cycle become inputs to the next. Common ones:
- **Viral/collaboration loop:** user invites colleagues to get value (e.g., shared clinical records with another provider)
- **Content/UGC loop:** usage creates public content that attracts new users (SEO)
- **Paid loop:** revenue funds acquisition with payback < N months
- **Sales/partner loop:** customers become references or resellers
- **Data/network loop:** more usage improves the product for everyone

For each: draw the loop, name the metric that measures cycle speed and conversion, and the bottleneck.

### 4. Levers per stage

For the focus stage, go deep; for others, list top ideas:
- **Acquisition:** channel experiments (from GTM candidates), SEO, partnerships, referral incentives
- **Activation/onboarding:** shorten time-to-value, remove steps before the value moment, templates/sample data, guided setup, lifecycle emails triggered by behavior (not by day count)
- **Retention/engagement:** habit loops tied to the job's natural frequency, notifications with value, health scores for B2B accounts, proactive CS for at-risk accounts, cohort analysis by segment/acquisition channel
- **Churn reduction:** exit surveys, cancellation flow with alternatives (pause, downgrade), involuntary churn fixes (failed payments, dunning)
- **Monetization/expansion:** usage-based upsell triggers at limits, add-ons, annual plans, NRR targets
- **Referral:** double-sided incentives aligned with value, timing after a success moment

### 5. Experiment backlog

Use the template at `assets/growth-plan-template.md`. Each idea needs: hypothesis ("We believe [change] for [segment] will [impact metric] by [amount] because [insight]"), primary metric, guardrail metrics (what must not get worse — e.g., support tickets, refund rate), and an ICE or RICE score. Prioritize the top 5–10.

For A/B tests, compute the needed sample size before running (baseline rate, minimum detectable effect, α = 0.05, power = 0.8) and the resulting duration given current traffic. **If traffic is too low for a reliable test** (common in B2B), say so and recommend alternatives: before/after with holdout, qualitative usability tests, painted-door tests, or larger bolder changes. Running underpowered tests and calling winners produces false learnings.

Include a short formula or table for sample size so the team can reuse it:
`n per variant ≈ 16 × p(1−p) / MDE²` (for α=0.05, power=0.8, absolute MDE).

### 6. Experimentation process & feedback loop

Define the operating rhythm: weekly growth meeting (review results, pick next experiments), experiment doc template, decision rules (ship / iterate / kill), and a learnings log. Then close the lifecycle loop:
- Winning experiments → `functional-specs`/`technical-specs` for proper implementation
- New problems/opportunities discovered → `product-discovery` for the next iteration
- Roadmap updates → `product-design` (PRD v2)

### 7. File output

Filename: `[project-name]-growth-plan.md`, saved to the outputs directory (Cowork: `/sessions/[session-id]/mnt/outputs/`; Claude Code: project `docs/` folder unless told otherwise). Show the focus area, top 3 experiments, and the 90-day targets; ask if they want to refine any experiment into a spec.

## Quality Checklist

- ✅ Growth model written as an equation with current and target values (or explicit placeholders)
- ✅ One focus area chosen by sensitivity analysis, with stage (pre-PMF vs scaling) considered
- ✅ At least one growth loop with its cycle metric and bottleneck
- ✅ Every experiment has hypothesis, primary metric, guardrails and ICE/RICE score
- ✅ A/B tests include sample size and duration; low-traffic alternatives offered when needed
- ✅ Retention and churn addressed before heavy acquisition spend
- ✅ Feedback loop back into discovery/PRD/specs is defined

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 12 — closes the loop back to Stage 0)
**Inputs:** measurement plan (NSM, events), GTM plan (ICP, channels, pricing), live product data
**Feeds into:** `product-discovery` and `product-design` (next iteration), `functional-specs` (winning experiments)
**Output:** `[project-name]-growth-plan.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md)
