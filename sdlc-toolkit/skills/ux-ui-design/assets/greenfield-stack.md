# Mode B — New Product: Recommended UI Stack

## Why this stack

| Choice | Why |
|---|---|
| **React + TypeScript** | Consistent with `references/react-standards.md`; types catch prop mistakes in components |
| **Tailwind CSS** | Tokens become utility classes; no growing pile of one-off CSS files; very well understood by coding agents |
| **shadcn/ui** (Radix primitives) | Components are copied into the repo, so the team owns and can change them; Radix gives keyboard and screen-reader behavior out of the box; theming via CSS variables |
| **lucide-react** | Default icon set of shadcn/ui; consistent stroke style |
| **TanStack Table** | Headless, typed data grids with sorting, filtering, pagination, column visibility — essential for data-dense apps |
| **React Hook Form + Zod** | Performant forms; one Zod schema validates on client and documents the contract |
| **Sonner** (toasts), **date-fns** (dates, with `es` locale) | Small, well-maintained |

Alternative when the team wants more batteries included (complex date pickers, rich inputs, notifications) with less assembly: **Mantine**. Pick one; don't mix component libraries.

## Tokens → CSS variables → Tailwind

Define color roles, not raw colors, so components never reference a hex value directly. shadcn/ui uses this convention:

```css
/* src/styles/tokens.css */
:root {
  --background: 0 0% 100%;
  --foreground: 222 47% 11%;
  --primary: 217 91% 50%;
  --primary-foreground: 0 0% 100%;
  --secondary: 215 20% 94%;
  --secondary-foreground: 222 47% 11%;
  --muted: 215 20% 96%;
  --muted-foreground: 215 16% 40%;
  --accent: 215 20% 94%;
  --accent-foreground: 222 47% 11%;
  --destructive: 0 72% 51%;
  --destructive-foreground: 0 0% 100%;
  --success: 142 64% 36%;
  --warning: 38 92% 45%;
  --info: 199 89% 40%;
  --border: 214 32% 88%;
  --input: 214 32% 88%;
  --ring: 217 91% 50%;
  --radius: 0.5rem;
}

.dark {
  --background: 222 47% 8%;
  --foreground: 210 40% 96%;
  --primary: 217 91% 62%;
  --primary-foreground: 222 47% 8%;
  /* …same roles, dark values; re-check contrast */
}
```

Values above are placeholders — derive them from the brand and verify contrast (text ≥ 4.5:1, UI components ≥ 3:1) in both themes. Newer shadcn/ui versions may use OKLCH values and Tailwind v4 `@theme` syntax; follow the version you install.

## Base component set (install from shadcn/ui)

Button, Input, Textarea, Select, Combobox (Command + Popover), Checkbox, Radio Group, Switch, Date Picker (Calendar + Popover), Form, Label, Dialog, Alert Dialog (destructive confirmations), Sheet (side panels), Tabs, Table + Data Table, Pagination, Badge, Alert, Toast (Sonner), Skeleton (loading), Tooltip, Dropdown Menu, Breadcrumb, Sidebar, Card, Separator, Avatar.

Custom components to expect in data-dense apps (build on top of the above): `EmptyState`, `PageHeader` (title + actions + breadcrumb), `FilterBar`, `FormSection` (titled group with description), `ReadOnlyField`, `StatusBadge` (domain states), `ConfirmAction`.

## Setup checklist

- [ ] Vite + React + TS project (or the framework chosen in technical specs)
- [ ] Tailwind + shadcn/ui init; tokens file imported globally
- [ ] Light/dark theme toggle with system preference default
- [ ] Font chosen deliberately (not a default); loaded with `font-display: swap`
- [ ] `eslint-plugin-jsx-a11y` and axe checks in tests (see test-strategy)
- [ ] Storybook (optional) mirroring the Design System artifact for component review
- [ ] Impeccable installed and taught the project's design context
