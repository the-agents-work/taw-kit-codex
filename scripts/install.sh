#!/usr/bin/env bash
# taw-kit-codex installer
# Default: COPY skills into ~/.codex/skills/ (cross-platform, no symlink permissions issues).
# Dev mode: TAW_SYMLINK=1 (or --symlink flag) symlinks instead — for plugin contributors who
# want live edits without re-running the installer after every change.
# Also registers the repo as a Codex marketplace via `codex plugin marketplace add`.
# Optional hooks: TAW_INSTALL_HOOKS=1 or --hooks enables Codex lifecycle hooks
# by writing ~/.codex/hooks.json and setting [features].codex_hooks = true.

set -euo pipefail

PLUGIN_NAME="taw"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/$PLUGIN_NAME"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME/skills"
PLUGINS_DIR="$CODEX_HOME/plugins"
BACKUP_DIR="$CODEX_HOME/skill-backups/$PLUGIN_NAME"
MARKER_FILE=".taw-kit-codex-managed"

say() { printf "\033[1;36m▸\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m⚠\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m✗\033[0m %s\n" "$1"; exit 1; }

# Mode: copy (default) vs symlink (dev). Hooks default to prompt in interactive
# installs, disabled in TAW_YES=1 unless TAW_INSTALL_HOOKS=1 is set.
MODE="copy"
INSTALL_HOOKS="${TAW_INSTALL_HOOKS:-}"
for arg in "$@"; do
  case "$arg" in
    --symlink) MODE="symlink" ;;
    --hooks) INSTALL_HOOKS="1" ;;
    --no-hooks) INSTALL_HOOKS="0" ;;
    *)
      warn "Unknown argument ignored: $arg"
      ;;
  esac
done
if [ "${TAW_SYMLINK:-0}" = "1" ]; then MODE="symlink"; fi

unique_path() {
  local base="$1"
  local candidate="$base"
  local i=1
  while [ -e "$candidate" ]; do
    candidate="${base}.${i}"
    i=$((i + 1))
  done
  printf "%s\n" "$candidate"
}

enable_codex_hooks_feature() {
  command -v python3 >/dev/null 2>&1 || {
    warn "python3 not found; cannot update $CODEX_HOME/config.toml automatically"
    warn "Add this manually: [features] codex_hooks = true"
    return 0
  }

  local config_file="$CODEX_HOME/config.toml"
  mkdir -p "$CODEX_HOME"
  python3 - "$config_file" <<'PY'
from pathlib import Path
import re
import shutil
import sys
import time

path = Path(sys.argv[1]).expanduser()
old = path.read_text() if path.exists() else ""
lines = old.splitlines(keepends=True)
table_re = re.compile(r"^\s*\[([^\]]+)\]\s*(?:#.*)?$")

features_start = None
features_end = len(lines)
for i, line in enumerate(lines):
    match = table_re.match(line)
    if not match:
        continue
    if match.group(1).strip() == "features":
        features_start = i
        features_end = len(lines)
        for j in range(i + 1, len(lines)):
            if table_re.match(lines[j]):
                features_end = j
                break
        break

if features_start is None:
    if lines and not lines[-1].endswith("\n"):
        lines[-1] += "\n"
    if lines and lines[-1].strip():
        lines.append("\n")
    lines.extend(["[features]\n", "codex_hooks = true\n"])
else:
    replaced = False
    for i in range(features_start + 1, features_end):
        if re.match(r"^\s*codex_hooks\s*=", lines[i]):
            lines[i] = "codex_hooks = true\n"
            replaced = True
            break
    if not replaced:
        lines.insert(features_start + 1, "codex_hooks = true\n")

new = "".join(lines)
if new != old:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_name(f"{path.name}.bak-taw-hooks-{time.strftime('%Y%m%d%H%M%S')}")
        shutil.copy2(path, backup)
        print(f"backed up config: {backup}")
    path.write_text(new)
    print("enabled [features].codex_hooks = true")
else:
    print("[features].codex_hooks already enabled")
PY
}

