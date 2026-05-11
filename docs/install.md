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
2. Replace bản skill cũ do taw-kit quản lý. Nếu gặp skill cùng tên không có marker taw-kit, installer sẽ cảnh báo trước khi xoá.
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

Nếu trước đó bạn tự sửa hoặc tự tạo skill trùng tên trong `~/.codex/skills`, installer sẽ không âm thầm xoá trong chế độ `TAW_YES=1`. Chọn một trong hai:

```bash
TAW_FORCE_REPLACE=1 TAW_YES=1 bash ~/.taw-kit-codex/scripts/install.sh      # xoá và thay bản mới
TAW_BACKUP_UNMANAGED=1 TAW_YES=1 bash ~/.taw-kit-codex/scripts/install.sh   # backup ra ~/.codex/skill-backups/taw/
```

## 4. Verify

```bash
codex plugin marketplace list
find ~/.codex/skills -maxdepth 1 -type d -name '*.bak.*' | wc -l  # phải là 0
test -f ~/.codex/skills/taw/.taw-kit-codex-managed
ls ~/.codex/skills/taw ~/.codex/skills/agent-fullstack-dev
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
while IFS= read -r skill; do
  rm -rf "$HOME/.codex/skills/$skill"
done < <(find ~/.taw-kit-codex/plugins/taw/skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
# Nếu đã đăng ký marketplace, xoá entry taw trong ~/.codex/config.toml hoặc bằng lệnh Codex CLI nếu bản CLI hỗ trợ remove.
```

## 7. Lỗi thường gặp

### `codex: command not found`
Cài Codex CLI trước (mục 2).

### Skill không tự kích hoạt
- Kiểm tra skill có thực sự ở `~/.codex/skills/taw/SKILL.md`.
- Kiểm tra marketplace có entry không: `codex plugin marketplace list`.
- Restart Codex (gõ `/quit` rồi mở lại).

### Hook không chạy
- Hiện installer chỉ copy skills; hooks chưa tự kích hoạt.
- Nếu cần hooks, đăng ký plugin qua UI/plugin flow của Codex hoặc copy cấu hình `plugins/taw/hooks.json` vào cấu hình Codex theo bản CLI đang dùng.
- Các skill chính vẫn chạy bình thường dù hooks chưa bật.

### Cần API key thay vì ChatGPT subscription
Set env var:
```bash
export OPENAI_API_KEY=sk-...
codex
```
