# HANDOFF — Kasiro Migration: Current State & Next Steps

_Last updated: 25 July 2026. Give this file to a fresh Claude Code / Codex / Cowork instance to resume with full context._

**Canonical location:** `kasiro-brain/ops/MIGRATION_HANDOFF.md` (repo `github.com/GinniNio/kasiro-brain`). Any copy in an outputs or uploads folder is a stale snapshot — edit this one.

---

## Who / what

- **Operator:** Kaye — solo, non-technical. Treats the agent as devops/platform/infra + product expert.
- **Product:** Kasiro (a.k.a. Predicto) — Africa-focused, USDT-only binary prediction-market marketplace (Polymarket-style). Node/Express + Vite React frontend, Drizzle ORM, PostgreSQL.
- **Real money:** ~$11K USDT across ~18 users (early beta). Every decision below is weighted by that fact.
- **Code repo:** `github.com/GinniNio/Prolego2` (private).
- **Brain repo:** `github.com/GinniNio/kasiro-brain` (operating state, portable across machines and agents).

---

## The goal

Move off Replit hosting onto infrastructure Kaye controls, then progressively move authoring off Replit too.

---

## Topology

### Today

```
Replit (authoring via Replit Agent)
   └─ push → GitHub GinniNio/Prolego2 (main)
                ├─ deploy → Render + own Neon   [staging-ish, dev data]
                └─ pull   → C:\Dev\Kasiro       [redundant mirror, pull-only]

kasiro.app → Cloudflare (PROXIED) → Replit deployment   [LIVE PRODUCTION]
```

### Target

```
Claude Code / Codex / any agent (authoring, local)
   └─ push → GitHub GinniNio/Prolego2 (main)
                └─ deploy → Render + own Neon

kasiro.app → Cloudflare (PROXIED) → Render
Replit: phased out only once the above is proven
```

### What cutover actually changes

| | Before | After |
|---|---|---|
| Authoring | Replit Agent | Replit → later Claude Code / Codex |
| Prod hosting | Replit deployment | Render |
| Prod DB | Replit-managed Postgres (**no access**) | Own Neon (full access) |
| Dev DB | Replit dev DB | Neon dev branch (**must be created**) |
| DNS / edge | Cloudflare (proxied) | Cloudflare (proxied, unchanged) |

The core win is narrow and real: production stops running on a database whose connection string Kaye cannot see.

---

## Critical fact — Scenario B

Production DB is a **separate, Replit-managed Postgres**, provisioned by Replit's deployment system. Kaye has **no Neon console access to it and cannot see the prod connection string** — it is injected only into the published Replit deployment at runtime. The `DATABASE_URL` visible in Replit Secrets is the **dev** DB, not prod.

Consequence: the prod dump must be produced from *inside* the running deployment (Prompt 13 endpoint).

---

## Decision — Option B, then SIMPLIFIED

- **Option B:** one MERGED cutover moving app + database together. Cannot run long-term on a connection string Kaye does not control.
- **SIMPLIFIED (25 Jul, after operator fatigue with too many moving parts):** collapse to **one app host (Render) + one managed Postgres (own Neon)**.
  - Defer **Cloudflare *hardening*** — WAF rules, origin lock, R2. **Cloudflare DNS + proxy stay; they are already live and in the critical path.**
  - Defer CI, leader-lease, origin-secrets, KMS seed until the app is live and stable.
  - **Do NOT self-host on a VPS** — rejected: unacceptable security burden for a non-technical solo operator holding real funds.

---

## Gate 3 facts (prod DB, captured via Replit read-only SQL)

PostgreSQL 16.14 (aarch64). Extensions: **plpgsql only**. Size ~40 MB. `max_connections` 450.
Schema: **89 tables, 1 function, 1 trigger, 13 enums** (matches dev).
Rows: users 18, wallets 18, ledger_entries 1,415, withdrawals 0, markets 165, positions 150, trades 335, webhook_events 1.
Balances: **available 11,060.22 USDT**, locked 0.00.

> `wallets` column is `available_balance`, **not** `balance`.

These figures move while prod is live. **The authoritative baseline is taken at the freeze during the real cutover** — do not validate against the numbers above.

**Dev baseline** (proven restore target during rehearsal): 89 tables, 13 enums, 16 wallets, 585 ledger_entries, available 1,248.18 USDT.

---

## WHERE WE ARE RIGHT NOW

**App is LIVE on Render against Kaye's own Neon, serving restored DEV data.**

Verified live 25 Jul 2026:

- `https://kasiro-prod.onrender.com/api/health` → 200
- `/api/ready` → 200 `{"status":"ready"}`
- All 6 assets serve correctly — `index-Cla2n2Oe.css` 200 `text/css` (168 KB), `main-CGgAIMHQ.js` 200 `text/javascript` (577 KB), plus radix / recharts / lucide chunks
- `/api/markets` → 200, 55 KB JSON
- SPA route `/markets` → 200 `text/html` (catch-all working, `/assets` correctly excluded)

