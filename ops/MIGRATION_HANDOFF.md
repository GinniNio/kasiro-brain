# HANDOFF — Kasiro Migration: Current State & Next Steps

_Last updated: 25 July 2026 (end of session). Give this file to a fresh Claude Code / Codex / Cowork instance to resume with full context._

---

# ▶ START HERE — resuming 26 July 2026

**Where we got to:** the app is live on Render against Kaye's own Neon, the full smoke test passed (read **and** write paths), and the AMM pricing defect that was live since launch is fixed and verified end-to-end with a real trade. Neon is on Launch with PITR/scale-to-zero configured. The env parity audit is done. **The cutover itself has not started.**

**Do these first, in this order. None require a freeze.**

1. **Smoke-test the Naira withdrawal path.** Payouts were enabled and verified live on 25 Jul, closing the one-way door — but request-to-money-landed has never been exercised. Use the operator account and a small amount. Bank payouts run through manual admin approval, so there is a human gate, but the flow is untested. Note the remaining asymmetry: deposits at 100% rollout, payouts at 45%.

2. **Dockerfile: add `ARG`/`ENV` for the `VITE_*` vars** before `npm run build`. Without it, `VITE_KORA_MODE=live` cannot reach the Render build and Kora checkout silently falls back to test mode. Exact snippet in the env audit section.

3. **Prompt 13: switch the dump to `--format=custom`** so the restore can use `pg_restore -j`. Shortens the freeze window, which now has a real cost.

4. **Add a seed-validity assertion** before the HD wallet swap. `Buffer.from(seed,"hex")` accepts malformed input and derives a wrong-but-plausible address set with no error.

5. **Confirm CI is green on `main`** — outstanding since the 07-19 push (6 failing tests, fix dispatched, never reconfirmed).

> ✅ **`adjust-price` containment — DONE 26 Jul** (commit `1682092`). Was the one pre-cutover item with a deadline. See "Closed items" below.

**Then the cutover** (§ "Immediate next actions" → step 3). Now needs a maintenance window and a user notice, because real Naira is flowing.

**Queued for immediately AFTER cutover — do not start before it.** `market-integrity-doctrine-and-spec.md` §3: the `external_trading_started_at` marker, its DB trigger, the production backfill, market-row locks and the admin guards, shipped as **one release**, then reconciliation, then admin financial controls restored. Held until after the move because items 1–3 of that build touch the trade transaction, which is the last code that should change in the same week as a host migration.

**The three things most likely to bite, all silent failures:**

| | Why it kills you |
|---|---|
| `CRON_LEADER=1` | Unset = TronGrid polling never runs = real USDT deposits land on-chain and are never credited |
| `TRONGRID_API_KEY` | Unset = deposit addresses 503, no issuance and no detection |
| Prod `HD_WALLET_MASTER_SEED` | Wrong = user funds route to addresses Kaye does not control |

**Session log for 25 Jul:** fixed the static-asset blocker; found and fixed a CORS gap that had killed every write path; ran the full smoke test (read + write, including a real trade); found, diagnosed and verified the fix for the AMM pricing inversion (SEV1, now RESOLVED — see `SEV1-amm-pricing-replit-prompt.md`); specified and shipped the parimutuel rake-convention fix (SEV2 — see `SEV2-parimutuel-rake-convention.md`); completed the env parity audit (45 vars missing on Render); adopted doctrine rule 16 and wrote `market-integrity-doctrine-and-spec.md`.

**Companion docs in this folder:**

| File | What it carries |
|---|---|
| `SEV1-amm-pricing-replit-prompt.md` | AMM pricing inversion — RESOLVED, with live verification and the deploy lesson |
| `SEV2-parimutuel-rake-convention.md` | Rake-on-losses, shared calculator, operator seeding by weight |
| `market-integrity-doctrine-and-spec.md` | Rule 16, `adjust-price` containment, protection-state build, acceptance test matrix |

**Closed items — `adjust-price` containment (26 Jul, commit `1682092`)**

`handleAdminAdjustPrice` was doing a read-modify-write across **two separate connections** (`storage.getMarket` then `storage.updateMarket`) with nothing holding the market row in between — a concurrent trade committing in that window was silently overwritten. Now a single transaction: `pool.connect()` → `BEGIN` → `SELECT … FOR UPDATE` on the market row → all guards evaluated against the locked row → write on the same client → `COMMIT`, with `ROLLBACK` on every early return and `client.release()` in `finally`.

