// Check that HTML mockups never scroll sideways at the widths that matter, and save screenshots.
//
// Usage:
//   node check-overflow.js <out-dir> <file-or-url> [<file-or-url> ...]
//   WIDTHS=1440,1024,768,390 node check-overflow.js shots mockups/*.html
//
// Needs Playwright (require('playwright') with a Chromium browser).
// For each page and width it prints the document scrollWidth; anything wider than the
// viewport is a FAIL (a table or grid is pushing the page). Tables should scroll inside
// their own wrapper (overflow-x: auto), never the page. Exits with code 1 on any FAIL.
// Pages that need a build step or a runtime (e.g. Claude Design artboards) must be
// rendered to plain HTML first; interactive states (drawers, dialogs) need a manual check.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [out, ...pages] = process.argv.slice(2);
if (!out || pages.length === 0) {
  console.log('Usage: node check-overflow.js <out-dir> <file-or-url> [...]');
  process.exit(2);
}
const widths = (process.env.WIDTHS || '1440,1024,768,390').split(',').map(Number);
fs.mkdirSync(out, { recursive: true });

(async () => {
  const browser = await chromium.launch();
  let failed = false;
  for (const p of pages) {
    const url = /^https?:|^file:/.test(p) ? p : 'file://' + path.resolve(p);
    const name = path.basename(p).replace(/\.[^.]+$/, '');
    for (const w of widths) {
      const page = await browser.newPage({ viewport: { width: w, height: 900 } });
      await page.goto(url, { waitUntil: 'networkidle' });
      const sw = await page.evaluate(() => document.documentElement.scrollWidth);
      const ok = sw <= w;
      failed ||= !ok;
      console.log(`${ok ? 'ok  ' : 'FAIL'} ${name} @${w}px scrollWidth=${sw}`);
      await page.screenshot({ path: path.join(out, `${name}-${w}.png`), fullPage: w < 1024 });
      await page.close();
    }
  }
  await browser.close();
  process.exit(failed ? 1 : 0);
})();
