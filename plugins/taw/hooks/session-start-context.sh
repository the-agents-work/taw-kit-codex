#!/usr/bin/env bash
# taw-kit hook: SessionStart
# Injects current project context so Claude starts with project awareness.
# Exits 0 always; failures are silent (hooks must never break sessions).

set -u

LOG="${HOME}/.taw-kit/logs/hooks.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

log() { printf '[%s] session-start: %s\n' "$(date -u +%FT%TZ)" "$1" >> "$LOG" 2>/dev/null || true; }

# Only run inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "not a git repo; skip"
  exit 0
fi

dirty_marker=".git/.taw-autocommit-disabled-dirty-start"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  printf 'dirty at session start: %s\n' "$(date -u +%FT%TZ)" > "$dirty_marker" 2>/dev/null || true
  log "dirty worktree at session start; auto-commit disabled until clean"
else
  rm -f "$dirty_marker" 2>/dev/null || true
fi

branch="$(git branch --show-current 2>/dev/null || echo 'detached')"
commits="$(git log -3 --oneline 2>/dev/null | head -3)"

# Find most recent plan dir (if any)
plan_dir=""
if [ -d "plans" ]; then
  plan_dir="$(ls -1td plans/*/ 2>/dev/null | head -1 | sed 's|/$||')"
fi

# Find deploy URL (if any)
deploy_url=""
[ -f ".taw/deploy-url.txt" ] && deploy_url="$(head -1 .taw/deploy-url.txt 2>/dev/null)"

# Emit a compact context block (≤20 lines cap)
{
  printf '## Project context (taw-kit session-start)\n'
  printf '%s\n' "- Branch: $branch"
  if [ -n "$commits" ]; then
    printf '%s\n' '- Recent commits:'
    printf '%s\n' "$commits" | sed 's/^/    /'
  fi
  [ -n "$plan_dir" ]   && printf '%s\n' "- Active plan: $plan_dir"
  [ -n "$deploy_url" ] && printf '%s\n' "- Deploy URL: $deploy_url"
} | head -20

log "emitted context (branch=$branch, plan=$plan_dir, deploy=$deploy_url)"
exit 0
