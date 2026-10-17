---
name: product-discovery
description: Valida el problema y la oportunidad ANTES de escribir el PRD — investigación de mercado, análisis competitivo, Jobs-to-be-Done, TAM/SAM/SOM, Lean Canvas, Opportunity Solution Tree, hipótesis riesgosas y plan de experimentos de validación. Úsalo siempre que el usuario tenga una idea de producto sin validar, quiera saber si vale la pena construir algo, pregunte por el mercado, la competencia o el tamaño de la oportunidad, o quiera entrevistar clientes — incluso si no dice "discovery". Validates the problem and market opportunity before committing to a PRD.
model_invoked: true
triggers:
  - product discovery
  - descubrimiento de producto
  - validar la idea
  - validar el problema
  - investigación de mercado
  - market research
  - análisis competitivo
  - competitive analysis
  - competidores
  - tamaño de mercado
  - tam sam som
  - jobs to be done
  - jtbd
  - lean canvas
  - entrevistas con clientes
  - customer interviews
  - problem validation
  - opportunity solution tree
  - product market fit
  - vale la pena construir
---

# Product Discovery Skill

## Purpose

Most failed products fail because they solved a problem nobody had badly enough to pay for — not because of bad code. This skill sits **before** `product-design` (Stage 0 of the pipeline) and answers: *is this problem real, for whom, how big is it, and what must be true for us to win?*

It produces a Discovery Brief that:
- Frames the problem and the customer's job-to-be-done
- Sizes the opportunity (TAM / SAM / SOM) with explicit assumptions
- Maps the competitive landscape and alternatives (including "do nothing" / spreadsheets)
- Summarizes the business model on a Lean Canvas
- Lists the riskiest assumptions and a concrete plan to test them cheaply
- Ends with a **Go / Pivot / Kill** recommendation that feeds the PRD

Write the output in the user's language (Spanish by default if the user writes in Spanish).

## Workflow

### 1. Gather context

Ask only what you can't infer from the conversation. Group questions so the user can answer in one message:

**The idea**
- What problem do you believe exists, and who has it?
- How do those people solve it today? (the real competitor is often Excel, WhatsApp, or a manual process)
- Why now? (regulation, technology shift, market change)

**Evidence so far**
- Have you talked to potential customers? How many? What did they say (quotes are gold)?
- Any data: waitlist, searches, LOIs, pilot users, internal metrics?

**Business context**
- Geography and segment (B2B / B2C / B2B2C; SMB / mid-market / enterprise)
- Business goal: new revenue line, internal efficiency, strategic bet?
- Constraints: budget, timeline, regulatory (e.g., health data, DIAN e-invoicing, GDPR)

If the user has little evidence, that's fine — say so explicitly in the brief and make the validation plan the most important section.

### 2. Research (when tools are available)

If web search is available, research competitors, pricing pages, market reports, and regulatory context. Cite sources inline with links. If not, build the analysis from the user's knowledge and **label estimates as assumptions** — never present an invented market figure as fact. A made-up TAM undermines every decision downstream.

### 3. Build the analysis

Use the template at `assets/discovery-brief-template.md`. Key frameworks and why each matters:

| Framework | What it answers | Why it matters downstream |
|---|---|---|
| Problem statement + JTBD | What job is the customer hiring a product to do? | Personas and user stories in the PRD derive from this |
| Alternatives & competitors | What do they use today, and what's wrong with it? | Positioning in `go-to-market` builds on this |
| TAM / SAM / SOM | Is the prize big enough? | Justifies investment; sets realistic revenue targets |
| Lean Canvas | Does the business model hang together? | Surfaces pricing, channels, and cost risks early |
| Riskiest assumptions | What must be true that we haven't proven? | Prevents building on untested beliefs |
| Opportunity Solution Tree | Which opportunities connect to the outcome we want? | Keeps the PRD focused on outcomes, not feature lists |

**Sizing guidance:** prefer bottom-up (number of target customers × realistic price × adoption) over top-down ("the market is $10B, we take 1%"). Show the arithmetic so the user can challenge each input.

**Riskiest assumptions:** classify each into one of four risk types — *Value* (will they want it?), *Usability* (can they use it?), *Feasibility* (can we build it?), *Viability* (does the business work?). Rank by impact × uncertainty. For the top 3–5, design the cheapest experiment that would disprove it: problem interviews, landing-page smoke test, concierge/Wizard-of-Oz MVP, prototype usability test, pricing survey (Van Westendorp), pre-sales/LOIs. Each experiment needs a **success threshold defined before running it** (e.g., "≥ 6 of 10 interviewees describe this pain unprompted").

### 4. Interview kit (optional but recommended)

If the user hasn't interviewed customers, generate a short interview guide (problem interviews, not pitch meetings): open questions about past behavior ("Tell me about the last time you…"), never "Would you use…?". People are bad at predicting future behavior but good at recalling past pain.

### 5. Recommendation

Close with a clear call:
- **Go** — evidence supports the problem and opportunity; proceed to `product-design` with the validated scope
- **Go with conditions** — proceed, but the PRD must include the listed validation experiments in the MVP
- **Pivot** — the problem is real but the segment/solution should change (say how)
- **Kill / Park** — evidence doesn't justify investment now (say what would change your mind)

Be honest. A discovery brief that always says "Go" is worthless.

### 6. File output

Filename: `[project-name]-discovery-brief.md`, saved to the outputs directory (Cowork: `/sessions/[session-id]/mnt/outputs/`; Claude Code: the project's `docs/` folder unless the user says otherwise).

After saving, show the recommendation and top 3 risks, and ask: "Do you want to adjust anything, or proceed to Stage 1 (Product Design)?"

## Quality Checklist

- ✅ Problem is described from the customer's perspective, not as a missing feature
- ✅ Current alternatives include non-software options (manual process, spreadsheets, doing nothing)
- ✅ Market sizing shows the arithmetic and labels every assumption
- ✅ Every market/competitor figure is either cited or labeled as an estimate
- ✅ Riskiest assumptions are ranked and each top risk has an experiment with a pre-defined pass threshold
- ✅ Recommendation is explicit (Go / Go with conditions / Pivot / Kill) and justified by the evidence
- ✅ Handoff section lists what `product-design` should take as input

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 0)
**Feeds into:** `product-design` (problem, personas, value proposition, success metrics), `go-to-market` (ICP, competitors, positioning), `growth-strategy` (initial channel hypotheses)
**Output:** `[project-name]-discovery-brief.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md)
