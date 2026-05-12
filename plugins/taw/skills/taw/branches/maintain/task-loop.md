# maintain: task-loop

Run a Ralph-style long-running task queue: durable task JSON, progress log, checks, commits, and
one small task per loop.

**Prereq:** router classified `tier2 = task-loop`.

## Step 1 - Use the task-loop skill

Follow the `taw-task-loop` skill workflow. If the skill is installed, load it and use it as the
source of truth.

## Step 2 - Inputs

Use these defaults unless the user specified otherwise:

- queue: `.taw/task-loop.json`
- progress: `.taw/task-loop-progress.md`
- memory: `AGENTS.md` or `CLAUDE.md` when present

If the user gave a PRD/TODO/prose, convert it into queue items.

If the user only says "run the loop" and no queue exists, ask one concise question for the task
source.

## Step 3 - Loop

For each iteration:

1. choose the highest-priority pending task with the smallest safe blast radius,
2. mark it `in_progress`,
3. implement only that task,
4. run checks,
5. commit if checks pass,
6. mark `passes: true`,
7. append progress,
8. continue only if the user requested non-stop/auto mode.

Never mark a task passed without checks.

## Step 4 - Done

Report:

- tasks passed,
- tasks blocked/skipped,
- checks run,
- commits created,
- next safe command: `$taw task-loop continue`.
