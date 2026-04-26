# Cài đặt taw-kit-codex chi tiết

## 1. Yêu cầu hệ thống

- **macOS 12+ / Linux / WSL2 trên Windows**
- **Codex CLI** (kiểm tra: `codex --version` — cần `0.122.0` trở lên)
- **Node.js ≥ 20** (cho project sinh ra)
- **Python 3** (cho installer cập nhật `marketplace.json`)
- **git**

## 2. Cài Codex CLI

Theo hướng dẫn chính thức: https://github.com/openai/codex

Sau khi cài, login:

```bash
codex login
```

## 3. Cài plugin taw-kit-codex

```bash
git clone https://github.com/the-agents-work/taw-kit-codex.git ~/.taw-kit-codex
bash ~/.taw-kit-codex/scripts/install.sh
```

Installer sẽ:
1. Backup plugin cũ (nếu có) sang `~/.codex/plugins/taw-kit-codex.bak.<timestamp>`.
2. Copy nguồn vào `~/.codex/plugins/taw-kit-codex/`.
3. Đăng ký entry vào `~/.agents/plugins/marketplace.json`.
4. Set executable cho `hooks/*.sh` và `scripts/*.sh`.

Để bỏ qua prompt xác nhận:

```bash
TAW_YES=1 bash ~/.taw-kit-codex/scripts/install.sh
```

## 4. Verify

```bash
codex plugin marketplace list
ls ~/.codex/plugins/taw-kit-codex/skills | wc -l    # ~47 (40 skill + 6 agent + 1 README)
```

Mở Codex và thử:

```
> tao cho toi mot landing page ban tra sua          # auto-trigger qua prose
> dung skill taw de tao landing page ban tra sua    # gọi rõ tên (khi auto không bắt)
```

Codex kích hoạt skill `taw`, vào nhánh BUILD. Codex KHÔNG hỗ trợ custom slash command nên không có `/taw`. `@` trong TUI là file picker, không phải skill mention — đừng gõ `@taw`, sẽ ra "no matches".

## 5. Nâng cấp

```bash
cd ~/.taw-kit-codex
git pull
bash scripts/install.sh
```

## 6. Gỡ

```bash
rm -rf ~/.codex/plugins/taw-kit-codex
# Sau đó xoá entry "taw-kit-codex" khỏi ~/.agents/plugins/marketplace.json (sửa tay)
```

## 7. Lỗi thường gặp

### `codex: command not found`
Cài Codex CLI trước (mục 2).

### Skill không tự kích hoạt
- Kiểm tra plugin có thực sự ở `~/.codex/plugins/taw-kit-codex/`.
- Kiểm tra `marketplace.json` có entry không: `cat ~/.agents/plugins/marketplace.json`.
- Restart Codex (gõ `/quit` rồi mở lại).

### Hook không chạy
- `chmod +x ~/.codex/plugins/taw-kit-codex/hooks/*.sh`
- Kiểm tra `~/.codex/plugins/taw-kit-codex/hooks.json` có path đúng không.
- Tạm thời tắt: rename `hooks.json` → `hooks.json.disabled` rồi restart Codex.

### Cần API key thay vì ChatGPT subscription
Set env var:
```bash
export OPENAI_API_KEY=sk-...
codex
```