**Previous blocker (static assets returning 500 / CSS served as `application/json`) is RESOLVED.**

Remaining truth: Render is running **dev data with a dev HD wallet seed**. It is not production and must not receive traffic until the cutover steps below are complete.

---

## Immediate next actions (in order)

### 1. Harden Neon before any prod data touches it

Free tier gives only **6 hours** of PITR. Do this *now*, not at cutover:

- Free → **Launch** plan
- **PITR → 7 days**
- **Disable scale-to-zero** (cold starts also make Render health checks flap)
- Min compute **0.25 CU**

Cost ~$20–80/mo.

### 2. Smoke-test the dev clone while it is still harmless

Last window where breaking things is free. In a browser against `kasiro-prod.onrender.com`:

- signup / login
- market list → open a market page
- place a trade
- Results page
- admin route (403 until `ADMIN_EMAILS` is set — set it, confirm it works)

### 3. Real prod cutover

1. Freeze prod.
2. Capture **authoritative baseline** at freeze (row counts + balances) — not the Gate 3 numbers.
3. In-deployment `pg_dump` via Prompt 13 endpoint.
4. Restore into own Neon.
5. **Set Render env to PROD values** — see the seed gate below.
6. **Set `TRUST_PROXY_HOPS=2`** — see the Cloudflare section below.
7. Attach `kasiro.app` to the Render service and let the cert issue **before** flipping the proxy.
8. Switch Cloudflare DNS to Render.
9. Verify `/api/debug/ip` returns a real client IP.

---

## HARD GATE — HD wallet seed

Render currently holds the **dev/test** `HD_WALLET_MASTER_SEED`.

If prod data lands while the seed is still dev, **every derived deposit address is wrong and user funds route to addresses Kaye does not control.**

At cutover, swap to the real prod seed **and** the prod `PLATFORM_USER_ID`, then **verify a known user's deposit address matches the prod value before opening any traffic.** This is the single highest-risk variable in the migration.

---

## Cloudflare — already live, NOT deferred

Verified 25 Jul 2026:

```
kasiro.app → 104.21.71.40, 172.67.143.22   (Cloudflare anycast)
NS: matias.ns.cloudflare.com, heather.ns.cloudflare.com
curl -I https://kasiro.app → server: cloudflare
```

kasiro.app is **proxied** (orange cloud) through Cloudflare to the Replit deployment today. Only Cloudflare *hardening* is deferred. DNS + proxy are in the critical path and the DNS switch is the final cutover step.

### `TRUST_PROXY_HOPS` must become 2

Prompt 4 shipped this env var with default `1`. Post-cutover there will be **two** proxies in front of Express: Cloudflare, then Render's load balancer.

Left at `1`, Express resolves `req.ip` to a **Cloudflare edge IP** instead of the real user. Consequences:

- Rate limiters key on a handful of Cloudflare IPs → one user tripping a limit throttles everyone
- Audit logs record Cloudflare IPs against real-money actions

Set `TRUST_PROXY_HOPS=2` in the same change as the DNS switch, then confirm via `/api/debug/ip` (behind `MONITOR_TOKEN`) that `req.ip` is a real client address.

### Other edge items

- Cloudflare SSL mode must be **Full (strict)** against the Render origin — not Flexible.
- `www.kasiro.app` is **NXDOMAIN** (no record). Decide whether a redirect is wanted.
- Attach the hostname to Render and let the cert issue before flipping the proxy, or expect a brief handshake failure.

---

## Replit phase-out — sequencing and the dev DB gap

Replit is **not just a host** — it is currently the IDE and the agent. Cutover removes Replit as *host* and as *prod DB owner*. Authoring migrates separately and later, to Claude Code / Codex.

**Do not close the Replit account at cutover.** Keep it until local authoring is proven.

### The gap: when Replit goes, the dev database goes with it

Claude Code and Codex do not come with a dev DB. If none exists, the failure mode is an operator or agent developing against the **production** connection string because it is the only one configured. With $11K of user funds that is the worst available outcome.

**Fix:** create a **Neon dev branch** off prod (copy-on-write, seconds, cheap). Because it contains real balances and PII, run a scrub (null emails, retain shape) before agents read it.

### Required ordering

```
Render + Neon live
  → DNS switch
  → create Neon dev branch + scrub
  → prove local dev works against the branch
  → THEN wind Replit down
```

### Porting the dev environment from Replit — mostly unnecessary

