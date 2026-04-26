---
name: taw-commit
description: >
  taw-kit's unified commit skill: stages files, scans for secrets/env/build-artefact
  leaks, generates a conventional commit message by READING the actual diff (not
  guessing), then commits. Two modes: CONTEXT mode (called by taw orchestrator —
  uses .taw/checkpoint.json phase info, writes strict [P<n>] format) and SMART
  mode (ad-hoc — infers type+scope+subject from diff content). Replaces the old
  git-auto-commit + commit-message-smart skills (merged). User never types git
  commands. Always prefixes output with "taw:" so you know which tool did it.
---

# taw-commit — Conventional Commits, taw-Branded

Every commit in a taw-kit project goes through THIS skill. Strict format + security scrub + diff-aware subject generation.

## Purpose

Every commit must be traceable to:
- the **phase** in `.taw/plan.md` (taw orchestrator BUILD branch, CONTEXT mode), OR
- the **feature** added (taw add-feature flow), OR
- the **error** fixed (taw FIX branch), OR
- **raw user intent** when called directly (SMART mode — reads diff).

Result: `git log --grep "(auth)"` or `git log --grep "\[P2\]"` returns exactly what you want, years later.

## Commit format (strict)

```
<type>(<scope>): <subject>

<optional body: 1-3 bullets of what changed and why>

<optional trailer: [P<n>] or Refs: <feature-id>>
```

- **type** — `feat | fix | chore | refactor | style | docs | test | perf | build | ci | revert`
- **scope** — kebab-case: `auth | shop | checkout | seo | env | db | ui | deploy | deps`
- **subject** — imperative, lowercase, ≤ 72 chars (soft limit 50), no trailing period, describes WHY not WHAT
- **phase tag** — `[P<n>]` only in CONTEXT mode (n = phase number from `.taw/plan.md`)

### Examples

```
feat(auth): add magic-link sign-in [P2]

- app/login/page.tsx: email form + Supabase signInWithOtp
- middleware.ts: protect /dashboard
- wired to SUPABASE_URL + SUPABASE_ANON_KEY

Refs: phase-2-authentication.md
```

```
fix(checkout): reject negative amount before Stripe call
```

```
chore(deps): bump next 14.2.3 → 15.0.1 with async cookies codemod
```

## Mode detection

```bash
if [ -f .taw/checkpoint.json ] && jq -e '.phase' .taw/checkpoint.json >/dev/null 2>&1; then
  MODE="context"
else
  MODE="smart"
fi
```

### CONTEXT mode (called by /taw orchestrator)

Read `.taw/checkpoint.json`:
```json
{ "phase": 2, "phase_file": "phase-2-authentication.md", "scope": "auth" }
```

Map `phase_file` → `scope` via first noun after phase number:
- `phase-2-authentication.md` → `auth`
- `phase-3-product-catalog.md` → `shop`
- `phase-4-checkout-stripe.md` → `checkout`

Append `[P<n>]` to subject.

### SMART mode (ad-hoc — no phase context)

Detect project's existing commit style first:
```bash
git log -20 --pretty=format:'%s'
```

| Pattern in history | Output style |
|---|---|
| `feat(scope): ...` / `fix(scope): ...` | Conventional Commits (full) |
| `feat: ...` / `fix: ...` | Conventional Commits (no scope) |
| `Add X`, `Fix Y`, `Update Z` | Imperative title-case |
| chaos | Default to Conventional — nudge team |

Use the detected style.

## Workflow

### Step 1 — Derive context + scope

**CONTEXT mode**: phase + scope from checkpoint.
**SMART mode**: infer scope from the largest diff directory:
- `app/shop/**` → `shop`
- `app/api/auth/**` → `auth`
- `components/ui/**` → `ui`
- `*.env*`, `next.config.*`, `tailwind.config.*` → `env` or `build`
- Multiple unrelated dirs → omit scope

### Step 2 — Pre-commit sanity (MANDATORY)

```bash
git add -A
git diff --cached --name-only > /tmp/taw-staged.txt
```

