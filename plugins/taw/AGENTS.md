# taw-kit-codex — AGENTS.md

You are running inside a project that has the **taw-kit-codex** plugin installed.

## What this plugin gives you

A bundle of 46 Vietnamese-friendly skills + 6 agent-role skills + 3 lifecycle hooks. Designed for users who describe software work in Vietnamese (or English) and expect a real result: web app, mobile app, backend API, CLI, automation script, data/reporting tool, docs, or repo workflow.

## Single entrypoint: the `taw` skill

Three ways the user invokes `taw`:

**A) Auto-trigger via prose** (preferred — no special syntax). When the user types prose like:

- `lam cho toi mot landing page ban ca phe` (build a coffee landing page)
- `viet tool CLI doi ten file hang loat`
- `lam backend API nhan webhook`
- `lam app mobile quan ly kho`
- `them trang lien he` (add a contact page)
- `fix loi build` (fix the build error)
- `deploy len vercel`
- `test cai login`
- `nang cap next len 15` (upgrade Next.js to 15)
- `don code` (clean dead code)
- `lui lai ban hom qua` (rollback to yesterday's version)
- `kiem tra bao mat` (security audit)

→ match against the `taw` skill description and fire it.

**B) Explicit `$taw` token** (Codex's native explicit-skill syntax, equivalent to Claude Code's `/taw`). Per Codex source code (`core-skills/src/render.rs`): *"If the user names a skill (with `$SkillName` or plain text), you must use that skill for that turn."* Skills installed in user-scope `~/.codex/skills/` need no namespace prefix.

**C) Plain text mention** (e.g. `dung skill taw de lam cho toi shop ca phe`, `use the taw skill to add a contact form`).

Codex CLI does NOT support custom user-defined slash commands (so no `/taw`), and the `@` prefix in the TUI is a file-picker, not a skill mention.

In both cases: the `taw` skill classifies intent (BUILD / FIX / SHIP / MAINTAIN / ADVISOR), detects target shape (web / mobile / hybrid / backend / CLI / automation / data / docs), and loads exactly one branch file from `skills/taw/branches/` to execute. Do not try to do broad product work directly — load the branch file first, then follow it step-by-step. For narrow user prose that clearly matches a direct skill (`taw-commit`, `taw-git`, `testing-playwright`, `stripe-checkout`, etc.), Codex may invoke that specific skill directly.

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

- Don't bypass the `taw` orchestrator and start coding directly when user gives broad free-form product/repo prose. Always classify → branch file → execute.
- Don't force Next.js/Vercel/Supabase when the user's task is mobile, backend, CLI, automation, data, docs, or an existing repo with a different stack.
- Don't reply in English to a Vietnamese user.
- Don't skip the approval gate in SAFE mode. The user trades 1 message for the right to course-correct before 5 minutes of work.
- Don't auto-install npm packages without asking unless the BUILD branch is actively scaffolding a new project.
