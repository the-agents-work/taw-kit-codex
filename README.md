# taw-kit-codex

> Bộ kit **Codex CLI** cho người không biết code — ra mắt sản phẩm thật chỉ bằng một câu mô tả tiếng Việt.

> Đây là bản port của [taw-kit](https://github.com/nghiahsgs/taw-kit) (vốn cho Claude Code) sang **OpenAI Codex CLI**. Cùng tính năng, cùng triết lý, chạy trên runtime của bạn đang dùng.

```
> lam cho toi mot shop my pham online
  → hỏi lại cho rõ (3–5 câu)
  → lập kế hoạch 5 ý, bạn duyệt
  → code + test + review
  → deploy (Vercel, Docker, hoặc VPS)
  → trả về URL đã chạy
```

**Không cần gõ `/taw`.** Codex tự kích hoạt skill khi bạn mô tả việc muốn làm bằng tiếng Việt — tạo mới, thêm tính năng, sửa lỗi, deploy, test, nâng cấp, dọn code, tối ưu, lùi bản — kit tự hiểu và chạy đúng nhánh.

```
> lam cho toi mot shop ca phe          → tạo mới
> them trang lien he                    → thêm tính năng
> loi roi, fix gium                     → auto-fix
> deploy len vercel                     → deploy
> test cai login                        → auto-gen test
> nang cap next len 15                  → upgrade deps
> don code dum                          → xoá dead code
> cham qua, check perf                  → bundle + lighthouse
> lui lai ban hom qua                   → rollback code + deploy
> kiem tra bao mat                      → audit P0/P1/P2
```

---

## Bạn nhận được gì

- **~40 skills, 6 agent-roles, 3 hooks** — đóng gói thành 1 Codex plugin, cài vào `~/.codex/plugins/taw-kit-codex/`
- **1 entrypoint duy nhất `taw`** — router 2 tầng tự hiểu tạo mới / thêm / sửa / deploy / test / nâng cấp / dọn code / rollback / refactor / audit bảo mật
- **Stack adaptation** — mặc định Next.js + Supabase + Polar cho project mới, nhưng TỰ DETECT project hiện tại đang dùng Stripe/Drizzle/Clerk... và respect, không ghi đè
- **Tự maintain AGENTS.md** — kit tạo + cập nhật file memory cho Codex sau mỗi run. Codex đọc lại mỗi session → tiết kiệm token + trả lời chính xác hơn cho repo lớn
- **Design có gu** — skill `frontend-design` của Anthropic (Apache 2.0) được bundle sẵn, giúp giao diện không bị "AI slop". Xem [THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md)
- **Dev workflow skills** — testing (vitest/playwright/rls), CI (GitHub Actions), bundle analyzer, knip dọn code, dep upgrade an toàn, Stripe alt cho Polar, Sentry monitoring, taw-commit, taw-git, debug-flight-recorder, status dashboard
- **License Apache-2.0** — dùng và phân phối tự do, kể cả thương mại

---

## Cài đặt

### Trước khi bắt đầu

| Thứ | Để làm gì | Cài ở đâu |
|-----|-----------|-----------|
| **Codex CLI** | Runtime AI để chạy skill | [github.com/openai/codex](https://github.com/openai/codex) |
| **Node.js ≥ 20** | Dự án taw-kit tạo ra sẽ chạy trên đây | [nodejs.org](https://nodejs.org) |
| **git** | Để clone repo | `brew install git` / `apt install git` |
| **OpenAI API key** hoặc **ChatGPT Plus** | Để Codex CLI gọi model | [platform.openai.com](https://platform.openai.com) |

**Hệ điều hành:** macOS, Linux, hoặc Windows qua WSL2.

```bash
git clone https://github.com/the-agents-work/taw-kit-codex.git ~/.taw-kit-codex
bash ~/.taw-kit-codex/scripts/install.sh
```

Trình cài đặt sẽ:
1. Phát hiện Codex CLI (báo lỗi nếu chưa cài).
2. Backup plugin cũ nếu có.
3. Copy plugin vào `~/.codex/plugins/taw-kit-codex/`.
4. Tạo / update `~/.agents/plugins/marketplace.json` để Codex thấy plugin.
5. Báo số skill, hook đã cài.

Cài lại / nâng cấp: chạy lại lệnh trên, hoặc `bash ~/.codex/plugins/taw-kit-codex/scripts/install.sh`.

---

## Chạy lần đầu

Mở Codex trong một thư mục trống:

```bash
mkdir my-first-product && cd my-first-product
codex
```

Trong Codex CLI, gõ:

```
> lam cho toi 1 landing page ban khoa hoc online
```

Codex sẽ tự nhận skill `taw`, hỏi 3–5 câu cho rõ yêu cầu, hiển thị kế hoạch, đợi bạn duyệt. Gõ `yes` là chạy: plan → research → code → test → security review → deploy. Tổng tầm 15–20 phút.

---

## Khác biệt so với bản Claude Code

| Tính năng | taw-kit (Claude) | taw-kit-codex |
|-----------|------------------|---------------|
| Slash command `/taw` | Có | Không (Codex chưa hỗ trợ custom slash). Trigger qua trigger phrase tự nhiên. |
| Subagent chạy song song | 2 researcher song song | Tuần tự (chậm hơn ~30s) |
| Skills format | Giống nhau | Giống nhau (cùng `name` + `description` frontmatter) |
| Hooks (PreToolUse/PostToolUse/SessionStart/...) | Có | Có (cùng JSON shape) |
| Sandbox / approval modes | Plan / acceptEdits / bypassPermissions | `--sandbox` workspace-write / read-only / danger-full-access |
| Memory file | `CLAUDE.md` | `AGENTS.md` |

---

## Đóng góp

- Repo: [github.com/the-agents-work/taw-kit-codex](https://github.com/the-agents-work/taw-kit-codex)
- Bản gốc Claude Code: [github.com/nghiahsgs/taw-kit](https://github.com/nghiahsgs/taw-kit)
- License: Apache-2.0 (xem [LICENSE](./LICENSE))

Built by [the-agents-work](https://www.theagents.work/).