Interim guard added: `total_trades > 0` → `409 MARKET_HAS_TRADES`. Deliberately **stricter than final policy** — it counts operator trades too. Post-cutover this is replaced by `external_trading_started_at IS NOT NULL`, at which point operator-only markets become repriceable again (`market-integrity-doctrine-and-spec.md` §3).

Two properties worth remembering:

- `total_trades` is read **from the locked SELECT**, not a second query, so there is no window between the lock and the check.
- The trade path increments `total_trades` inside the same transaction that holds the market lock (`server/trades/amm-buy.ts:173`), so the two paths genuinely serialise.

**Side effect: doctrine rule 16 is now effectively enforced on the AMM side.** `poolsFromPrice` still changes `k` (see spec §1), but with reprice restricted to zero-trade markets there are no positions whose exit price could move. The guard was aimed at the concurrency defect and closed the governance hole as a consequence.

**Fixed 25–26 Jul, recorded because the mechanism recurs:**

- **Stale-chunk failures after every deploy.** `index.html` was served with `maxAge: "1h"`, so a returning user held a pre-deploy shell referencing content-hashed chunk URLs that no longer existed → `lazy()` import rejects → `RouteErrorBoundary` → "Something went wrong". Compounded by a service worker caching navigations under a **static** `CACHE_NAME`, which meant `activate` never purged the old shell. Fixed: `no-cache, no-store, must-revalidate` on `/`, `/admin` and `/sw.js`; `CACHE_NAME` now build-derived; `skipWaiting()` + `clients.claim()`. Verified live. **Note the SPA fallback (`res.sendFile`) is a different code path from `express.static` — both needed the header.**
- **`<SelectItem value="">` in `CreateMarketForm.tsx:1392`.** Radix reserves `""` for "no selection", so the create-market page threw on mount. Surfaced now because `"@radix-ui/react-select": "^2.1.7"` is a caret range and the Docker `npm ci` work pulled a stricter 2.x — the code didn't change, the library did. Fixed with a `__none__` sentinel translated at the boundary so `competitionId` keeps `""` semantics. Only instance in the client.

**Open — worth a small change:** `RouteErrorBoundary` shows "Something went wrong" with no error identity. Two unrelated bugs (stale chunk, then the Radix throw) presented identically and cost a deploy cycle to tell apart. The boundary already holds the error object; surfacing the error name or a short code, even in small text, would have made the second diagnosis immediate.

**Known-open, not blocking cutover:** price formatters mislabel currency in two places (`₦65` for a ₦890 share price; `$100.00` for a ₦100 minimum) — one focused pass, worth doing before real volume. `/dev/pool-layouts` still hardcodes rake-on-total. One production market still has a `NULL proposition_fingerprint`, invisible to the duplicate gate. Unknown `/api/*` paths return HTML instead of a JSON 404. CSP still allows `connect-src https://api.anthropic.com`.

---

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
*(detail — see START HERE at the top for the resume checklist)*

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

Free tier gives only **6 hours** of PITR. Do this *before* the prod restore, not at cutover:

- [x] Free → **Launch** plan — **DONE 2026-07-25**
- [ ] **PITR / history retention → 7 days** (Launch permits up to 7d but does not default to it)
- [ ] **Disable scale-to-zero** (cold starts also make Render `/api/health` checks flap)
- [ ] Min compute **0.25 CU**

Plan upgrade alone does not apply the three settings below it — they are separate compute toggles and must be set explicitly.

Cost ~$20–80/mo.

### 2. Smoke-test the dev clone while it is still harmless

**Read paths: COMPLETE 2026-07-25.** All render, all API 200 except the one noted below.

| Screen | Result |
|---|---|
| Home / market list / filters / categories | ✅ |
| Market detail (AMM + parimutuel cards) | ✅ |
| Signup / login | ✅ (after the CORS fix) |
| `/portfolio` | ✅ ₦6,835 / $5.00, no positions, P&L zeroed |
| `/wallet` | ✅ balance correct, demo-credit banner correctly gates withdrawals |
| `/leaderboard` | ✅ (empty — no settled markets) |
| `/indices` | ✅ ("0 live now", all Coming soon — product state, not a defect) |
| Results (nav → `/winners`) | ✅ "No resolved markets this week" |
| Console errors | ✅ none from app code (only a browser wallet-extension collision) |

> Note: `/results` is not a route — the Results nav item points at `/winners`.

**Write path: COMPLETE 2026-07-25 — real trade executed, arithmetic exact.**

