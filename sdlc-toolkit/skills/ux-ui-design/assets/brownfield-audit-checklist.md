# Mode A — Existing Product: Design System Extraction Checklist

Goal: describe the design system the product **already has** (explicitly or implicitly) so new screens fit in. This is an audit, not a redesign.

## 1. Detect the stack

Look at `package.json` and the style folders. Record what you find:

| Area | Where to look | Example finding |
|---|---|---|
| CSS framework | `bootstrap`, `tailwindcss`, `@mui/material`, `antd`, `@chakra-ui/*` in dependencies | `bootstrap ^5.3`, `react-bootstrap ^2.8` |
| Styling approach | `sass`, CSS modules, styled-components, plain CSS | SCSS per component + global `scss/` |
| Theme overrides | `_variables.scss`, `_colors.scss`, `theme.ts`, `:root { --… }` | `src/scss/_colors.scss` with `$primary`, `$gray-*` |
| Icons | `react-icons`, `lucide-react`, `@fortawesome/*`, SVG folder | `react-icons` (which sets? fa, md, bi…) |
| Tables | `react-table`, `@tanstack/react-table`, `ag-grid` | `react-table v7` |
| Forms | `react-hook-form`, `formik`, custom | custom dynamic forms |
| Fonts | `index.html`, `@font-face`, `font-family` in global styles | |
| Dark mode | theme variables, `data-bs-theme`, `.dark` classes | partial (`$card-color`, `$darktheme-primary`) |

## 2. Extract tokens

Build a table per category with the **name in code**, the value, and where it's used. Don't invent names; reuse the code's names so engineers recognize them.

- **Color:** brand/primary, secondary, semantic (success, warning, danger, info), neutrals (gray scale), backgrounds, text colors, borders. Flag hard-coded hex values found in component styles that don't come from variables.
- **Typography:** font families, base size, heading sizes, weights, line heights.
- **Spacing:** framework scale (e.g., Bootstrap `$spacer` multiples) and any custom values.
- **Radius, shadows, z-index, breakpoints.**
- **Contrast check:** compute contrast of primary text/background pairs and primary buttons — record failures as accessibility debt.

## 3. Inventory components

For each component type, list the implementation(s) in use and where:

| Component | Implementation | Location | Variants in use | Notes |
|---|---|---|---|---|
| Button | react-bootstrap `Button` | everywhere | primary, outline-secondary, danger | |
| Modal | `components/modal/basic-modal` | | | wraps react-bootstrap Modal |
| Data table | react-table v7 + custom | `features/*/PatientTable` | | |
| Form field | | | | |
| Navigation | | | | |
| Alerts / toasts | | | | |
| Empty / loading states | | | | often missing — note it |

## 4. Record patterns

Recurring screen compositions to reuse in new designs:
- List page: header + filters + table + pagination + row actions
- Create/edit: form in page vs. in modal (which one does the product use, and when?)
- Destructive confirmation pattern
- Feedback pattern after save (toast? inline alert? redirect?)
- Navigation: sidebar/top bar, breadcrumbs, tabs

## 5. Log design debt (don't fix silently)

| Issue | Example | Impact | Suggested fix | Priority |
|---|---|---|---|---|
| Multiple styles for the same component | 3 different primary buttons | inconsistency | consolidate | Medium |
| Hard-coded colors | `#0068ff` in component SCSS | theming breaks | use `$primary` | Low |
| Accessibility gaps | low contrast, icons without labels | WCAG failure | | High |

New screens designed in this spec should not add to this list.

## 6. Rules for new screens in Mode A

- Use existing components and tokens first; if something new is needed, build it with the same library and tokens and add it to the inventory.
- Match existing patterns (if edit happens in modals everywhere, don't introduce a full-page edit without a reason).
- New screens must meet WCAG 2.2 AA even if old ones don't.
- Any change to the visual language (colors, typography, spacing scale) is a separate, explicit decision by the user.
