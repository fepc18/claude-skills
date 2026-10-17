---
name: ux-ui-design
description: Diseña la experiencia y la interfaz antes de escribir specs técnicas — flujos de usuario, arquitectura de información, inventario de pantallas, design system (tokens + componentes), wireframes y mockups con todos sus estados, accesibilidad WCAG 2.2 AA y plan de pruebas de usabilidad. Tiene dos modos — producto existente (respeta el stack y el lenguaje visual que ya hay, p. ej. Bootstrap/react-bootstrap/SCSS) y producto nuevo (React + Tailwind + shadcn/ui) — y usa los artifacts Design System y Design de Claude cuando están disponibles, con Impeccable para el pulido en código. Úsalo siempre que el usuario hable de diseñar pantallas, UI, UX, interfaz, wireframes, mockups, prototipos, design system, look & feel, rediseño o "cómo se va a ver", incluso si no dice "UX".
model_invoked: true
triggers:
  - diseño de interfaz
  - diseño de interfaces
  - ux
  - ui
  - ux/ui
  - wireframes
  - mockups
  - prototipo
  - design system
  - sistema de diseño
  - flujos de usuario
  - user flows
  - pantallas
  - look and feel
  - rediseño
  - redesign
  - tokens de diseño
  - design tokens
  - impeccable
  - shadcn
  - accesibilidad
---

# UX/UI Design Skill

## Purpose

Functional specs say *what* each feature does; technical specs say *how* the code is built. Between them sits the question teams usually skip: **what does the user actually see and do, screen by screen?** Skipping it means engineers improvise layouts in code, every screen looks a bit different, and edge states (empty, error, loading, no permission) appear only when a user hits them.

This skill produces a UX/UI Design Spec with:
- User flows and information architecture (screens, navigation)
- A design system: tokens + component inventory
- Wireframes → mockups for every key screen, with all their states
- Accessibility requirements (WCAG 2.2 AA)
- A lightweight usability test plan
- A component map that `technical-specs` turns into code

Write the output in the user's language.

## Step 1 — Choose the mode (this decides almost everything else)

The single most important decision is whether we are designing **inside an existing product** or **for a new one**. Look for evidence before asking: a frontend repo for this product, `package.json`, style folders, an existing component library.

| | **Mode A — Existing product** | **Mode B — New product** |
|---|---|---|
| When | There is already a frontend in production for this product (or this is a module of one) | Greenfield, or the user explicitly wants a new visual foundation |
| Principle | **Consistency beats novelty.** Users already learned this UI; a new module that looks different feels like a different, less trustworthy product | Pick a modern, accessible, AI-friendly foundation and define it once |
| Stack | Whatever exists (e.g., Bootstrap 5 + react-bootstrap + SCSS variables + react-icons + react-table) | React + TypeScript + Tailwind CSS + shadcn/ui (Radix primitives) + lucide-react; TanStack Table for data grids; React Hook Form + Zod for forms |
| Design system | **Extracted** from the code (tokens, components, patterns already in use) | **Defined** from scratch from brand + product needs |
| New components | Only when nothing existing fits, built with the same library and tokens | From shadcn/ui first; custom only when needed |
| Impeccable | Diagnostic only (see Step 7) | Full use |

If the evidence is ambiguous, ask one question: "¿Este diseño es para un producto que ya existe (respetamos su estilo actual) o para uno nuevo?" The user can always override the default — e.g., a deliberate redesign of an existing product is Mode B, but then say clearly that it's a migration project with its own cost.

Read `assets/brownfield-audit-checklist.md` for Mode A or `assets/greenfield-stack.md` for Mode B now.

## Step 2 — Gather context

Read upstream docs if present: `*-prd.md` (personas, epics), `*-functional-specs.md` (flows, acceptance criteria, any wireframes), `*-discovery-brief.md` (user context, JTBD), `*-measurement-plan.md` (events that screens must fire). Then ask only what's missing:
- Primary devices and context of use (desktop at a reception desk? tablet in a consulting room? phone in the field?)
- Who uses it and how often (power users daily vs. occasional users) — this decides density vs. guidance
- Brand assets (logo, colors) — Mode B only; Mode A takes them from the code
- Accessibility or legal constraints beyond WCAG AA
- Languages and locale formats (dates dd/mm/aaaa, currency, document types)

## Step 3 — UX structure: flows and information architecture

Before drawing any screen, settle the structure — it's cheap to change here and expensive later.

1. **User flows** per key job (from functional specs): Mermaid flowcharts with entry point, decisions, happy path, and error/exit paths.
2. **Screen inventory / sitemap**: every screen, its purpose, who can see it (role/permission), and how you reach it.
3. **Navigation model**: global nav, contextual nav, breadcrumbs, how the user always knows where they are and how to get back.
4. **Content priorities per screen**: what must be visible without scrolling, what is secondary, what goes behind a click.

For data-dense, professional tools (clinical records, billing, back-office), favor: keyboard-friendly forms, long forms split into sections with progress and autosave, tables with sticky headers, filters and saved views, clear distinction between read and edit modes, and confirmation only for destructive or irreversible actions (signing a record, issuing an invoice).

## Step 4 — Design system

