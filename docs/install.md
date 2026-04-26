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

Installer sẽ (mặc định **chế độ user — copy**):
1. **Copy** từng thư mục skill vào `~/.codex/skills/<name>/` (cross-platform an toàn, kể cả Windows native).
2. Backup skill cũ trùng tên (nếu có) sang `<name>.bak.<timestamp>`.
3. Đăng ký marketplace qua `codex plugin marketplace add`.

**Chế độ dev — symlink** (cho contributor muốn sửa repo và test ngay, không cần cài lại):

```bash
TAW_SYMLINK=1 bash ~/.taw-kit-codex/scripts/install.sh
# hoặc
bash ~/.taw-kit-codex/scripts/install.sh --symlink
```

Symlink chỉ chạy được trên macOS / Linux / WSL. Trên **Windows native** dùng copy (mặc định).

Để bỏ qua prompt xác nhận (CI / scripted):

```bash
TAW_YES=1 bash ~/.taw-kit-codex/scripts/install.sh
```

## 4. Verify

```bash
codex plugin marketplace list
ls ~/.codex/plugins/taw/skills | wc -l    # ~47 (40 skill + 6 agent + 1 README)
```

Mở Codex và thử (1 trong 3 cách):

```
> tao cho toi mot landing page ban tra sua             # auto-trigger qua prose
> $taw tao landing page ban tra sua          # explicit (~/taw của Claude)
> dung skill taw de tao landing page ban tra sua       # plain text mention
```

Codex kích hoạt skill `taw`, vào nhánh BUILD. Codex KHÔNG hỗ trợ custom slash (không có `/taw`); `@` trong TUI là file picker, không phải skill mention — đừng gõ `@taw`, sẽ ra "no matches".

## 5. Nâng cấp

**Chế độ user (copy)** — cài lại sau mỗi lần `git pull`:
```bash
cd ~/.taw-kit-codex
git pull
bash scripts/install.sh
```

**Chế độ dev (symlink)** — chỉ cần `git pull`, Codex đọc live:
```bash
cd ~/.taw-kit-codex
git pull
# done — không cần cài lại trừ khi có skill mới được thêm
```

## 6. Gỡ

```bash
rm -rf ~/.codex/plugins/taw
# Sau đó xoá entry "taw-kit-codex" khỏi ~/.agents/plugins/marketplace.json (sửa tay)
```

## 7. Lỗi thường gặp

### `codex: command not found`
Cài Codex CLI trước (mục 2).

### Skill không tự kích hoạt
- Kiểm tra plugin có thực sự ở `~/.codex/plugins/taw/`.
- Kiểm tra `marketplace.json` có entry không: `cat ~/.agents/plugins/marketplace.json`.
- Restart Codex (gõ `/quit` rồi mở lại).

### Hook không chạy
- `chmod +x ~/.codex/plugins/taw/hooks/*.sh`
- Kiểm tra `~/.codex/plugins/taw/hooks.json` có path đúng không.
- Tạm thời tắt: rename `hooks.json` → `hooks.json.disabled` rồi restart Codex.

### Cần API key thay vì ChatGPT subscription
Set env var:
```bash
export OPENAI_API_KEY=sk-...
codex
```