Bought 0.37 YES on the Davido market (pools 35/65, quoted 0.65). Every figure matched the complete-sets AMM to six decimals:

```
                        expected        actual
cost                    NGN 329.2       NGN 329       ✓
fee (2.5%)              NGN 8.2
total debited           NGN 337.4       NGN 337   (6,835 -> 6,498)  ✓
pools after   yes       34.870811       34.870811     ✓
              no        65.240811       65.240811     ✓
yesPrice      0.65  ->  0.651681        0.651681      ✓ rose
volume                  0.246831        0.246831      ✓
```

This closes SEV1 at every layer — quote, execution, pool state, and ledger. Buying YES raises the YES price on a live trade, not just in a unit test.

**Still outstanding:**

- [ ] **Admin access needs a DB update, not just env.** `requireAdmin` (`server/middleware/requireAdmin.ts`) fails closed on TWO conditions: `user.role === "admin"` (L8) AND email present in `ADMIN_EMAILS` (L15). Setting the env var satisfies only the second. `role` is set automatically only in `server/passport.ts` (OAuth strategies) — `handleRegister` for email signup never sets it. Fix:
  ```sql
  UPDATE users SET role = 'admin' WHERE email = '<operator email>';
  ```
  **The same two-step applies at cutover on prod.** Swapping `ADMIN_EMAILS` alone will not grant access.

### Display bugs found during the trade (presentational only — cost basis and P&L are correct)

- **Portfolio price-per-share is mislabelled.** True price is `0.650841 USDT = NGN 890`. The card renders `Bought at: NGN 65 · Now NGN 65` — the USDT price multiplied by 100 and given a Naira symbol. Prediction-market cents mislabelled as Naira, off by ~13.7x.
- Same family as the trade-panel bug logged earlier: `Min stake: $100.00` in USDT mode, where the Naira figure (100) is rendered with a `$` prefix instead of converted.

Both point at a systematic problem in the **price formatters** specifically — the amount formatters (cost, balance, P&L) are correct throughout. Worth fixing as one pass rather than individually.

### ⚠️ FOUND 2026-07-25 — second missing env var: `TRONGRID_API_KEY`

`GET /api/wallet/deposit-info` returns **503 "Deposit system not configured"** on every page load (it is fired by a global wallet hook, not just `/wallet`).

Cause: `isHDWalletConfigured()` in `server/trongrid.ts:59` requires **both** vars:

```ts
return !!HD_WALLET_MASTER_SEED && !!TRONGRID_API_KEY;
```

`HD_WALLET_MASTER_SEED` is set on Render; **`TRONGRID_API_KEY` is not** — and it appears in neither the "currently set" nor the "deliberately unset" list in this document. Same class of gap as the CORS one: an unlisted variable that silently disables a core money path.

`server/trongrid.ts:193` shows the deposit *polling loop* short-circuits on the same check, so both address issuance and deposit detection are off without it.

**Failing closed here is correct behaviour** — the dev clone must not hand out addresses derived from the dev seed. But at cutover, if `TRONGRID_API_KEY` is missing, **no user can deposit** and nothing in the UI explains why.

**Use this endpoint as the cutover canary:** after setting the prod seed and key, `GET /api/wallet/deposit-info` must return **200**, and the returned address must match a known-good production deposit address for that user.

### ⚠️ Related hardening gap — seed validity is never checked

`isHDWalletConfigured()` tests **presence, not validity**. `getMasterSeed()` (`trongrid.ts:63-68`) accepts a BIP-39 mnemonic *or* falls through to `Buffer.from(HD_WALLET_MASTER_SEED, "hex")`, which silently ignores invalid characters and truncates.

A malformed prod seed therefore produces a **valid-looking but wrong** address set, with no error anywhere — which is exactly the catastrophic scenario in the HD-wallet hard gate below. Add a length/format assertion on the derived seed before the cutover swap, and verify a known user's deposit address rather than trusting a clean boot.

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

## ENV PARITY AUDIT — 2026-07-25 (Replit Secrets vs Render)

Render has **8** vars; Replit has **32**. **25 missing.** Nothing is on Render but absent from Replit. Only three values legitimately differ: `DATABASE_URL`, `HD_WALLET_MASTER_SEED`, `PLATFORM_USER_ID`.

Replit **Configurations** holds a further **20** non-secret vars, none of them on Render.

### 🔴 `CRON_LEADER` — mandatory at cutover, currently unset on Render

