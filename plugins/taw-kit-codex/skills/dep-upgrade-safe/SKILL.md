---
name: dep-upgrade-safe
description: 'Safe dep upgrade refs (Next.js/React/Supabase/Tailwind/TS/shadcn) + codemods + safety protocol. Triggers: "breaking change", "codemod", "upgrade next", "upgrade react", "nang cap", "cap nhat deps", "migration guide".'
---

# dep-upgrade-safe — Breaking Change Cheatsheet

## Step 0 — Detect what's installed

Read `package.json`:
```bash
node -e "const p=require('./package.json'); console.log(JSON.stringify({...p.dependencies,...p.devDependencies},null,2))"
```

Match versions. Map to the relevant section below.

## Safety protocol (run for ANY upgrade)

1. `git status --porcelain` → must be clean. If not, commit/stash.
2. `git rev-parse HEAD > .taw/upgrade-sha.txt` → snapshot for rollback.
3. Run upgrade.
4. Run `npm run build && npm test 2>/dev/null || true && npx tsc --noEmit 2>/dev/null || true`.
5. Red → `git reset --hard $(cat .taw/upgrade-sha.txt) && npm install` to revert.
6. Green → `taw-commit` with `type=chore, scope=deps`.

## Next.js

### 14 → 15

Codemod:
```bash
npx @next/codemod@latest upgrade latest
```

Breaking changes to apply manually if codemod misses:
- `cookies()`, `headers()`, `params`, `searchParams` are now **async** → must `await`
- Fetch caching default changed from `force-cache` to `no-store` — add `{ cache: 'force-cache' }` where you relied on old default
- `geo` + `ip` removed from `NextRequest` → use `@vercel/functions` helpers
- Minimum Node bumped to 18.18

### 13 → 14

Breaking:
- Server Actions now stable (no more `experimental.serverActions` flag) → remove from next.config
- Dynamic metadata re-generates on each request — if expensive, memoize
- `<Image>` default `loader` behaviour changed on custom hosts

## React

### 18 → 19

Codemod:
```bash
npx codemod@latest react/19/migration-recipe
```

Key changes:
- `useFormState` → `useActionState`
- `forwardRef` no longer needed for function components using ref as prop (but still works)
- `useTransition` callback can now return a value
- `<form action>` accepts a function directly
- Deprecated: `propTypes`, `defaultProps` on function components (use TS types)

### 17 → 18

Codemod:
```bash
npx codemod@latest react/18/replace-render-with-create-root
```

Key: Strict mode double-invokes effects in dev; if your code assumed single-invoke, fix it.

## @supabase/supabase-js

### 1.x → 2.x (major)

- Import path: `import { createClient } from '@supabase/supabase-js'` (unchanged)
- `.rpc()` returns `{ data, error }` shape (was just `data` in v1)
- Realtime API moved under `.channel()` — old `.from().on()` removed
- Auth helpers split: use `@supabase/ssr` for Next.js instead of `@supabase/auth-helpers-nextjs` (which is deprecated)
- Row types now strongly typed via `Database` generic

Migration:
```ts
// old (v1)
supabase.from('table').on('INSERT', handler).subscribe()
// new (v2)
supabase.channel('x').on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'table' }, handler).subscribe()
```

### auth-helpers-nextjs → @supabase/ssr

```bash
npm uninstall @supabase/auth-helpers-nextjs
npm install @supabase/ssr
```

Replace `createServerComponentClient` / `createRouteHandlerClient` with `createServerClient`. Cookie handling now explicit.

## Tailwind CSS

### 3 → 4

Codemod:
```bash
npx @tailwindcss/upgrade@latest
```

Breaking:
- Config is now CSS-native via `@theme` blocks, not `tailwind.config.ts` — codemod auto-migrates
- PostCSS plugin is now `@tailwindcss/postcss` (separate package)
- `@apply` still works but prefer inline utilities
- Some utility classes renamed: `shadow-sm` → `shadow-xs`, `outline-none` → `outline-hidden` (retain old behaviour)

## TypeScript

### 5.0 → 5.x

Usually non-breaking between minors. Run `npx tsc --noEmit` after each bump.

### 4 → 5

- `moduleResolution: "bundler"` is recommended for modern bundlers
- Decorators are now stage 3 standard (remove `experimentalDecorators` if possible)
- Stricter enum handling

## shadcn/ui (copy-paste components)

shadcn isn't a versioned npm package — the CLI (`shadcn` or `shadcn-ui`) updates individual components:
```bash
npx shadcn@latest diff button  # see what changed
npx shadcn@latest add button --overwrite  # apply update
```

After upgrading shadcn CLI itself to a new major, re-run for each component you have. Keep a list in `components.json`.

## drizzle-orm

### Migration protocol
```bash
npx drizzle-kit check      # warns about pending migrations
npx drizzle-kit generate   # after schema changes
npx drizzle-kit push       # apply (dev only)
npx drizzle-kit migrate    # apply via migration files (prod)
```

Never mix `push` and `migrate` on the same DB — pick one strategy.

### Major bumps
Drizzle is still 0.x — minor bumps can include breaking column-type changes. Read the CHANGELOG before bumping.

## Generic tips

- **Peer dep conflicts** (`ERESOLVE`) → don't use `--legacy-peer-deps` silently. Resolve: bump the outer dep that's pinning the inner.
- **Lockfile drift** → after any upgrade, delete `node_modules` + `package-lock.json` and reinstall if lockfile seems inconsistent.
- **CI passes, prod breaks** → CI and prod might differ in Node version. Pin Node via `.nvmrc` or `engines` in package.json.

## Constraints

- Never bump a major without showing breaking-change summary to user first
- Snapshot git SHA BEFORE install — revert path must be frictionless
- Prefer `npm-check-updates` over manual editing — it also handles peer ranges
- Don't upgrade multiple majors in one commit — do `react` first, verify, commit; then `next`, verify, commit