install_codex_hooks() {
  [ -f "$PLUGIN_DIR/hooks.json" ] || { warn "No hooks.json found in plugin; skipping hooks"; return 0; }
  command -v python3 >/dev/null 2>&1 || {
    warn "python3 not found; cannot merge hooks.json automatically"
    return 0
  }

  local target_plugin_dir="$PLUGINS_DIR/$PLUGIN_NAME"
  local target_hooks_file="$CODEX_HOME/hooks.json"
  mkdir -p "$target_plugin_dir" "$CODEX_HOME"
  rm -rf "$target_plugin_dir/hooks"
  cp -R "$PLUGIN_DIR/hooks" "$target_plugin_dir/hooks"
  cp "$PLUGIN_DIR/hooks.json" "$target_plugin_dir/hooks.json"
  chmod +x "$target_plugin_dir"/hooks/*.sh 2>/dev/null || true

  python3 - "$target_hooks_file" "$PLUGIN_DIR/hooks.json" <<'PY'
from pathlib import Path
import json
import shutil
import sys
import time

target = Path(sys.argv[1]).expanduser()
source = Path(sys.argv[2]).expanduser()

if target.exists():
    try:
        existing = json.loads(target.read_text())
    except Exception as exc:
        raise SystemExit(f"cannot parse existing hooks.json: {exc}")
else:
    existing = {"hooks": {}}

incoming = json.loads(source.read_text())
existing.setdefault("hooks", {})

def is_taw_group(group):
    for hook in group.get("hooks", []):
        command = hook.get("command", "")
        if "/plugins/taw/hooks/" in command or "plugins/taw/hooks/" in command:
            return True
    return False

for event, groups in incoming.get("hooks", {}).items():
    kept = [group for group in existing["hooks"].get(event, []) if not is_taw_group(group)]
    kept.extend(groups)
    existing["hooks"][event] = kept

for event in list(existing["hooks"].keys()):
    if not existing["hooks"][event]:
        del existing["hooks"][event]

new_text = json.dumps(existing, indent=2, ensure_ascii=False) + "\n"
old_text = target.read_text() if target.exists() else ""
if new_text != old_text:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        backup = target.with_name(f"{target.name}.bak-taw-hooks-{time.strftime('%Y%m%d%H%M%S')}")
        shutil.copy2(target, backup)
        print(f"backed up hooks: {backup}")
    target.write_text(new_text)
    print(f"merged taw hooks into {target}")
else:
    print(f"taw hooks already present in {target}")
PY

  enable_codex_hooks_feature
  say "Hooks enabled: $target_hooks_file"
  warn "Restart Codex sessions for hook changes to take effect."
}

# ---- 1. Pre-flight ----
if ! command -v codex >/dev/null 2>&1; then
  fail "Codex CLI chưa cài. Cài trước: https://github.com/openai/codex"
fi

[ -d "$PLUGIN_DIR/skills" ] || fail "Không tìm thấy $PLUGIN_DIR/skills — repo bị thiếu file?"

CODEX_VER="$(codex --version 2>/dev/null | head -1 || echo unknown)"
say "Phát hiện: $CODEX_VER"
say "Plugin nguồn: $PLUGIN_DIR"
if [ "$MODE" = "symlink" ]; then
  say "Symlink skills vào: $SKILLS_DIR (chế độ dev — sửa repo là Codex thấy ngay)"
else
  say "Copy skills vào: $SKILLS_DIR (chế độ user — cross-platform)"
fi

# ---- 2. Confirm ----
if [ "${TAW_YES:-}" != "1" ]; then
  printf "\nCài đặt? (y/N) "
  read -r ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *) fail "Hủy." ;;
  esac
fi

mkdir -p "$SKILLS_DIR" "$BACKUP_DIR"

# ---- 3. Remove old installer backups from Codex's skill scan path ----
REMOVED_BACKUPS=0
for old_backup in "$SKILLS_DIR"/*.bak.*; do
  [ -e "$old_backup" ] || continue
  rm -rf "$old_backup"
  REMOVED_BACKUPS=$((REMOVED_BACKUPS + 1))
done
if [ "$REMOVED_BACKUPS" -gt 0 ]; then
  warn "Deleted $REMOVED_BACKUPS old .bak skill directories from $SKILLS_DIR"
fi

# ---- 4. Install each skill ----
INSTALLED=0
REPLACED=0
BACKED_UP=0
for skill_path in "$PLUGIN_DIR"/skills/*/; do
  [ -d "$skill_path" ] || continue
  skill_name="$(basename "$skill_path")"
  target="$SKILLS_DIR/$skill_name"

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] || [ -f "$target/$MARKER_FILE" ] || diff -qr "$skill_path" "$target" >/dev/null 2>&1; then
      rm -rf "$target"
      REPLACED=$((REPLACED + 1))
    elif [ "${TAW_BACKUP_UNMANAGED:-}" = "1" ]; then
      backup="$(unique_path "$BACKUP_DIR/${skill_name}.bak.$(date +%s)")"
      mv "$target" "$backup"
      BACKED_UP=$((BACKED_UP + 1))
      warn "Backed up unmanaged skill: $skill_name → ${backup#$CODEX_HOME/}"
    elif [ "${TAW_FORCE_REPLACE:-}" = "1" ]; then
      warn "Deleting unmanaged existing skill because TAW_FORCE_REPLACE=1: $target"
      rm -rf "$target"
      REPLACED=$((REPLACED + 1))
    elif [ "${TAW_YES:-}" = "1" ]; then
      fail "Skill đã tồn tại nhưng không do taw-kit quản lý: $target. Set TAW_FORCE_REPLACE=1 để xoá, hoặc TAW_BACKUP_UNMANAGED=1 để backup ra $BACKUP_DIR."
    else
      warn "Skill đã tồn tại nhưng không do taw-kit quản lý: $target"
      printf "Xoá và thay bằng bản taw-kit mới? (y/N) "
      read -r replace_ans
      case "$replace_ans" in
        y|Y|yes|YES)
          rm -rf "$target"
          REPLACED=$((REPLACED + 1))
          ;;
        *)
          fail "Hủy để tránh xoá nhầm skill user custom. Chạy lại với TAW_BACKUP_UNMANAGED=1 nếu muốn backup trước."
          ;;
      esac
    fi
  fi

  if [ "$MODE" = "symlink" ]; then
    ln -s "$skill_path" "$target"
  else
    cp -R "$skill_path" "$target"
    printf "managed_by=taw-kit-codex\nsource=%s\n" "$skill_path" > "$target/$MARKER_FILE"
  fi
  INSTALLED=$((INSTALLED + 1))
