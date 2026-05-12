---
name: taw-task-loop
description: Ralph-style long-running task queue for Codex. Use when the user wants an autonomous loop over a PRD/task JSON, progress file, git history, and fresh context per task; useful for many small verifiable tasks such as tests, migrations, components, cleanup, refactors, or user stories. Triggers include "Ralph", "task loop", "prd.json", "long-running tasks", "non stop", "agent loop", "run task queue", "auto tasks", "passes true", "vòng lặp task", and "làm tới khi hết task".
---

# taw-task-loop

Run a local, behavior-checked task queue inspired by Ralph-style agent loops.

The goal is not to create one huge agent session. The goal is to keep durable state in files,
finish one small verifiable task at a time, commit it, mark it done, then continue from clean
project memory.

## State files

Default files:

- `.taw/task-loop.json` - machine-readable task queue
- `.taw/task-loop-progress.md` - human-readable progress log
- `AGENTS.md` or `CLAUDE.md` - project memory, if present
- git history - durable execution trace

Task schema:

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

Allowed `status`: `pending`, `in_progress`, `passed`, `blocked`, `skipped`.

## Workflow

1. If `.taw/task-loop.json` does not exist, create it from the user's PRD/prose/TODO list.
2. Sort candidates by highest `priority`, then smallest safe blast radius.
3. Pick exactly one `pending` task.
4. Mark it `in_progress` before editing.
5. Read current project memory and relevant git history/diff.
6. Implement only that task.
7. Run the task's `checks`; if absent, infer the lightest reliable checks from the repo.
8. If checks pass:
   - update task to `status: "passed"` and `passes: true`
   - append `.taw/task-loop-progress.md`
   - commit with `taw-commit` when available
9. If checks fail:
   - fix once if obvious
   - otherwise mark `blocked`, include compact failure detail, and move on only if the user asked for non-stop mode
10. Continue until no safe pending task remains or the user stops the loop.

## Task selection rules

Prefer tasks that are:

- small,
- easy to verify,
- low risk,
- independent from dirty user changes,
- scoped to one module or one user story.

Good task-loop work:

- unit tests,
- E2E smoke tests,
- migrations with rollback/check SQL,
- small refactors with API before/after,
- route/component splits,
- lint/type cleanup,
- docs generated from current code,
- one user story from a PRD.

Avoid:

- broad rewrites,
- ambiguous product decisions,
- destructive data operations,
- production deploys,
- secrets or credentials changes,
- tasks without a credible check.

## Fresh-context note

Inside one Codex session, you cannot truly spawn a brand-new CLI process unless the user asks for
an external script. Simulate the Ralph pattern by keeping state in files and re-reading only:

- selected task,
- progress log,
- recent git history,
- relevant source files,
- project memory.

If the user explicitly asks for a shell orchestrator, create a small script such as
`.taw/run-task-loop.sh` that repeatedly launches the user's preferred CLI. Do not assume command
names or auth; detect or ask first.

## Safety

- Never mark `passes: true` without running checks.
- Never edit multiple unrelated tasks in one loop.
- Never hide blocked tasks; write the blocker in JSON + progress log.
- Never log secrets.
- Respect dirty worktrees: do not overwrite user changes.