```
index.ts:646  if (process.env.CRON_LEADER === "1") { ...start workers... }
index.ts:689  else → "Not cron leader — skipping background workers"
```

Gates **every** background job: TronGrid deposit polling, settlement, expiry alerts, resolution checks. Replit Configurations has `CRON_LEADER = 1`.

Unset is correct while Render runs *alongside* live Replit. **At cutover Render becomes the only host — `CRON_LEADER=1` becomes mandatory.** Left unset, deposits are never credited even with `TRONGRID_API_KEY` present, because the polling loop never starts. This document previously listed it only under "deliberately unset"; that framing is safe now and catastrophic if carried through the cutover.

### 🔴 Kora — deposits opened to 100% on 2026-07-25 (mid-migration)

```
KORA_DEPOSIT_ROLLOUT_PERCENT = 100     ← was 0 earlier the same day
KORA_PAYOUT_ROLLOUT_PERCENT  = 45
KORA_PAYOUTS_ENABLED         = false   ← payouts DISABLED regardless of the 45%
KORA_PAYMENTS_ENABLED        = true
KORA_MODE                    = live
KORA_INTERNAL_USER_IDS       = 7553487c-d93f-4b91-9d93-e8b6db620ea3
```

Verified live: `GET https://kasiro.app/api/payments/config` → `koraPaymentsEnabled: true, koraPayoutsEnabled: false`.

**Documentation correction:** earlier text here and in memory claimed *"deposits live at 45% rollout, payouts still off"*. The 45% was always on **payouts**, which are disabled. Deposits were at **0**, and are now at **100**.

#### ✅ RESOLVED 2026-07-25 — payouts enabled, one-way door closed

`KORA_PAYOUTS_ENABLED` set to `true` and the deployment republished. Verified live:
`GET https://kasiro.app/api/payments/config` → `koraPaymentsEnabled: true, koraPayoutsEnabled: true`, with `/api/health` and `/api/markets` both 200.

The clean boot also confirms `KORA_SECRET_KEY` is a **live-mode** key: `validateKeyModeConsistency(secretKey, mode)` runs whenever either rail is active, so a `sk_test_` key against `KORA_MODE = live` would throw.

**Republish gotcha, recorded for next time:** `getKoraConfig()` calls `buildKoraConfig()` on every request (no memoisation), so it reads `process.env` fresh — but a Replit **Configurations** change does not mutate the environment of an already-running deployment. Config edits require a **republish** to take effect. Enabling a rail also activates `validateKeyModeConsistency`, and because the config is rebuilt per request rather than cached at boot, a mismatch surfaces as a **500 on every Kora request**, not a clean startup failure.

#### Still open

- **Rollout asymmetry:** `KORA_DEPOSIT_ROLLOUT_PERCENT = 100` vs `KORA_PAYOUT_ROLLOUT_PERCENT = 45`. Everyone can deposit; fewer than half can withdraw. Much better than a closed door, still not symmetric.
- **The withdrawal path has never been smoke-tested end to end.** Testing deliberately stopped short of submitting a withdrawal. Bank payouts run through manual admin approval (`/api/admin/withdrawals/bank/:id/approve` → `/execute`), so there is a human gate, but request-to-money-landed is unexercised. Do it with the operator account and a small amount before anyone else's payout arrives.

#### ⚠️ This raises cutover risk materially

Every earlier assumption in this document was priced on *no real users, no real money*. That is no longer true:

- **The freeze window now has a real cost.** Users mid-deposit during dump/restore will see failures. Needs a maintenance window and a notice, not a silent switch.
- **`CRON_LEADER` moves from important to critical.** Kora deposits credit via webhook, but **USDT deposits credit via the TronGrid polling loop, which only runs on the cron leader**. Unset at cutover = real on-chain deposits are never credited. Users watch funds leave their wallet and never arrive.
- **`KORA_NOTIFICATION_URL = https://kasiro.app/api/webhooks/kora`** is correct after DNS moves, but there is a window during the switch where delivery target is ambiguous. Confirm Kora's failed-webhook retry behaviour before freezing.

**Recommendation: hold deposits at a low rollout percentage until after cutover.** Changing the money-in path and the hosting substrate in the same week means two novel failure sources debugged simultaneously.

### `VITE_KORA_MODE` — NOT a bug (corrected)

An earlier draft of this audit claimed `VITE_KORA_MODE` was set nowhere and every build shipped `koraMode = "test"`. **That was wrong** — it is set in Configurations as `live`, matching server-side `KORA_MODE = live`. Client and server agree. No build-flag defect.