done
SUMMARY_EXTRA=""
if [ "$REPLACED" -gt 0 ]; then
  SUMMARY_EXTRA="$SUMMARY_EXTRA, replaced $REPLACED existing"
fi
if [ "$BACKED_UP" -gt 0 ]; then
  SUMMARY_EXTRA="$SUMMARY_EXTRA, backed up $BACKED_UP unmanaged"
fi
if [ "$REMOVED_BACKUPS" -gt 0 ]; then
  SUMMARY_EXTRA="$SUMMARY_EXTRA, deleted $REMOVED_BACKUPS old backups"
fi
if [ -n "$SUMMARY_EXTRA" ]; then
  SUMMARY_EXTRA=" (${SUMMARY_EXTRA#, })"
fi

if [ "$MODE" = "symlink" ]; then
  say "Symlinked $INSTALLED skill$SUMMARY_EXTRA"
else
  say "Copied $INSTALLED skill$SUMMARY_EXTRA"
fi

# ---- 5. Register marketplace (best-effort, non-fatal) ----
if codex plugin marketplace add "$REPO_ROOT" >/dev/null 2>&1; then
  say "Marketplace registered: $PLUGIN_NAME"
else
  warn "Không đăng ký được marketplace (có thể đã đăng ký rồi). Bỏ qua."
fi

# ---- 6. Hooks install / reminder ----
if [ -f "$PLUGIN_DIR/hooks.json" ]; then
  if [ -z "$INSTALL_HOOKS" ] && [ "${TAW_YES:-}" != "1" ]; then
    printf "\nEnable Codex lifecycle hooks? This turns on taw auto-commit checkpoints. (y/N) "
    read -r hooks_ans
    case "$hooks_ans" in
      y|Y|yes|YES) INSTALL_HOOKS="1" ;;
      *) INSTALL_HOOKS="0" ;;
    esac
  fi

  if [ "$INSTALL_HOOKS" = "1" ]; then
    install_codex_hooks
  else
    warn "Hooks not enabled. Run with TAW_INSTALL_HOOKS=1 or --hooks to activate."
  fi
fi

# ---- 7. Done ----
if [ "$MODE" = "symlink" ]; then
  UPDATE_HINT="cd $REPO_ROOT && git pull   # sửa repo là Codex thấy ngay, không cần cài lại"
else
  UPDATE_HINT="cd $REPO_ROOT && git pull && bash scripts/install.sh   # update bằng git pull + cài lại"
fi

printf "\n\033[1;32m✓ Cài xong.\033[0m\n"
cat <<EOF

Thử ngay:

  cd /tmp && mkdir -p smoke && cd smoke && git init -q
  codex
  > lam cho toi mot landing page ban ca phe

Codex sẽ tự kích hoạt skill 'taw' và chạy luồng BUILD.

Lệnh hữu ích:
  ls $SKILLS_DIR | head                # xem skill đã cài
  $UPDATE_HINT
  TAW_SYMLINK=1 bash $SCRIPT_DIR/install.sh   # chuyển sang chế độ dev (live edits)
  TAW_INSTALL_HOOKS=1 bash $SCRIPT_DIR/install.sh   # bật Codex hooks + auto-commit checkpoint

EOF