**Auto-unstage local-state paths** (these are NEVER meant for git):

```bash
for pat in '.claude/' '.claudebk/' '.taw/' '.expo/' '.expo-shared/' '.eas/' '.DS_Store' 'Thumbs.db' '*.log' '*.tsbuildinfo' 'node_modules/' '.next/' 'dist/' 'build/' 'ios/build/' 'android/build/' 'android/.gradle/' 'android/app/build/'; do
  files=$(git diff --cached --name-only | command grep -E "^${pat}" || true)
  if [ -n "$files" ]; then
    git reset HEAD -- $files >/dev/null 2>&1
    echo "taw: ↩ unstaged $pat (local-state, never commit)"
  fi
done
```

If 0 staged files left after unstage → abort: "taw: nothing to commit (all local state). Skipping." Exit 0.

**Filename blockers** — always unstage:

| Pattern | What it is |
|---|---|
| `.env`, `.env.local`, `.env.*.local` | Secrets |
| `*.key`, `*.pem`, `*.p12`, `*.pfx` | Private keys |
| `id_rsa`, `id_ed25519`, `id_ecdsa` | SSH keys |
| `credentials.json`, `service-account*.json` | Cloud IAM |
| `node_modules/**`, `.next/**`, `dist/**`, `out/**`, `build/**`, `.expo/**`, `ios/build/**`, `android/build/**` | Build artefacts |
| `.claude/**`, `.claudebk/**` | Codex CLI local state |
| `.taw/**` | taw-kit local state (intent, checkpoint, deploy) |
| `.DS_Store`, `Thumbs.db` | OS cruft |
| `*.log`, `*.tsbuildinfo` | Generated |

**Content blockers** — scan staged diff for secret patterns:

```bash
git diff --cached | command grep -InE "$CONTENT_PATTERN"
```

where `$CONTENT_PATTERN` combines these well-known tokens:

| Source | Pattern |
|---|---|
| AWS access key | `AKIA[0-9A-Z]{16}` |
| AWS secret assignment | `aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}` |
| GitHub PAT | `(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}` |
| OpenAI / Anthropic | `sk-[A-Za-z0-9]{20,}` |
| Google API key | `AIza[0-9A-Za-z\-_]{35}` |
| Slack token | `xox[abpr]-[0-9A-Za-z-]{10,}` |
| Stripe live key | `sk_live_[0-9A-Za-z]{24,}` |
| JWT | `eyJ[A-Za-z0-9_=-]{10,}\.eyJ[A-Za-z0-9_=-]{10,}\.[A-Za-z0-9_=\-]+` |
| PEM private key header | `-----BEGIN (RSA|EC|OPENSSH|PGP|DSA)? ?PRIVATE KEY-----` |
| DB URL with password | `(mongodb|postgres|postgresql|mysql|redis)://[^:]+:[^@]+@` |
| Supabase service role | `SUPABASE_SERVICE_ROLE_KEY[[:space:]]*=[[:space:]]*[A-Za-z0-9._-]+` |
| `password = "..."` | `(password|passwd|pwd)[[:space:]]*=[[:space:]]*['\"][^'\"]{6,}['\"]` |

On hit:
1. Print file + line (NOT the value): `taw: 🚨 secret pattern matched in <file>:<line>`
2. Unstage: `git reset HEAD <file>`
3. VN msg: "File `<path>` lộ secret ở dòng <n>. Đã unstage. Chuyển giá trị vào `.env.local` rồi commit lại."

### Step 3 — `.gitignore` maintenance (append-only)

Check `.gitignore`. If missing, create with minimum:
```gitignore
# Env / secrets
.env
.env.local
.env*.local
*.key
*.pem
*.p12
credentials.json
service-account*.json

# Web build artefacts
node_modules/
.next/
out/
dist/
build/
*.tsbuildinfo

# Mobile build artefacts
.expo/
.expo-shared/
ios/build/
android/build/
android/.gradle/
android/app/build/
.eas/

# Local state — NEVER commit (taw-kit, Codex CLI)
.claude/
.claudebk/
.taw/

# OS / IDE
.DS_Store
Thumbs.db
*.log
.idea/
.vscode/
```

