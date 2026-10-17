# Growth Plan: [Project Name]

**Version:** 1.0 · **Date:** [YYYY-MM-DD] · **Owner:** [Growth lead / PM]
**Product stage:** Pre-PMF / Early growth / Scaling · **Horizon:** next 90 days

---

## 1. Summary
- **North Star:** [metric] — current [x] → target [y] by [date]
- **Focus area this quarter:** [stage] — because [sensitivity result]
- **Top 3 bets:** [1], [2], [3]

## 2. PMF Check
- Retention curve flattens? [yes/no — at __% by week __]
- Sean Ellis "very disappointed" score: [__% or not measured]
- **Implication:** [focus on retention/activation vs. scale acquisition]

## 3. Growth Model

```
New paying accounts / month = Visitors × Signup% × Activation% × Trial→Paid%
Net MRR next month          = MRR × (1 − churn%) × (1 + expansion%) + New × ARPA
```

| Input | Current | Target | +10% relative improvement → NSM impact |
|---|---|---|---|
| Visitors / month | | | |
| Signup % | | | |
| Activation % | | | |
| Trial → paid % | | | |
| Monthly churn % | | | |
| Expansion % | | | |

**Biggest lever:** [input] — [why]

## 4. Funnel Diagnosis

| Stage | Conversion | Benchmark / target | Main drop-off reason (data or hypothesis) |
|---|---|---|---|
| Visit → Signup | | | |
| Signup → Activated | | | |
| Activated → Retained W4 | | | |
| Retained → Paying | | | |

## 5. Growth Loops

### Loop 1: [Name]
```
[New user] → [does value action] → [creates output: invite / content / referral] → [reaches new user] → ...
```
- **Cycle metric:** [e.g., invites per activated user × invite acceptance %]
- **Cycle time:** [days]
- **Bottleneck:** [...]

## 6. Levers by Stage

| Stage | Lever ideas | Focus? |
|---|---|---|
| Acquisition | | |
| Activation / onboarding | | |
| Retention / engagement | | |
| Churn reduction (voluntary + involuntary) | | |
| Monetization / expansion | | |
| Referral | | |

## 7. Experiment Backlog

| # | Hypothesis | Stage | Primary metric | Guardrails | I | C | E | ICE | Status |
|---|---|---|---|---|---|---|---|---|---|
| E1 | We believe [change] for [segment] will [move metric by x] because [insight] | | | | | | | | Backlog |

*(RICE alternative: Reach × Impact × Confidence / Effort.)*

### Experiment design: E1
- **Type:** A/B test / painted door / before-after with holdout / usability test
- **Variants:** control: [...] · treatment: [...]
- **Baseline rate (p):** [__] · **MDE (absolute):** [__]
- **Sample size per variant:** n ≈ 16 × p(1−p) / MDE² = [__]
- **Traffic available / week:** [__] → **Duration:** [__ weeks] (minimum 1 full business cycle)
- **Decision rule:** ship if primary metric improves ≥ MDE with p < 0.05 and no guardrail regresses
- **If traffic is insufficient:** [alternative method]

## 8. Operating Rhythm
- **Weekly growth meeting:** results → learnings → pick next experiments
- **Experiment doc** per test (hypothesis, design, result, decision)
- **Learnings log:** [link]
- **Monthly:** cohort review; update growth model numbers

## 9. Feedback Loop into the Lifecycle

| Learning / result | Goes to | Action |
|---|---|---|
| Winning experiment | functional-specs / technical-specs | Implement properly, remove flag |
| New problem or segment | product-discovery | Validate before building |
| Roadmap change | product-design (PRD v2) | Reprioritize epics |

## 10. 90-Day Targets

| Metric | Today | Day 30 | Day 60 | Day 90 |
|---|---|---|---|---|
| North Star | | | | |
| Activation % | | | | |
| W4 retention | | | | |
| Monthly churn | | | | |
| NRR | | | | |
