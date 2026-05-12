# taw-kit-codex

Global Codex skills for building, fixing, testing, refactoring, deploying, and maintaining real
software projects from plain-language prompts.

This is the OpenAI Codex port of [`taw-kit`](https://github.com/nghiahsgs/taw-kit). Install it
once and the skills are available globally in Codex from any repo.

```text
> $taw build a coffee shop website
  -> clarifies scope
  -> drafts a short plan
  -> builds the app
  -> runs checks
  -> reviews the result
  -> deploys when asked
```

## What It Is

`taw-kit-codex` is a user-level Codex plugin/skill pack:

- 47 bundled skills
- 6 internal agent roles
- one main entrypoint: `$taw`
- direct utility skills such as `$taw-commit`, `$taw-git`, `$taw-trace`, and `$taw-task-loop`
- stack-aware workflows for web, mobile, backend APIs, CLI tools, automation, data scripts, docs,
  and repo maintenance

The default install copies skills into:

```bash
~/.codex/skills/
```

That means the kit is global. You can open Codex inside any project and use `$taw` immediately.

## Install

Requirements:

- OpenAI Codex CLI
- Node.js 20+
- git
- macOS, Linux, or Windows via WSL2

Install globally:

```bash
git clone https://github.com/the-agents-work/taw-kit-codex.git ~/.taw-kit-codex
bash ~/.taw-kit-codex/scripts/install.sh
```

Install with Codex lifecycle hooks enabled:

```bash
TAW_INSTALL_HOOKS=1 bash ~/.taw-kit-codex/scripts/install.sh
```

Hooks enable session context and taw auto-commit checkpoints. The installer sets
`[features].codex_hooks = true`, writes/merges `~/.codex/hooks.json`, and copies hook scripts to
`~/.codex/plugins/taw/hooks/`. Existing hook entries are preserved.

Auto-commit can be disabled per shell:

```bash
export TAW_NO_AUTOCOMMIT=1
```

Update:

```bash
cd ~/.taw-kit-codex
git pull
bash scripts/install.sh
```

Developer mode with live symlinks:

```bash
TAW_SYMLINK=1 bash scripts/install.sh
```

Verify:

```bash
ls ~/.codex/skills | grep '^taw'
codex
```

Then type `$` in the Codex TUI. Codex should show `taw`, `taw-commit`, `taw-git`,
`taw-task-loop`, and the rest of the installed skills.

## How To Use It

Codex does not have custom slash commands. Use one of these patterns.

### 1. Explicit Skill Call

Use `$taw` when you want to force the main orchestrator:

```text
> $taw build a landing page for an online course
> $taw add a contact form
> $taw fix the build error
> $taw deploy to Vercel
> $taw refactor the backend safely; call APIs before and after
> $taw task-loop from this PRD until all tasks pass
```

### 2. Plain Language

You can also type naturally. Codex will usually trigger the right skill from the description:

```text
> build me a CRM dashboard
> this Next.js app is broken, fix it
> write Playwright tests for login
> refactor this backend API in small safe loops
```

### 3. Direct Utility Skills

Some skills are useful without the full `$taw` router:

```text
> $taw-commit
> $taw-git pr
> $taw-trace who changed this file
> $taw-task-loop run .taw/task-loop.json non stop
```

Do not use `@taw`. In Codex TUI, `@` is a file picker, not a skill mention.

## Main Workflows

| Workflow | Example |
|---|---|
| Build a new app/site/tool | `$taw build an inventory app` |
| Add a feature | `$taw add a booking form` |
| Fix a broken project | `$taw fix` |
| Deploy | `$taw deploy vercel` |
| Generate tests | `$taw test checkout flow` |
| Upgrade dependencies | `$taw upgrade next 15` |
| Clean dead code | `$taw clean` |
| Analyze performance | `$taw perf` |
| Roll back safely | `$taw rollback` |
| Refactor safely | `$taw refactor` |
| Sync generated types | `$taw types` |
| Seed data | `$taw seed Vietnamese sample data` |
| Security review | `$taw security` |
| Project status | `$taw status` |
| Long-running task queue | `$taw task-loop` |

## Backend API Refactor Loop

`$taw refactor` includes a safety-first backend mode for existing APIs.

Use it like this:

```text
> $taw refactor this backend safely.
> Base URL is http://localhost:3010.
> DB is MONGOOSE_URI=mongodb://localhost:27017/app_db.
> Create a refactor list, call APIs before and after every small refactor,
> wait for hot reload, and continue non stop.
```

The workflow is:

1. create or update `.taw/refactor-list.md`
2. pick a small low-risk slice
3. call a baseline API first
4. edit one small module/helper/route registry
5. wait for reload: 30s, then 60s, then 120s if needed
6. call the same API again
7. compare status/body/headers or stable semantic fields
8. run build/type checks
9. log the pass and continue

Local auth is supported. If the local DB and JWT secret are available, the workflow can mint a
temporary local token from an existing local user without printing the token.

## Ralph-Style Task Loop

The kit includes `$taw-task-loop`, inspired by Ralph-style long-running agents.

The idea:

- keep task state in `.taw/task-loop.json`
- keep progress in `.taw/task-loop-progress.md`
- use git commits as durable checkpoints
- complete one small verifiable task per loop
- run checks before marking `passes: true`
- continue until all safe tasks are passed or blocked

Example:

```text
> $taw-task-loop create a task queue from this PRD and run it non stop.
```

Default task shape:

```json
{
  "version": 1,
  "tasks": [
    {
      "id": "T001",
      "title": "Add unit tests for auth helpers",
      "priority": 100,
      "status": "pending",
      "passes": false,
      "checks": ["npm test -- auth"],
      "notes": ""
    }
  ]
}
```

This is best for small, easy-to-check work: tests, migrations, component splits, API refactors,
docs, lint cleanup, or one user story at a time.

## Stack Adaptation

The kit does not force one stack onto every project.

For new web apps, it may suggest the default taw stack: Next.js, Tailwind, shadcn/ui, Supabase,
and Polar. For existing projects, it detects and respects what is already there: Stripe, Clerk,
NextAuth, Prisma, Drizzle, Expo, Vite, Python, Docker, Playwright, Vitest, Jest, and more.

## Skill Catalog

Key user-facing skills:

- `taw` - main natural-language router
- `taw-commit` - scan/stage/commit with a conventional message
- `taw-git` - branches, PRs, merges, recovery
- `taw-trace` - git history lookup without remembering git commands
- `taw-task-loop` - JSON task queue loop for long-running work

Common specialist skills:

- `frontend-design`
- `nextjs-app-router`
- `building-native-ui`
- `testing-vitest`
- `testing-playwright`
- `github-actions-ci`
- `supabase-setup`
- `stripe-checkout`
- `payment-integration`
- `sentry-errors`
- `debug`
- `debug-flight-recorder`
- `docs-seeker`

Internal agent roles are bundled for taw orchestration:

- `agent-planner`
- `agent-researcher`
- `agent-fullstack-dev`
- `agent-mobile-dev`
- `agent-tester`
- `agent-reviewer`

## Notes For Claude Code Users

| Claude taw-kit | taw-kit-codex |
|---|---|
| `/taw ...` | `$taw ...` |
| `@` may mention agents/files depending on UI | `@` is a Codex file picker |
| `CLAUDE.md` memory | `AGENTS.md` / project memory depending on repo |
| Claude Code subagents | Codex skills and agent-style workflows |

## Contributing

Repo:

```text
https://github.com/the-agents-work/taw-kit-codex
```

Original Claude Code kit:

```text
https://github.com/nghiahsgs/taw-kit
```

License: Apache-2.0.
