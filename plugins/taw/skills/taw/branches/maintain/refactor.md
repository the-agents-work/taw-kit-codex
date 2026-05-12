# maintain: refactor

Safe structural cleanup with behavior preserved. This branch supports both classic refactors
(rename/extract/split/move/export style) and backend API refactor loops where every small
change is guarded by before/after API checks.

**Prereq:** router classified `tier2 = refactor`.

## Core rule

Refactor is not "make code prettier and hope." Refactor means:

1. choose a small slice,
2. capture behavior before,
3. edit only that slice,
4. wait for the app to reload,
5. call the same behavior check after,
6. build/checkpoint,
7. only then continue.

If behavior cannot be checked, skip that candidate or ask for a safer endpoint. Do not keep
editing while a server is restarting.

## Step 1 - Classify the refactor lane

Pick exactly one lane.

| User signal | Lane |
|---|---|
| "rename X to Y", "doi ten X thanh Y" | `classic/rename-symbol` |
| "extract ...", "tach component", "split file", "move file", "named/default export" | `classic/targeted` |
| "tao list can refactor", "call api truoc/sau", "BE", "backend", "localhost", "port", "hot reload", "refactor nho", "safety first", "non stop" | `api-loop` |
| unclear | ask one concise question |

For Vietnamese users, reply in Vietnamese.

## Step 2 - Shared setup

Create `.taw/` if missing and write `.taw/intent.json` already handled by the router.

Run:

```bash
git status --porcelain
git rev-parse HEAD > .taw/refactor-sha.txt
```

Dirty worktree policy:

- Do not stop just because the repo is dirty.
- Record pre-existing dirty files in `.taw/refactor-session.json`.
- Do not edit dirty files unless they are the explicit target or required for the approved slice.
- Never use `git reset --hard` in a dirty worktree. If revert is needed, revert only the files touched by this branch or ask first.

Detect stack before editing:

- Read `package.json` when present.
- Detect build/test commands.
- For backend/API work, detect server command, port, DB/env keys, route files, auth middleware, and response helpers.
- Read env keys only; never print secret values.

## Step 3A - API-loop lane

Use this lane when the user asks for backend/API refactor, asks to make a refactor list, or
explicitly says to call API before and after refactor.

### 3A.1 Find runtime facts

Infer or read from the user:

- base URL, e.g. `http://localhost:3010`
- DB, e.g. `MONGOOSE_URI=mongodb://localhost:27017/lavni_db_2023`
- health endpoint, e.g. `/health`
- dev server command, e.g. `npm start`
- build command, e.g. `npm run build -- --pretty false`

If the user already gave these, use them. Do not ask again.

If no server is listening:

1. start the app with the detected/user-provided env,
2. wait for it to listen,
3. then continue.

### 3A.2 Create the refactor list

Write or update `.taw/refactor-list.md`.

Candidate order:

1. route registration registries that preserve exact order,
2. tiny pure helpers for duplicated query parsing / response branching,
3. unused imports in touched route modules,
4. small endpoint modules with stable 401/404 or read-only responses,
5. larger billing/transaction/partner/admin modules only after several small loops pass.

Avoid first:

- write-heavy endpoints unless test data can be cleaned up,
- slow/unstable endpoints unless the user explicitly accepts the risk,
- broad cross-cutting files while unrelated dirty changes exist,
- files with active user changes unless the user targeted them.

### 3A.3 Baseline API before each slice

Before editing, capture the exact command(s) that prove current behavior.

Prefer:

- `GET /health`
- missing-token authenticated routes that return stable `401`
- missing route `404`
- public read-only route with stable payload
- authenticated read-only route with a locally minted token

Auth/token rule:

- If local DB + local JWT secret are available, the agent may mint a temporary JWT from an existing local user.
- Do not print token values.
- Prefer existing users over resetting passwords.
- If test records are created, record their IDs and delete them before the loop finishes.

Baseline fields to compare:

- status code
- response body
- `Content-Length` when present
- `ETag` when byte-stable
- stable semantic fields when byte order is nondeterministic

If the endpoint is nondeterministic, note exactly which field is nondeterministic and compare
stable semantics instead.

### 3A.4 Edit one small slice

Rules:

- One module or one tight helper extraction per loop.
- Preserve route order exactly, especially dynamic/catch-all routes.
- Preserve middleware order exactly. Auth usually stays before validation/handler if that was the old behavior.
- Keep public routes explicit when nearby auth routes are moved into a registry.
- Do not mix behavior fixes into the refactor.

