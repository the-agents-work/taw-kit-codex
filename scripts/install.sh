#!/usr/bin/env bash
# taw-kit-codex installer
# Default: COPY skills into ~/.codex/skills/ (cross-platform, no symlink permissions issues).
# Dev mode: TAW_SYMLINK=1 (or --symlink flag) symlinks instead — for plugin contributors who
# want live edits without re-running the installer after every change.
# Also registers the repo as a Codex marketplace via `codex plugin marketplace add`.

set -euo pipefail

PLUGIN_NAME="taw"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/$PLUGIN_NAME"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME/skills"
BACKUP_DIR="$CODEX_HOME/skill-backups/$PLUGIN_NAME"
MARKER_FILE=".taw-kit-codex-managed"

# Mode: copy (default) vs symlink (dev)
MODE="copy"
if [ "${TAW_SYMLINK:-0}" = "1" ] || [ "${1:-}" = "--symlink" ]; then
  MODE="symlink"
fi

say() { printf "\033[1;36m▸\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m⚠\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m✗\033[0m %s\n" "$1"; exit 1; }
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

# ---- 6. Hooks reminder ----
if [ -f "$PLUGIN_DIR/hooks.json" ]; then
  warn "Hooks chưa được tự kích hoạt — Codex chỉ load hooks khi plugin đã 'install' qua /plugins."
  warn "Tạm thời bỏ qua hoặc copy nội dung $PLUGIN_DIR/hooks.json vào ~/.codex/config.toml [hooks] section."
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

EOF