The **Dockerfile change is still required**, because `VITE_*` vars are inlined by Vite at `npm run build` and Render's runtime environment cannot reach them:

```dockerfile
ARG VITE_KORA_MODE
ARG VITE_POSTHOG_KEY
ENV VITE_KORA_MODE=$VITE_KORA_MODE \
    VITE_POSTHOG_KEY=$VITE_POSTHOG_KEY
RUN NODE_ENV=production npm run build
```

Same class as the `NODE_ENV=development` dev-bundle bug already fixed at Dockerfile line 25.

### Configurations — port list

| Variable | Value on Replit | Cutover action |
|---|---|---|
| `CRON_LEADER` | `1` | **MUST SET on Render** — see above |
| `VITE_KORA_MODE` | `live` | **Build arg** |
| `KORA_MODE` | `live` | Set |
| `KORA_PAYMENTS_ENABLED` | `true` | Set |
| `KORA_PAYOUTS_ENABLED` | `false` | Set |
| `KORA_DEPOSIT_ROLLOUT_PERCENT` | `0` | Set — deliberate 0 |
| `KORA_PAYOUT_ROLLOUT_PERCENT` | `45` | Set |
| `KORA_INTERNAL_USER_IDS` | one UUID | Set |
| `KORA_NOTIFICATION_URL` | `https://kasiro.app/api/webhooks/kora` | Set — already points at kasiro.app, correct post-DNS |
| `KORA_REDIRECT_URL` | `https://kasiro.app/wallet/payment-result` | Set — same |
| `KORA_DAILY_DEPOSIT_LIMIT_NGN` / `_WITHDRAWAL_` | `150000` | Set |
| `KORA_MAX_DEPOSIT_NGN` / `KORA_MAX_WITHDRAWAL_NGN` | `50000` | Set |
| `ALERT_EMAILS_ENABLED` | `true` | Set |
| `USE_LIST_PUBLIC_MARKETS` | `true` | Set |
| `PLAY_DEMO_ENABLED` | `true` | Decide |
| `NODE_OPTIONS` | `--enable-source-maps` | Optional |
| `ALLOWED_ORIGINS` | `https://predicto-build.replit.app` | **Do NOT port as-is** — stale Replit dev URL. Use `https://kasiro.app`. Works today only because `APP_URL` separately allowlists the real domain. |
| `RUN_STARTUP_MIGRATIONS` | `1` | **DEAD CONFIG — do not port.** `index.ts:322-324`: flag removed; migrations run only via the deploy build step (`docs/RUNBOOK-DEPLOY.md`). |

**The pattern: every dangerous omission fails silently.** The app boots green, pages render, and one money path is dead with nothing surfaced. That is why this audit belongs before the freeze, not during it.

### ⚠️ Build-time, not runtime — `VITE_*`

`VITE_KORA_MODE` and `VITE_POSTHOG_KEY` are read via `import.meta.env` and inlined by Vite at `npm run build`. **Setting them in Render's runtime environment does nothing.**

`VITE_KORA_MODE` is currently set **NOWHERE** — not Secrets, not Configurations, not `.env`, not the Dockerfile, not `vite.config`. Every build ships `koraMode = "test"` (`client/src/lib/kora-checkout.ts:19-26`, fail-closed unless the value is exactly `"live"`).

Consequence depends on the server key:
- `KORA_SECRET_KEY = sk_test_…` → consistent, nothing real moving, no bug.
- `KORA_SECRET_KEY = sk_live_…` → **live bug**: server mints `checkout.korapay.com`, client accepts only `test-checkout.korapay.com`, so every Naira deposit fails at the final step for the 45% cohort. Presents as a Kora fault, is actually a build flag.

**Dockerfile change required either way** — it currently has no `ARG` for any `VITE_` var:

```dockerfile
ARG VITE_KORA_MODE
ARG VITE_POSTHOG_KEY
ENV VITE_KORA_MODE=$VITE_KORA_MODE \
    VITE_POSTHOG_KEY=$VITE_POSTHOG_KEY
RUN NODE_ENV=production npm run build
```

Same class as the `NODE_ENV=development` dev-bundle bug already fixed at Dockerfile line 25.

### ⚠️ `PLAY_PHONE_ENC_KEY` is an encryption key, not a credential

`shared/schema.ts:1553` — `encrypted_phone = AES-256-GCM(msisdn, PLAY_PHONE_ENC_KEY)`, 32 bytes (64 hex chars). **If it changes, every encrypted phone number becomes permanently unreadable.** Carry it over byte-exact and back it up in Bitwarden before touching anything.