### 3A.5 Wait for reload

After every code edit, wait before calling the API:

1. wait 30 seconds,
2. if still restarting or connection refused, wait 60 seconds more,
3. if still not ready, wait 120 seconds more,
4. only then restart the local dev server with the known command/env,
5. after restart, wait at least 30 seconds before retrying health.

During this wait, do not make another edit.

### 3A.6 API after-check

Call the same baseline commands after reload.

Pass condition:

- status/body match, and
- `Content-Length`/`ETag` match when stable, or
- documented semantic fields match when byte order is nondeterministic.

Fail condition:

- If health is down, follow the wait ladder first.
- If the same API response differs after the app is ready, stop editing and either fix the slice or revert only the slice.

### 3A.7 Build checkpoint

After every 1-3 passing loops, run the detected build/type check.

Typical commands:

```bash
npm run build -- --pretty false
npx tsc --noEmit
```

Use the repo's actual scripts. If build was already failing before the loop, record that and
do not blame the refactor.

Update `.taw/refactor-list.md` after each passing loop:

```md
N. `path/to/file.ts`
   - Issue: ...
   - Refactor: ...
   - Verification: compared ... before/after.
   - Status: done. Status/body/... matched after <wait> reload wait.
```

Continue loops while there are safe candidates and the user requested continuous work. Stop only
when:

- no safe candidate with a reliable API gate remains,
- build/check fails and cannot be fixed within the slice,
- the user interrupts,
- the next candidate is materially larger and needs explicit approval.

## Step 3B - Classic targeted lane

Use this lane for explicit rename/extract/split/move/export-style requests.

### Target gathering

Required info:

- rename: old name + new name
- extract: source file + line range/description + new file name
- split: source file + split rules
- move: source path + target path
- export-style: target file/folder + direction

If missing, ask one concise question.

### Tool check

For rename and import rewrites, prefer `ast-grep`/`sg` when installed:

```bash
command -v sg >/dev/null 2>&1 || command -v ast-grep >/dev/null 2>&1
```

If missing, fall back to `rg` + careful manual edits. Do not ask to install unless the refactor
is too broad to do safely by hand.

### Classic execution

Rename:

- grep for old and new names first,
- avoid strings/comments unless explicitly requested,
- use word-boundary replacements only.

Extract:

- infer props from parent scope,
- create the new file using project conventions,
- replace old block with the new component/helper call,
- preserve public API.

Split:

- move cohesive top-level units only,
- keep an index/re-export when callers depend on old imports,
- do not delete the original public surface unless requested.

Move:

- move the file,
- update imports with correct relative paths,
- verify no stale imports remain.

Export-style:

- update exported declaration,
- update all imports.

## Step 4 - Verify

Run the lightest reliable checks first, then broader checks:

```bash
git diff --check
npx tsc --noEmit
npm run build
npm test
```

Use only commands available in the repo. For API-loop lane, API before/after checks are mandatory
for each slice; build alone is not enough.

## Step 5 - Error handling

If a refactor slice fails:

1. stop further edits,
2. show the compact failing diff/response difference,
3. try one targeted fix if obvious,
4. if still failing, revert only the files touched by this slice or ask the user.

Do not use `git reset --hard` unless the user explicitly asks and confirms.

## Step 6 - Commit

If code changed and checks passed, invoke `taw-commit`:

```text
type=refactor, scope=<inferred>, subject="<small behavior-preserving summary>"
```

If the user asked for a long-running non-stop refactor session, commit only at a sensible checkpoint
or when the branch's common post-step runs.

## Step 7 - Done

Final response must include:

- files refactored,
- API before/after endpoints checked,
- build/type/test commands run,
- any skipped candidates and why,
- pre-existing dirty files not touched.

Suggested next commands:

```text
$taw refactor tiếp
$taw review
$taw test <critical flow>
```

## Constraints

- Preserve behavior. No opportunistic bug fixes inside a refactor slice.
- Never edit while the app is restarting.
- Never log tokens/secrets.
- Never touch `node_modules/`, generated folders (`.next/`, `dist/`, `build/`), or ambient `*.d.ts` unless explicitly targeted.
- For changes affecting more than 50 files or high-risk modules, show count/risk and get confirmation unless the user explicitly said YOLO/non-stop.
- If API baseline cannot be obtained after the wait ladder and one restart, skip that candidate and explain why in `.taw/refactor-list.md`.
