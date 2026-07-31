# HANDOFF — Kasiro / Portfolio: Next Session
_Give this to a fresh Claude/Cowork session to resume. Kasiro's production cutover is DONE. The current phase is Observe (to ~14 Aug 2026)._
_Last updated: 31 July 2026, post-cutover. Supersedes the pre-cutover HANDOFF-NEXT-SESSION.md and the cutover sections of MIGRATION_HANDOFF.md._

## 1. Who / what
- **Operator:** Kaye — solo, non-technical; treat as devops/platform/infra + product expert. Replit Agent still available for code; verify its production-state claims against shown query output (two false claims on record).
- **Portfolio:** Kasiro (real-money USDT+NGN prediction market, repo `GinniNio/Prolego2`) and GbegeBall (repo `GinniNio/GbegeBall`). Governed by `Portfolio_Operating_Plan_v1.0`. One high-risk production event at a time.

## 2. Current state (verified 31 Jul 2026)
- **kasiro.app runs on Render (`kasiro-prod`, Frankfurt) against Kaye-owned Neon (Frankfurt, direct endpoint).** DNS via Cloudflare (proxied, Full strict). www redirects to root.
- Cutover executed 31 Jul ~15:00–17:00 UTC: freeze via Cloudflare WAF block → baseline → one-shot db-export (worked; latch now set on old Replit DB) → restore matched to six decimals (18 users, ~11K USDT) → prod seed verified by deposit-address equality → DNS switched → reopened.
- **Verified live on new host:** trading (reconciled trade), USDT deposit address derivation, all 8 workers (CRON_LEADER=1 on Render only), admin console (ADMIN_EMAILS set), sessions, TRUST_PROXY_HOPS=2 (real client IPs), **Naira deposits end-to-end** (₦500 live: checkout.korapay.com → webhook → exact credit).
- **NEVER verified:** NGN withdrawal/payout end-to-end. Do a small operator withdrawal during Observe.
- Replit production deployment: shut down (or in progress) — account and workspace stay until local dev is proven.

## 3. Observe phase (until ~14 Aug) — the rules
- Daily reconcile: run `validate.sql` (in Replit workspace) against Neon; watch worker heartbeats (`/api/health/workers` with MONITOR_TOKEN).
- No production code merges to `main` (Render auto-deploys main; no leader-lease yet).
- Fix-forward only; the stale Replit DB is never written again.

## 4. Post-observation queue (in order)
1. **Rotations:** MONITOR_TOKEN (both values exposed in session transcript) + Neon DB password (connection string exposed) → update Render env + Bitwarden.
2. **Cleanup release:** remove `db-export` endpoint + mount; fix `/api/payments/config` (add `optionalAuth`, `Cache-Control: no-store`); CSP allow PostHog or drop it; stale service-worker note (self-heals).
3. `play.kasiro.app` → add as Render custom domain, flip DNS (still points at Replit).
4. Migration discipline: numbered forward-only runner, ban `drizzle-kit push` on prod, least-privilege DB role.
5. Market-integrity protection-state build (`external_trading_started_at` etc.) — first code release after Observe, one release, per `market-integrity-doctrine-and-spec.md` §3.
6. Local dev setup: Neon dev branch off prod + PII scrub + local `.env` (git-ignored) at `C:\Dev\Kasiro` → then Replit wind-down.
7. NGN payout smoke test (if not already done during Observe).

## 5. GbegeBall — Workstream B
Prep may start during Observe (touches no production): review `chore/production-baseline-v2` inventory → restore-proof into disposable Neon PG16 → fix 3 client tests (don't weaken) → merge guardrails → write ARCHITECTURE/OPERATIONS/MIGRATIONS docs. GbegeBall production move only after Kasiro's Observe closes clean.

## 6. Key facts
- Money paths: raw `pg` + `FOR UPDATE` + idempotency (ADR-009). Withdrawals manual-approval. Withdrawal kill switch NEVER built.
- Wallet seed: prod-only, in Bitwarden + Render env. Never rotate during any move. Verify by deposit-address match, not by boot.
- Neon: use DIRECT endpoint for admin/migrations (`-pooler` breaks advisory locks). Launch plan, scale-to-zero OFF, PITR 7d.
- Kora config: rebuilt from env per request, but Render env changes need the redeploy to finish; `VITE_KORA_MODE` is BUILD-time (Dockerfile ARG; changing it needs Clear-build-cache deploy).
- Working docs: `Prolego2 docs/` (STATUS, OPERATIONS, ARCHITECTURE, MIGRATIONS, runbooks) — update STATUS.md to post-cutover state next session. Brain: `kasiro-brain/domains/eng.md` 2026-07-31 entries hold the full cutover record.

## 7. Working style
Concise, direct, first-principles, cite verifiable facts. Confirm approach + list files before code. Simple step-by-step instructions when operating consoles. Verify present-day facts by checking, not recalling.
