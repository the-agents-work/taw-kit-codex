# taw-kit-codex — AGENTS.md

You are running inside a project that has the **taw-kit-codex** plugin installed.

## What this plugin gives you

A bundle of ~40 Vietnamese-friendly skills + 6 agent-role skills + 3 lifecycle hooks. Designed for non-developer users who describe their product idea in Vietnamese (or English) and expect a real, deployable Next.js / Expo app at the end.

## Single entrypoint: the `taw` skill

Two ways the user invokes `taw`:

**A) Auto-trigger via prose** (preferred — no special syntax). When the user types prose like:

- `lam cho toi mot landing page ban ca phe` (build a coffee landing page)
- `them trang lien he` (add a contact page)
- `fix loi build` (fix the build error)
- `deploy len vercel`
- `test cai login`
- `nang cap next len 15` (upgrade Next.js to 15)
- `don code` (clean dead code)
- `lui lai ban hom qua` (rollback to yesterday's version)
- `kiem tra bao mat` (security audit)

→ match against the `taw` skill description and fire it.

**B) Explicit prose invocation** (e.g. `dung skill taw de lam cho toi shop ca phe`, `use the taw skill to add a contact form`). When the user names the skill in prose, invoke `taw` regardless of how plain the rest looks.

Codex CLI does NOT support custom user-defined slash commands (so no `/taw`) and the `@` prefix in the TUI is a file-picker, not a skill mention. There is no special prefix — the user types prose and either auto-trigger or explicit naming routes them to the `taw` skill.

In both cases: the `taw` skill classifies intent (BUILD / FIX / SHIP / MAINTAIN / ADVISOR) and loads exactly one branch file from `skills/taw/branches/` to execute. Do not try to do the work directly — load the branch file first, then follow it step-by-step.

## Language rule (HARD)

Detect the language of the user's input. If they write Vietnamese (or VN-style mixed text like `lam cho tui cai web`), reply 100% in Vietnamese — friendly, conversational, Southern style. If English, reply in English. Default to Vietnamese for ambiguous/short input. Internal reasoning + agent-internal output stays English (see `terse-internal` skill).

## Codex-specific notes (vs original Claude Code taw-kit)

- **Subagents**: original ran `agent-planner`, `agent-researcher` x2, `agent-fullstack-dev`, `agent-tester`, `agent-reviewer` in a chain with parallel researchers. Codex CLI runs them **sequentially in-context** by invoking each `agent-*` skill. Total time ~30-60s slower; functionality identical.
- **Hooks**: lifecycle hook JSON shape matches Claude Code 1:1 (`PreToolUse`, `PostToolUse`, `SessionStart`, etc.). All three taw-kit hooks ported as-is.
- **Slash commands**: Codex does not support custom user-defined slash commands, and the `@` prefix in the TUI is a file-picker (not a skill mention). Trigger the `taw` skill via prose match alone — either implicit ("lam cho toi shop ca phe") or explicit ("dung skill taw de lam shop ca phe").
- **Settings**: replaced Claude `settings.json` with Codex `~/.codex/config.toml` — see `docs/install.md`.

## Skill discovery priority

Codex looks for skills in (highest to lowest):

1. `$CWD/.agents/skills/` and parent dirs up to repo root
2. `$REPO_ROOT/.agents/skills/`
3. `$HOME/.codex/skills/` (where this plugin's skills land after install)
4. `/etc/codex/skills/`

A project-local skill of the same name overrides this plugin's version. Use that for per-project customization.

## State files written by `taw`

- `.taw/intent.json` — what the user wants (parsed from prose + clarifications)
- `.taw/plan.md` — the 3-5 bullet plan shown to user for approval
- `.taw/checkpoint.json` — last completed step + next-action hint for crash recovery
- `.taw/design.json` — design tokens picked during BUILD by `frontend-design` consult
- `plans/<timestamp>-<slug>/` — full plan + numbered phase files written by `agent-planner`

## Don't

- Don't bypass the `taw` orchestrator and start coding directly when user gives free-form prose. Always classify → branch file → execute.
- Don't reply in English to a Vietnamese user.
- Don't skip the approval gate in SAFE mode. The user trades 1 message for the right to course-correct before 5 minutes of work.
- Don't auto-install npm packages without asking unless the BUILD branch is actively scaffolding a new project.