**Append-only rule:** if `.gitignore` exists, do NOT overwrite. Read it, identify missing patterns, append with `# Added by taw-commit` comment separator.

### Step 4 — Generate subject (SMART mode or when hint missing)

Read `git diff --cached` fully. Classify the change:

**Type picking** (based on what diff ACTUALLY does):

| Type | Triggers |
|---|---|
| `feat` | NEW exports, new routes, new UI — adds functionality |
| `fix` | Adds guards, null-checks, corrects wrong logic/values, changes test assertions to pass |
| `refactor` | Rename/extract/move — same behaviour, different shape |
| `perf` | Bundle reduction, lazy loads, memoization, caching |
| `test` | Only `*.test.*` / `*.spec.*` touched |
| `docs` | Only `*.md`, comments, JSDoc |
| `style` | Whitespace/formatting only |
| `build` | `package.json` deps, lockfile, Dockerfile, tsconfig |
| `ci` | `.github/workflows/`, CI scripts |
| `chore` | Everything else housekeeping |
| `revert` | `Revert "..."` pattern |

**Subject rules:**
1. Imperative ("add login" not "added" / "adds")
2. No trailing period
3. Max 72 chars (soft 50)
4. Describe WHY / outcome, not WHAT (diff shows the what)
5. Lowercase first letter after `type(scope):`

| Bad | Good |
|---|---|
| `fix(auth): fixed bug` | `fix(auth): reject expired magic links before session create` |
| `feat(ui): updated button` | `feat(ui): add loading+disabled state to primary button` |
| `refactor: cleanup` | `refactor(cart): extract calcTotal into pure function` |
| `chore: stuff` | `chore(deps): bump next 14.2 → 15.0 with async cookies codemod` |

### Step 5 — Commit

HEREDOC to preserve body formatting:

```bash
git commit -m "$(cat <<'EOF'
feat(auth): add magic-link sign-in [P2]

- app/login/page.tsx: email form + Supabase signInWithOtp
- middleware.ts: protect /dashboard routes

Refs: phase-2-authentication.md
EOF
)"
```

### Step 6 — First-time setup (only if `git rev-parse` fails)

```bash
git init
git branch -M main
# Only set user.email / user.name if git config is empty — never override
```

### Step 7 — Output

Print ONE line in EN:
```
taw: committed feat(auth): add magic-link sign-in [P2] — abc1234
```

No long summary. The log speaks for itself.

## Type reference

| Type | When |
|---|---|
| `feat` | New user-visible feature or page |
| `fix` | Bug in existing feature |
| `chore` | Config, env, deps, housekeeping |
| `refactor` | Code restructure, no behaviour change |
| `style` | CSS/Tailwind/formatting only |
| `docs` | README, comments, `.taw/*.md` |
| `test` | Tests added/updated |
| `perf` | Performance improvement |
| `build` | Build system, bundler |
| `ci` | GitHub Actions, CI config |
| `revert` | Revert a prior commit (append `Reverts: <sha>`) |

## Safety rules

- NEVER `git commit --no-verify` unless user explicitly asks.
- NEVER `git commit --amend` on a pushed commit.
- NEVER force-push from this skill.
- If merge conflict markers exist → abort + VN msg: "taw: đang có conflict, sửa xong rồi chạy lại."
- Commit subject ALWAYS in English (convention — GitHub tooling expects EN).
- Body CAN be VN if project history uses VN.
- Breaking changes → REQUIRE `!` after type or `BREAKING CHANGE:` footer.

## Constraints

- Read diff FULLY before generating subject — no guessing from filenames
- Respect project's detected commit style (don't force Conventional if team uses something else)
- Scrub secrets BEFORE commit, not after
- Max 72 chars subject — hard limit, truncate aggressively
- Output prefix "taw:" in all user-visible strings — branding discipline
