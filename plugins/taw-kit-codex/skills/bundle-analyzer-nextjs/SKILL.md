---
name: bundle-analyzer-nextjs
description: >
  Analyze and reduce Next.js JavaScript bundle size. Covers @next/bundle-analyzer
  setup, interpreting the report, and the common fixes (dynamic imports,
  replacing heavy libs, tree-shaking). Used by branches/maintain/perf.md.
  Trigger phrases (EN + VN): "bundle size", "bundle analyzer", "giam bundle",
  "first load js", "giam size", "toi uu bundle".
---

# bundle-analyzer-nextjs — Shrink the Client JS

## Step 0 — Detect existing setup

Check `next.config.{js,mjs,ts}`:
```bash
grep -l '@next/bundle-analyzer' next.config.* 2>/dev/null
```

If already wired, skip Step 1 — just run.

## Step 1 — Install + wire (new)

```bash
npm install -D @next/bundle-analyzer cross-env
```

Edit `next.config.mjs` (preferred for Next 14+):
```js
import bundleAnalyzer from '@next/bundle-analyzer'

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
})

/** @type {import('next').NextConfig} */
const nextConfig = {
  // ... your existing config
}

export default withBundleAnalyzer(nextConfig)
```

Add script to `package.json`:
```json
"analyze": "cross-env ANALYZE=true next build"
```

## Step 2 — Run the analyzer

```bash
npm run analyze
```

After build, three HTML reports open in browser:
- `client.html` — JS shipped to browser (the one you care about most)
- `edge.html` — runtime on edge functions
- `nodejs.html` — SSR-only bundles

Each treemap: rectangle size = gzipped bytes. Hover to see exact size.

## Step 3 — Interpret the report

**Healthy Next.js First Load JS:** <150 KB gzipped shared + <200 KB per route.

**Warning signs:**
- Any single package >50 KB → candidate for dynamic import
- `moment.js`, full `lodash`, `@fortawesome/fontawesome-free`, full `antd`, `chart.js` → known bundle hogs
- Duplicate copies of React / any package → usually a peer-dep mismatch

## Step 4 — Standard fixes (in order of impact)

### Replace heavy libs

| Remove | Use instead | Saves |
|---|---|---|
| `moment` | `date-fns` or `dayjs` | ~60 KB |
| `lodash` (full) | `lodash-es` + named imports | ~50 KB |
| `axios` | native `fetch` | ~15 KB |
| `chart.js` (full) | `uPlot` or `recharts` lean build | ~40 KB |
| `formik` | `react-hook-form` | ~30 KB |
| `@fortawesome/fontawesome-free` | `lucide-react` (per-icon) | ~80 KB |
| full `antd` | `shadcn/ui` + `radix` | ~200 KB |

Codemod example (lodash):
```bash
# from
import _ from 'lodash'
_.debounce(fn, 300)

# to
import debounce from 'lodash/debounce'
debounce(fn, 300)
```

### Dynamic import heavy components

For charts, editors, maps, modals (used conditionally):
```tsx
import dynamic from 'next/dynamic'
const Chart = dynamic(() => import('@/components/Chart'), { ssr: false, loading: () => <p>…</p> })
```

Also dynamic-import heavy client-only libs:
```tsx
// lazy load monaco editor only when user clicks "Edit code"
const MonacoEditor = dynamic(() => import('@monaco-editor/react'), { ssr: false })
```

### Tree-shake barrel imports

If you see `icons/index.ts` dragging in 500 unused icons, use per-file imports:
```tsx
// from (bad — whole barrel)
import { CheckIcon } from '@/icons'
// to (good — direct path)
import { CheckIcon } from '@/icons/check'
```

### next/image for static assets

`<img>` with raw URLs ship the full asset. `next/image` lazy-loads, auto-resizes, modern format:
```tsx
import Image from 'next/image'
<Image src="/hero.jpg" width={1200} height={600} alt="" priority />
```

### Server vs Client components

Move data-fetching + formatting code to Server Components (zero client JS):
```tsx
// app/page.tsx — Server Component (default in App Router)
export default async function Page() {
  const data = await fetchData()
  return <View data={data} />  // View can be 'use client' only if truly interactive
}
```

Check that `'use client'` directives aren't accidentally at the top of a large tree — each one expands the client bundle.

### Font loading

Use `next/font` (hosts fonts at build time, no runtime FOIT):
```tsx
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'], display: 'swap' })
```

## Step 5 — Verify savings

Re-run `npm run analyze`, compare First Load JS numbers. Report (VN):
```
Bundle before → after:
  First Load JS: 487 KB → 321 KB (-34%)
  /dashboard:    312 KB → 198 KB (-37%)

Top reductions:
  moment → date-fns:        -62 KB
  lazy load chart:          -48 KB
  barrel → direct imports:  -18 KB
```

## Gotchas

- **`use client` on a parent** — every child becomes a client component; move `'use client'` down to the leaf that actually needs interactivity
- **Importing from `@/components/index.ts`** barrels — breaks tree-shaking for many setups; prefer explicit paths
- **`process.env.X`** in client code — value is inlined, entire client bundle re-built; make sure you don't leak secrets (NEXT_PUBLIC_ prefix only for truly public)
- **Bundle-analyzer not opening** → run with `BROWSER=none npm run analyze` to skip auto-open, then open HTML manually

## Constraints

- Don't install analyzer permanently if user doesn't want it — `npx` one-shot works
- Never change visual behaviour while shrinking bundle — perf fix != refactor
- Compare sizes in gzipped form — `.next/analyze/__client.html` shows both; use gzipped column
- `First Load JS` is the number that matters most for TTI / LCP