| Piece | Port? | Why |
|---|---|---|
| Code | No | Already in GitHub; `git clone` *is* the port |
| `.replit` / `replit.nix` | No | Replit-specific, worthless off-platform |
| Dev DB data | No | Neon branch off prod gives better-shaped data than 16 test wallets / 585 junk ledger rows |
| **Secrets** | **Yes** | Replit Secrets → Bitwarden → local git-ignored `.env` |

Confirm `.gitignore` covers `.env` **before** creating it — Claude Code and Codex both read the working tree.

Local prerequisites: Node 20, npm, `psql` client tools.

---

## Repos — roles and rules

### `github.com/GinniNio/Prolego2` — code

Render deploys from `main`.

### `C:\Dev\Kasiro` — local mirror

**Today: pull-only redundancy.** Never `git commit` here while Replit is the authoring environment.

```powershell
cd C:\Dev\Kasiro
git fetch origin
git status
git log --oneline HEAD..origin/main    # what you're missing
git pull --ff-only origin main
```

`--ff-only` is deliberate and permanent for as long as the mirror role holds: if it ever refuses to fast-forward, something wrote to the mirror that should not have, and force-pulling would hide it.

If `git status` shows local modifications:

```powershell
git stash push -u -m "local wip before pull"
git pull --ff-only origin main
git stash pop
```

Run `npm install` after a pull if `package.json` / `package-lock.json` changed.

> **Do not** run `npm run db:push` or any Drizzle migration against a `DATABASE_URL` pointing at Neon. That instance holds restored dev data and will receive the prod restore. Check what `.env` resolves to before any DB command.

**ROLE CHANGE AT PHASE-OUT:** once Claude Code / Codex become the authoring environment, `C:\Dev\Kasiro` becomes the **primary workspace** and the pull-only / never-commit rule **expires**. Do not inherit the stale rule.

### `github.com/GinniNio/kasiro-brain` — operating state

Working copy currently at `C:\Users\hp\OneDrive\Documents\Claude\Projects\Predicto\kasiro-brain`. GitHub is what provides any-machine / any-agent access; OneDrive is an incidental second sync layer.

Written **only** by agent sessions, so the risk is inverted from the code repo: uncommitted local edits that never get pushed. This has already happened once — commit `0b0975c` is a "carry over uncommitted 2026-07-20/21 state" cleanup.

```powershell
cd "C:\Users\hp\OneDrive\Documents\Claude\Projects\Predicto\kasiro-brain"
git fetch origin
git status
git add -A
git commit -m "Session <date>: <what changed>"
git push origin main
```

If behind as well, prefer `git pull --rebase origin main` — this repo is a linear log of session state and merge commits make it harder to read back.

> `KASIRO_BRAIN.md` lists the OneDrive Predicto folder under *What Is Dead / Archived*. That is now misleading: the brain repo lives there deliberately. Correct the entry to note the exception.

---

## Cloud accounts / services in play

- **GitHub:** `GinniNio/Prolego2` (Render deploys from `main`); `GinniNio/kasiro-brain`.
- **Render:** service `kasiro-prod`, region **Frankfurt/EU**, Docker runtime, Standard instance (2 GB), 1 instance, health check `/api/health`. Temp URL `kasiro-prod.onrender.com`.
  - MCP: `claude mcp add --transport http render https://mcp.render.com/mcp --header "Authorization: Bearer <RENDER_API_KEY>"` (OAuth uses API key).
- **Neon (Kaye-owned):** project in **Frankfurt (AWS eu-central-1)**, host `ep-damp-cloud-ag12hvc1.c-2.eu-central-1.aws.neon.tech` (**DIRECT** endpoint, no `-pooler`), db `neondb`, role `neondb_owner`. Currently holds restored DEV data. **Still to do: Launch plan, scale-to-zero off, PITR 7 days, min 0.25 CU.**
- **Replit:** dev workspace + published prod deployment. Prod DB is Replit-managed (Scenario B). **Keep account open until local authoring is proven — not merely until cutover.**
- **Bitwarden:** vault for all secrets. See `Using Bitwarden for the Kasiro Migration.docx`.
- **Cloudflare:** DNS + proxy, **LIVE** (see Cloudflare section). Hardening deferred.
- **Cloudflare R2:** intended for prod dump storage. Dev rehearsal used the download-only variant, so R2 / AWS SDK not needed yet — AWS SDK was **removed** from `package.json` to fix the Docker build (see npm saga).

---

## Render env vars currently set (dev values — Render is a dev clone)

`DATABASE_URL` (own Neon direct URL), `SESSION_SECRET`, `PLATFORM_USER_ID`, `CRON_SECRET`, `MONITOR_TOKEN`, `HD_WALLET_MASTER_SEED` (**dev/test seed — NOT prod**).

