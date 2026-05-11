# Plan Bullet Format

Load during Step 3 of `$taw`. Render exactly 3–5 bullets covering the dimensions below.

## Format

```
Plan:
1. <Stack> — <1-line description>
2. <Pages/Features> — <list of 3-5 items>
3. <Data/Integrations> — <DB tables + integrations>
4. <Run/Ship> — <preview, deploy, CLI command, job schedule, or docs output>
5. <Estimated time> — <minutes>
```

## Rules

- Bullets numbered 1–5 only. No `-` or `•`.
- Each line ≤ 90 characters.
- No emoji in bullets (save those for Step 8 "Done!").
- Simple English; keep framework names as-is (Next.js, Supabase, Expo, Python, etc.).

## Examples

**Landing page for an online course:**
```
Plan:
1. Next.js + Tailwind + shadcn/ui (lean stack, easy to edit)
2. 3 sections: hero + features + email form
3. Supabase stores email leads (table: `leads`)
4. Deploy to Vercel (or Docker / VPS on request), URL like <slug>.vercel.app
5. Estimated 10-15 minutes
```

**Online coffee shop:**
```
Plan:
1. Next.js + Tailwind + Supabase + Polar
2. 4 pages: home, menu, cart, thank-you
3. Tables: `products` (6 samples), `orders`, `customers`
4. Payments via Polar (cards) + COD, deploy to Vercel
5. Estimated 18-22 minutes
```

**CRM for a cosmetics shop:**
```
Plan:
1. Next.js + Tailwind + shadcn + Supabase auth
2. 2 pages: customer list, customer detail
3. Table: `customers` (name, phone, email, notes, tag, status)
4. CSV import + manual entry, deploy to Vercel
5. Estimated 12-15 minutes
```

**CLI utility for batch renaming files:**
```
Plan:
1. Node.js CLI script (no web UI)
2. Commands: preview, rename, rollback log
3. Reads local folders only; no database or external API
4. Run with `node bin/rename-files.js --dry-run`
5. Estimated 10-15 minutes
```

**Backend webhook receiver:**
```
Plan:
1. TypeScript API service using the existing backend stack
2. Endpoint: signed webhook receiver + retry-safe handler
3. Stores events in the existing database table
4. Verify with local curl smoke test, deploy target follows repo config
5. Estimated 15-20 minutes
```

## Anti-patterns (do NOT do)

- DO NOT list low-level tech (e.g. "using useState + useEffect...") — user doesn't need to know.
- DO NOT promise features the user didn't confirm (e.g. "dark mode" if not asked).
- DO NOT skip "Estimated time" — the user needs to know how long to wait.
