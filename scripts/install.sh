#!/usr/bin/env bash
# taw-kit-codex installer
# Symlinks all plugin skills into ~/.codex/skills/ so Codex CLI auto-discovers them.
# Also registers the repo as a Codex marketplace via `codex plugin marketplace add` for
# future use of the `/plugins` UI flow.

set -euo pipefail

PLUGIN_NAME="taw-kit-codex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/$PLUGIN_NAME"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME/skills"

say() { printf "\033[1;36m▸\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m⚠\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m✗\033[0m %s\n" "$1"; exit 1; }

# ---- 1. Pre-flight ----
if ! command -v codex >/dev/null 2>&1; then
  fail "Codex CLI chưa cài. Cài trước: https://github.com/openai/codex"
fi

[ -d "$PLUGIN_DIR/skills" ] || fail "Không tìm thấy $PLUGIN_DIR/skills — repo bị thiếu file?"

CODEX_VER="$(codex --version 2>/dev/null | head -1 || echo unknown)"
say "Phát hiện: $CODEX_VER"
say "Plugin nguồn: $PLUGIN_DIR"
say "Symlink skills vào: $SKILLS_DIR"

# ---- 2. Confirm ----
if [ "${TAW_YES:-}" != "1" ]; then
  printf "\nCài đặt? (y/N) "
  read -r ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *) fail "Hủy." ;;
  esac
fi

mkdir -p "$SKILLS_DIR"

# ---- 3. Symlink each skill into ~/.codex/skills/ ----
INSTALLED=0
SKIPPED=0
BACKED_UP=0
for skill_path in "$PLUGIN_DIR"/skills/*/; do
  [ -d "$skill_path" ] || continue
  skill_name="$(basename "$skill_path")"
  target="$SKILLS_DIR/$skill_name"

  if [ -L "$target" ]; then
    # Existing symlink — overwrite (assume it's our previous install)
    rm -f "$target"
  elif [ -e "$target" ]; then
    # Real dir/file — back up to avoid clobbering user customizations
    backup="${target}.bak.$(date +%s)"
    mv "$target" "$backup"
    BACKED_UP=$((BACKED_UP + 1))
    warn "Backup user skill: $skill_name → $(basename "$backup")"
  fi
  ln -s "$skill_path" "$target"
  INSTALLED=$((INSTALLED + 1))
done
say "Symlinked $INSTALLED skill" "${BACKED_UP:+(backed up $BACKED_UP existing)}"

# ---- 4. Register marketplace (best-effort, non-fatal) ----
if codex plugin marketplace add "$REPO_ROOT" >/dev/null 2>&1; then
  say "Marketplace registered: $PLUGIN_NAME"
else
  warn "Không đăng ký được marketplace (có thể đã đăng ký rồi). Bỏ qua."
fi

# ---- 5. Hooks reminder ----
if [ -f "$PLUGIN_DIR/hooks.json" ]; then
  warn "Hooks chưa được tự kích hoạt — Codex chỉ load hooks khi plugin đã 'install' qua /plugins."
  warn "Tạm thời bỏ qua hoặc copy nội dung $PLUGIN_DIR/hooks.json vào ~/.codex/config.toml [hooks] section."
fi

# ---- 6. Done ----
cat <<EOF

\033[1;32m✓ Cài xong.\033[0m

Thử ngay:

  cd /tmp && mkdir -p smoke && cd smoke && git init -q
  codex
  > lam cho toi mot landing page ban ca phe

Codex sẽ tự kích hoạt skill 'taw' và chạy luồng BUILD.

Lệnh hữu ích:
  ls $SKILLS_DIR | head                           # xem skill đã cài
  ls -la $SKILLS_DIR/taw                          # xác nhận symlink trỏ về repo
  bash $SCRIPT_DIR/install.sh                     # cài lại / nâng cấp
  cd $REPO_ROOT && git pull && bash scripts/install.sh  # update từ GitHub

EOF