Deliberately unset: `CRON_LEADER` (no workers), `TELEGRAM_BOT_TOKEN` (would block boot without webhook secret), `ADMIN_EMAILS` (admin routes 403 until set). Kora disabled.

---

## Code changes made so far (in repo, via Replit Agent)

- **Prompt 1 (Dockerfile):** multi-stage Node build; installs canvas native libs (`libcairo2 libpango-1.0-0 libjpeg62-turbo libgif7`); non-root; `/api/health` (liveness, no DB) + `/api/ready` (DB + `public._drizzle_migrations` check); 10–15 s graceful shutdown. Loggers already stdout/stderr only.
- **Prompt 2:** moved ~34 startup data-fix/seed tasks OUT of boot into `scripts/db-deploy.ts` (gated `RUN_DB_DEPLOY=once`, uses `DATABASE_ADMIN_URL ?? DATABASE_URL`, rejects `-pooler` host, `statement_timeout='5000ms'`). Kept on boot: connectivity check, `seedDatabase`, `ensureOperatorUser` (INSERT/UPDATE only, no DDL). `ensureMetricsTable` (DDL) moved to db-deploy.
- **Prompt 4:** `TRUST_PROXY_HOPS` env (default 1), startup log, `/api/debug/ip` (behind `MONITOR_TOKEN`) returning `req.ip` / XFF / CF-Connecting-IP. **Set to 2 at cutover — see Cloudflare section.**
- **Prompt 13 (db-export):** `POST /api/admin/db-export` — super_admin + `MONITOR_TOKEN` + `{confirm:"EXPORT_CONFIRMED"}`; one-shot (stamps `_applied_fixes` key `db_export_completed_once`, 410 on re-call); runs `pg_dump` (plain SQL `--clean --if-exists --no-owner --no-acl` | gzip) to `/tmp`; verifies BOTH pg_dump and gzip exit 0 before serving; then download OR R2. Restore = `gunzip -c | psql`.
  - **TODO for prod:** switch to `--format=custom` for `pg_restore -j` (parallel, faster).
  - Dev rehearsal **PROVEN:** dump dev (484 KB gz) → restore to own Neon → 5-metric validation matched.

---

## The npm / Docker saga (so you DON'T repeat it)

Fresh `npm ci` in Docker crashed at a consistent ~71 s with `npm error Exit handler never called!`.

Chased and failed: Node 22→20, npm 10.9.8→10.8.2→11.4.2, parallel-vs-single stages, `--ignore-scripts`, `--include=dev`.

**Actual resolution:** removing `@aws-sdk/client-s3` + `@aws-sdk/lib-storage` (huge dep tree, added in Prompt 13) unblocked the build.

Final working Dockerfile: **Node 20**, single `npm ci --include=dev`, build with **`NODE_ENV=production`** (a `NODE_ENV=development` builder was producing a dev Vite bundle — fixed), `npm prune --omit=dev`, non-root, `CMD ["node","dist/index.cjs"]`.

Add AWS SDK back later only via a CI-built image, and only if R2 is wanted.

---

## Deferred / optional (post-live, as Kaye grows)

Cloudflare hardening (WAF, origin lock), CI (Prompt 6), leader-lease (Prompt 9A/B/C), seed KMS (Prompt 10), Kora payload sanitize (Prompt 11), trongrid gap-fill (Prompt 12), least-privilege DB role (Prompt 7), R2 / AWS SDK re-add.

---

## Carry-forwards from brain state

- **CI on `main` unconfirmed green** after the 07-19 push (6 failing tests; fix dispatched, never reconfirmed).
- **Process rule (07-20):** "shipped" requires a **live-URL check** before being logged as closed. This rule is what caught the static-asset bug on 25 Jul.
- **Kora NGN deposits** live in production at 45% rollout; payouts still off. Detail in `domains/eng.md` → Naira Payments, and `C:\Dev\Kasiro\docs\handoffs\2026-07-19-kora-ngn-payments-production-launch.md`.

---

## Cost model

Render Standard $25 + Neon Launch always-on ~$20–80 + extras → **~$50/mo lean, ~$150/mo robust**. Verified detail inside `Kasiro Render Implementation Guide V3.5+`.

---

## Companion documents

- `Kasiro Render Implementation Guide V3.9 — Option B merged cutover.docx` — full governing plan (supersedes earlier V2.x / V3.x + hardening reviews).
- `Kasiro Move — Super Simple Step-by-Step (Option B, merged).docx` — plain-English operator walkthrough.
- `Using Bitwarden for the Kasiro Migration.docx` — secrets handling.

---

## Working style / preferences

Concise, direct, first-principles. No fluff. Confirm approach + list files before writing code. Verify present-day facts by checking, not recalling. External reviewers have stress-tested this plan hard — expect rigorous pushback, respond evenhandedly, and correct the record when wrong.
