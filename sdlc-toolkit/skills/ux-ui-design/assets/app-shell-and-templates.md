# App Shell, Screen Templates and Responsive Rules

Lessons from designing data-dense back-office products (billing, inventory, clinical). Read this before drawing the first screen. Each rule fixes a problem that users noticed on real reviews.

## 1. Validate the style before designing many screens

Start with 3 or 4 representative screens: the main daily task, a list, a form and the login. Use them to agree on colors, type, density and the app shell. Only then draw the rest. Changing a color on 4 artboards is cheap. Changing it on 20 is not.

## 2. Decide screen coverage: templates plus custom screens

Products migrated from a legacy system often have 50 to 100 menu options. Most of them repeat four shapes. Don't draw every option; propose this and let the user decide:

| Template | Covers | Must show |
|---|---|---|
| **List with filters** | Masters and catalogs (payers, products, users, codes…) | Filter bar, paginated table, row actions, New, export; empty, loading and no-permission states |
| **Form** | Create and edit of each master, settings | Sections as cards, fields in an auto-fit grid, required mark and legend, error under the field, sticky Save bar with shortcut |
| **Report with totals** | Queries and reports | Required date range, filters, group by, subtotals and grand total, XLSX/CSV/PDF export; audit reports add a "Fix" action per row |
| **Step wizard / file import** | Initial data loads, opening a new site, bulk uploads, period tools | Numbered steps with state, file summary (valid vs. error rows), downloadable error table, "nothing is saved until the last step" |

Then draw **custom screens only where the risk is**: the main transaction (for example dispense and invoice), its confirmation and printout, and the irreversible or regulated actions (void with credit note, group billing, regulatory files, stock entry with lots, permissions). In the spec, add a coverage table that maps every legacy option to a template or a custom screen, so nothing is left without a design.

## 3. App shell: the same frame on every screen

Users notice when the frame moves between screens. They read it as "a different product".

- **One shared shell.** Build the top bar, sidebar and content frame once (a shared stylesheet or component on the canvas) and reuse it on every artboard. Copying the markup by hand makes widths and spacing drift.
- **Fixed sidebar width** (for example 240 px, `flex: 0 0 240px`). Never let it size to its content. Long labels must not make it wider on one screen than on another.
- **Long menus: module tabs, short sidebar and hubs.**
  - Put modules as tabs in the top bar, so the sidebar only shows the current module's options (4 to 10).
  - Options with many variants (reports, voids, catalogs, masters, tools) open a *hub*: a grid of cards with title and one-line description. A count next to the sidebar entry says how many it holds.
  - A flat sidebar with 40 entries is the first thing users complain about.
- **Icons on every navigation entry, from one set** (lucide for shadcn). Either every screen has icons or none does; mixing them reads as unfinished.
- **The active place is always visible.** Mark the active tab and the active sidebar entry with `aria-current="page"`, and show breadcrumbs (Module / Option / Document) on every page.
- **Top bar breathing room.** Give the top bar vertical padding (8 to 12 px). The search box must not touch the top edge, on desktop or mobile.
- **Global search** (`Ctrl K`) finds both records (patients, documents) and menu options.
- **Show only what the profile allows.** Hide options the user can't use instead of showing them disabled. The server still enforces the permission.

## 4. Responsive rules

Back-office users work on desktop, but someone will open it on a phone or tablet. Design for that from the first screen and verify it.

- **Breakpoint at 1024 px.**
  - Below it, hide the tabs and the sidebar and show a ☰ button that opens a side Sheet (about 300 px).
  - Inside the Sheet, put modules as pills and the current module's options as a list.
  - Never turn the menu into a horizontal strip of options; it becomes too long.
- **Top bar on mobile:** wraps into 3 rows (brand and user / site selector / search at full width). Hide the user's name and keep the icon.
- **Grids:** use `repeat(auto-fit, minmax(200px, 1fr))` for field grids. Use `flex-wrap` with a large `flex-grow` for main and side columns (main about 520 px minimum, side about 300 px), so they stack on small screens.
- **Tables:** give them a minimum width (640 px, wider for editable tables) inside a wrapper with `overflow-x: auto`. The table scrolls, the page never does.
- **When the side column steals too much width** from a wide table (7 or more columns or editable cells), put the table at full width and move totals and actions below, aligned right.
- **Verify, don't assume.** Run `scripts/check-overflow.js` at 1440, 1024, 768 and 390 px. `document.scrollWidth` must equal the viewport width. Check interactive states (drawer open, dialog open) by hand.

## 5. Patterns for transactions

- **Irreversible or external actions** (issue an invoice, send to the tax authority, void) get a confirmation dialog that lists the consequences in plain words.
  - The dialog names the amount and what happens to stock.
  - For the most dangerous actions, ask the user to type a word (for example ANULAR) to confirm.
- **Disabled buttons explain why,** with visible text and `aria-describedby`, for example: "Se habilita cuando la validación no tenga errores".
- **Errors live next to the cause:** inline under the field or in the table cell, plus one summary alert at the top. The alert has a title that says what to do and text that says how.
- **Status is never color alone.** Semantic colors often have similar luminance (success green vs. destructive red). Every status badge has text, and every alert has an icon and a title. Run `scripts/check-contrast.py` with a `distinct` list to catch this.
- **Item history.** When a document can change after it is issued (pending items delivered later), show a timeline with who did what and when.
- **Artboard states as tweaks.** For screens with a before/after (confirming vs. done), add a property on the artboard to switch states instead of drawing two artboards that drift apart.

## 6. Printed outputs

If the product prints receipts or tickets, design them as screens too.

- Thermal printers are usually 80 mm wide (about 302 px at 96 dpi). Use the monospace font at 11 to 12 px.
- The receipt carries the legal header, the items (with pending ones marked), the totals, the electronic-invoice code and QR, and who served the customer.
- Plan a dedicated print route with `@page { size: 80mm auto; margin: 0 }` and a letter-size PDF as fallback.
- Ask early which printer model is used and whether the browser can print to it directly or a local agent is needed.

## 7. Close with open decisions, not assumptions

While designing you will make business assumptions. Examples: whether pending items are billed on the day of the visit, whether an accepted invoice can still be edited, whether billing uses a fixed or a computed amount. Draw the most likely option, say so on the screen's notes, and list every assumption in the spec's **Open decisions** section for the product owner. Do the same for missing brand assets (logo, colors) and hardware (barcode scanner, printer, shared PCs).
