# taw-kit-codex Skills Catalog

This directory contains the skills installed by `scripts/install.sh` into `~/.codex/skills`.

Current bundle:

- 47 skills
- 6 internal agent roles
- one main user entrypoint: `taw`

## Primary User-Facing Skills

| Skill | Purpose |
|---|---|
| `taw` | Main natural-language router for build/fix/deploy/test/refactor/review workflows |
| `taw-commit` | Stage, scan, generate a conventional commit message, and commit |
| `taw-git` | Branches, PRs, merges, and safe git recovery |
| `taw-trace` | Read git history by feature, file, phase, or commit |
| `taw-task-loop` | Ralph-style JSON task queue loop with checks, commits, and progress tracking |

## Agent Roles

| Skill | Purpose |
|---|---|
| `agent-planner` | Decompose product intent into build phases |
| `agent-researcher` | Fetch focused documentation |
| `agent-fullstack-dev` | Build web/backend/CLI/data/docs work |
| `agent-mobile-dev` | Build Expo React Native work |
| `agent-tester` | Run build/smoke checks and translate errors |
| `agent-reviewer` | Quick security and quality review |

## Specialist Skills

The rest of the directory contains focused implementation skills for auth, forms, payments,
Supabase, Stripe, testing, Playwright, GitHub Actions, Expo, frontend design, debugging, SEO,
Sentry, dependency upgrades, bundle analysis, cleanup, and project memory.

Codex discovers these by their `SKILL.md` frontmatter after installation.
