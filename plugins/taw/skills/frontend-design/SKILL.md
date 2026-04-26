---
name: frontend-design
description: 'Distinctive, production-grade frontend UIs that avoid generic AI aesthetics. Triggers: "build web component", "landing page", "dashboard UI", "react component", "lam giao dien", "thiet ke", "cho dep", "anti AI slop".'
license: Complete terms in LICENSE.txt
---

This skill guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Apply creative forms like gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

---

## HARD RULE — Vietnamese diacritic support (taw-kit-codex override)

**WHY:** taw-kit-codex projects default to Vietnamese audiences. Many "designer" display fonts on Google Fonts (Bodoni, Cooper, Tiempos, Yeseva One, Abril Fatface, etc.) ship Latin glyphs only — when used for VN text, the browser falls back to the system font for diacritics (`Ư`, `Ờ`, `Ạ`, `ặ`, `ự`...). Result: dấu thanh trôi tách khỏi chữ, kerning vỡ, "NGƯỜI" hiển thị thành "NGƯ" + "ỜI" rõ rệt. Looks broken.

**RULE 1 — Pick from this VN-safe Google Fonts shortlist** (every font here has full Vietnamese subset, verified):

**Body / sans:**
- `Be Vietnam Pro` — designed-in-VN, the safest bet
- `Inter`, `Plus Jakarta Sans`, `Manrope`, `DM Sans`
- `Public Sans`, `Source Sans 3`, `IBM Plex Sans`
- `Noto Sans` (universal — works for any script)

**Body / serif:**
- `Lora`, `Source Serif 4`, `IBM Plex Serif`
- `Noto Serif`

**Display (headings) — distinctive AND VN-safe:**
- `Bricolage Grotesque` — modern, characterful
- `Be Vietnam Pro` (heavier weights for display)
- `Fraunces` (variable serif, full VN)
- `Bodoni Moda` (NOT plain "Bodoni" — Moda has VN, plain Bodoni doesn't)
- `Playfair Display` (VN partial — verify before commit)
- `DM Serif Display`, `IBM Plex Serif`
- `Sora`, `Outfit`

**AVOID for VN projects** (no VN diacritics):
- `Cooper Hewitt`, `Tiempos`, `Bodoni*` (the plain ones), `Didot`, `Cinzel`
- `Abril Fatface`, `Yeseva One`, `Fjalla One`, `Bevan`
- Most "novelty" / single-style display fonts
- Web-safe fallbacks like `Times New Roman`, `Georgia` (technically work but ugly for VN — use Noto Serif instead)

**RULE 2 — Always specify the `vietnamese` subset when using `next/font`:**

```ts
// ✓ CORRECT
import { Be_Vietnam_Pro, Bricolage_Grotesque } from 'next/font/google'

const sans = Be_Vietnam_Pro({
  subsets: ['vietnamese', 'latin'],   // ← MUST include 'vietnamese'
  weight: ['400', '500', '700'],
  variable: '--font-sans',
})

const display = Bricolage_Grotesque({
  subsets: ['vietnamese', 'latin'],
  variable: '--font-display',
})
```

```ts
// ✗ WRONG — defaults to 'latin' only, VN diacritics fall back to system font
const sans = Be_Vietnam_Pro({ weight: ['400', '700'] })
```

**RULE 3 — For raw `<link>` tags, request the `vietnamese` subset explicitly:**

```html
<!-- ✓ CORRECT -->
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;700&display=swap&subset=vietnamese,latin" rel="stylesheet">

<!-- ✗ WRONG — no subset param, gets latin only -->
<link href="https://fonts.googleapis.com/css2?family=Bodoni+Moda&display=swap" rel="stylesheet">
```

**RULE 4 — Verify before commit:**

Before declaring the design done, render a VN-heavy headline like "NGƯỜI MÊ HƯƠNG CÀ PHÊ THẬT" or "ĐƯỢC YÊU THÍCH NHẤT" and visually confirm dấu (`Ư Ờ Ậ Ặ ự ữ ặ`) sit ON the base letter, not floating above/beside it. If you can't render in browser, search the chosen font's Google Fonts page for "Vietnamese" in the language list — if it's not there, swap.

**RULE 5 — When in doubt, pair with `Be Vietnam Pro`:**

Created specifically for Vietnamese typography. Ships 14 weights including italic. Works as both body and display. If user wants "safe + elegant", default to it.