### Missing from Render — 25

| Variable | Breaks if missing | Action |
|---|---|---|
| `TRONGRID_API_KEY` | USDT deposits — address issuance AND detection | **Cutover** |
| `KORA_PUBLIC_KEY` / `KORA_SECRET_KEY` | Naira deposits (live, 45% rollout) | **Cutover** |
| `VITE_KORA_MODE` | Kora silently falls back to test mode | **Build arg** |
| `PLAY_PHONE_ENC_KEY` | Encrypted phone data unreadable — irreversible | **Cutover, exact** |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google sign-in dead — Google-registered users locked out | **Cutover** |
| `APP_URL` | OAuth callback + CORS root domain | **Cutover** = `https://kasiro.app` |
| `RESEND_API_KEY` / `RESEND_FROM_EMAIL` | All email, incl. **password reset** | **Cutover** |
| `TATUM_API_KEY` | `isDemoMode()` true; webhook HMAC fails (`tatum.ts:70,179`) | Verify scope |
| `TRON_DEPOSIT_ADDRESS` | Not referenced in code — confirm dead | Verify |
| `TELEGRAM_BOT_TOKEN` + `TELEGRAM_WEBHOOK_SECRET` + `TELEGRAM_CHANNEL_ID` | All-or-nothing: token without secret **blocks boot** | Deliberate |
| `WHATSAPP_TOKEN` / `_PHONE_ID` / `_BUSINESS_ACCOUNT_ID` | WhatsApp (still open) | Deliberate |
| `PLAY_DEMO_ENABLED` / `PLAY_SMS_ENABLED` | Feature flags | Decide |
| `FOOTBALL_DATA_API_KEY` | Football seeding skips — degrades gracefully | Low |
| `AI_INTEGRATIONS_ANTHROPIC_API_KEY` / `_BASE_URL` | AI feature | Low |
| `VITE_POSTHOG_KEY` | Analytics console-only | **Build arg**, low |
| `CRON_LEADER` | Already deliberate (no workers) | Deliberate |
| `NEW_NEON_URL` | Migration artifact, not app config | Ignore |

---

## Render env vars currently set (dev values — Render is a dev clone)

`DATABASE_URL` (own Neon direct URL), `SESSION_SECRET`, `PLATFORM_USER_ID`, `CRON_SECRET`, `MONITOR_TOKEN`, `HD_WALLET_MASTER_SEED` (**dev/test seed — NOT prod**).

Deliberately unset: `CRON_LEADER` (no workers), `TELEGRAM_BOT_TOKEN` (would block boot without webhook secret), `ADMIN_EMAILS` (admin routes 403 until set). Kora disabled.

### ⚠️ CORS — accidentally unset, broke ALL writes (found 2026-07-25)

`ALLOWED_ORIGINS` and `APP_URL` were both unset on Render. `server/app.ts` builds its allowlist from those two vars, so in production the allowlist was **empty** and `app.ts:242` threw `Error: Not allowed by CORS` for any request carrying an `Origin` header.

**Symptom:** every POST returned `500 {"error":"internal_server_error"}` while the whole site looked healthy. Registration, login, trading, deposit and withdrawal were all dead.

**Why reads still worked:** browsers omit `Origin` on same-origin GETs, and `app.ts:228` (`if (!origin) return cb(null, true)`) waves those through. Chrome *does* send `Origin` on same-origin POSTs.

**Proof:**

```
POST /api/auth/register  WITH Origin header → 500 {"error":"internal_server_error"}
POST /api/auth/register  NO   Origin header → 400 {"message":"Required"}   (validation reached)
```

**Fix now:**

```
ALLOWED_ORIGINS=https://kasiro-prod.onrender.com
```

Prefer `ALLOWED_ORIGINS` over `APP_URL` here — `APP_URL` also feeds `APP_ROOT_DOMAIN` and the passport OAuth `baseURL`, so pointing it at a temporary Render hostname has unwanted side effects.

**At cutover:** set `APP_URL=https://kasiro.app`. `ALLOWED_SUBDOMAINS` is `["www","play"]`, so `www.kasiro.app` is already allowlisted (still NXDOMAIN in DNS).

**Lesson:** production has `APP_URL` set, which is why signup works on kasiro.app. This was a pure env gap in the new deployment — it would have taken the front door down on cutover day. Audit the full env var list against production before cutover, not just the ones on the checklist.

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