**Mode A — extract.** Follow the audit checklist: pull color, typography, spacing, radius and shadow tokens from SCSS/CSS variables and theme overrides; list the components already in use (buttons, inputs, modals, tables, cards, alerts) with where they live; record recurring patterns (form layout, table + filters, modal confirmations). Note inconsistencies (three button styles, ad-hoc colors) as **design debt** in a separate section — document them, don't silently "fix" them in the new design.

**Mode B — define.** Tokens as CSS variables (light and dark), mapped to Tailwind theme and shadcn/ui variables: color roles (background, foreground, primary, secondary, muted, accent, destructive, border, ring, plus semantic success/warning/info), type scale, spacing scale, radius, shadows, motion durations. Then the base component set and their states.

**Where it lives.** If Claude's **Design System** artifact type is available in this environment, publish the design system there — it becomes the browsable reference that later design and coding sessions read before building anything. For Mode A, build it from the extracted tokens and components (it's a portrait of what exists, not a new proposal). If the artifact type isn't available (Cursor, CLI), write tokens to a file in the repo (`design-tokens.css` / `_tokens.scss` / `tokens.json`) and the component list into the spec.

## Step 5 — Wireframes and mockups

Go low-fidelity first (layout, hierarchy, content), get agreement, then high-fidelity with the design system applied. For each key screen include **all states**: default, empty (first use), loading, error, partial data, no permission, success/confirmation — plus responsive behavior at the breakpoints that matter for the context of use.

**Where they live.**
- If Claude's **Design** artifact type is available: lay out the screens as artboards on a canvas, built from the published design system, one artboard per screen/state. Link the artifact from the spec.
- Otherwise: static HTML mockups using the **real stack** of the mode (Bootstrap CSS for Mode A with the product's tokens; Tailwind + shadcn-style markup for Mode B), saved next to the spec. Mockups in the real stack translate to code with little loss.

Annotate each screen with: purpose, components used (from the inventory), data shown and its source, actions and their results, analytics events fired, and accessibility notes.

## Step 6 — Accessibility and usability

**Accessibility (WCAG 2.2 AA) as requirements, not a later audit:** color contrast ≥ 4.5:1 for text (3:1 for large text and UI components), full keyboard operation with visible focus, labels and error messages tied to inputs, target size ≥ 24×24 px, no information conveyed by color alone, logical heading structure, status messages announced to screen readers. In Mode A, check that new screens meet this even if older ones don't, and log the older gaps as debt.

**Usability test plan (lightweight):** 5 representative users, 3–5 realistic tasks taken from the user flows, success criteria per task (completion, time, errors), and what would trigger a redesign. Testing the mockups before coding is the cheapest moment to find problems.

## Step 7 — Implementation guidance (Impeccable)

[Impeccable](https://impeccable.style) is a design skill for coding agents that improves visual quality of generated frontend code and catches common "AI-generated look" anti-patterns. How to use it depends on the mode, because its opinions are a design language of their own:

- **Mode B:** use it fully during implementation — teach it the project's design context first, then critique/audit screens and polish before merging.
- **Mode A:** use only its **diagnostic** commands (critique, audit — hierarchy, spacing, contrast, accessibility). Don't apply commands that change the visual language (bolder colors, new typography, new motion) unless the user approves a visual change, because the product's existing style wins over Impeccable's defaults. When teaching it the project context, describe the existing design system so its suggestions stay within it.

Command names may change between Impeccable versions — check its docs rather than assuming. If Impeccable isn't installed, mention it once as optional; the spec stands on its own.

## Step 8 — Output

Use the template at `assets/ux-ui-design-spec-template.md`. Filename: `[project-name]-ux-ui-design.md`, saved to the outputs directory (Cowork: `/sessions/[session-id]/mnt/outputs/`; Claude Code: the project's `docs/` folder unless told otherwise), plus links to the Design System and Design artifacts or the paths of the HTML mockups and token files.

After saving, show the mode, the screen inventory and the component map summary, and ask: "¿Ajustamos algo o seguimos a Technical Specs?"

## Quality Checklist

- ✅ Mode chosen from evidence and stated explicitly at the top
- ✅ Mode A: no new visual language introduced; new components reuse existing library and tokens; inconsistencies logged as debt, not silently changed
- ✅ Mode B: tokens defined for light and dark, mapped to Tailwind/shadcn variables
- ✅ Every key flow has a diagram with error paths
- ✅ Every screen in the inventory has role/permission, purpose and entry point
- ✅ Every key screen shows empty, loading, error and no-permission states
- ✅ Component map lists, for each UI element, the existing/shadcn component or a new component with props and states
- ✅ Accessibility requirements are concrete (contrast, keyboard, labels, target size)
- ✅ Usability test plan has tasks and success criteria
- ✅ Analytics events from the measurement plan are attached to the screens that fire them

## Dependencies & Context

**Used by:** sdlc-orchestrator (Stage 6)
**Inputs:** PRD (personas, epics), functional specs (flows, acceptance criteria), discovery brief, measurement plan (events), existing frontend code (Mode A)
**Feeds into:** `technical-specs` (component map → React component tree, tokens → styling setup), `test-strategy` (accessibility and visual states to test), `implementation-scaffolding` (Mode B stack setup)
**References:** react-standards.md (accessibility, component structure), security-rules.md (no sensitive data in mockups — use realistic but fake data)
**Output:** `[project-name]-ux-ui-design.md` + Design System / Design artifacts or token files and HTML mockups

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) + design artifacts
