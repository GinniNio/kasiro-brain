# Kasiro Product Intelligence
**Domain owner:** Product agent | **Last updated:** 2026-07-12

---

## Conversion Strategy

**Core thesis:** The user Kasiro targets already understands crypto, already understands sports results, and probably already bets. The job is not to explain prediction markets — it's to show that trading YES/NO is better than placing a bet with a bookie or a speculative crypto trade.

**The problem hierarchy** (from kasiro-conversion-plan.md):
1. Users don't understand what they're buying (YES/NO share ≠ a bet ticket)
2. Users don't see a meaningful return on small deposits
3. Users don't trust that they'll be paid out
4. Users don't have a reason to return after their first market

**Conversion funnel:**
```
Deposit → First Trade → Return Visit → Refer a Friend → Power Trader
```

Each step has a different drop-off reason. The signals engine (Loops 1–8) addresses the return visit and referral steps.

**Differentiator framing (from kasiro-conversion-plan.md):**
- vs sportsbook: you trade against the crowd, not the house
- vs crypto: you're trading on things you actually know about
- vs Bayse/2sabi: multi-outcome parimutuel engine — pools not binary only

**WhatsApp shareability constraint:** The app must work fully in environments where WhatsApp is the primary sharing channel — share links must render correctly in WhatsApp previews and Telegram.

---

## Loop System Status

### Shipped and Live (as of 2026-04-24)

| Loop | What it does | Status |
|---|---|---|
| Loop 1 — First Trade | Onboards user through first trade with clear UX | Live |
| Loop 2 — Return | Push notification / Telegram alert when market nears close | Live |
| Loop 3 — Win | Settlement notification, encourages next deposit | Live |
| Loop 4 — Loss | Consolation + next market suggestion | Live |
| Loop 5 — Idle | Re-engagement for users inactive >7 days | Live |
| Loop 6 — Referral | Referral code system, tracked rewards | Live (P0 hardening list outstanding) |
| Loop 7 — Outward | External distribution / ambassador loop | Queued |
| Loop 8a — Social proof | Pool size / trader count signals on market cards | Live |
| Loop 8b — Scarcity | Closing-soon urgency signals | Live (minimum viable) |

**P0 hardening list for Loop 6:** Still outstanding as of last check — referral edge cases and reward distribution hardening.

**Outward stack (Loop 7):** Not yet built. Covers external content distribution to bring new users in via creator/ambassador channels.

---

## Feature Status

### Parimutuel Refactor (P1–P3 shipped 2026-04-24)

| Item | Status |
|---|---|
| Rake from DB (`feeBps`) — dynamic | Shipped |
| Bucket metadata table | Shipped |
| Dynamic layout switch (AMM vs parimutuel) | Shipped |
| Pool card redesign | Open |
| Lock-time display | Open |
| Mobile bottom sheet | Open |

### Market Gates v0.1 / Trust Trail (shipped 2026-05-22)

| Gate | Status |
|---|---|
| `clarity_lint` — blocks poorly formed markets | Shipped |
| `source_check` — blocks markets without verifiable source | Shipped |
| `risk_compliance` — saga/compensating-action pattern | Shipped |
| Scenario tests (5 pending) | Open — activation-rollback is highest-leverage |

### UI Open Items (3 remaining)

Exact items: check `C:\Dev\Kasiro\ACTION_PLAN.md` for current status. As of last review:
- WhatsApp share card rendering
- Dark background direction (aligns with 2sabi + competitor UX)
- [Third item — check ACTION_PLAN.md]

---

## Signals Engine Status

**Inward stack:** Loops 1–6 + 8a + 8b — all live.

**Niche Discovery agent:**
- Local web app, `npm run niche` → localhost:5273
- 4 tabs: Run, Review, Calibrate, Archive
- Heuristic scorer only (no LLM path)
- **Daily scan RETIRED 2026-05-07** — scrape scripts never returned to repo. Revive only after restoring them.

---

## Product Roadmap Priorities

**Current pillar focus:** Check `C:\Dev\Kasiro\ACTION_PLAN.md` for active week focus.

**Operating constraint:** One Pillar One Week. Finite weekly hour budget. Nothing added mid-week.

**Backlog priorities (approximate rank):**
1. Naira payments (Kora) production hardening — see section below; treat as P0 given real money is moving
2. Loop 6 P0 hardening
3. Parimutuel open items (pool card, lock-time, mobile sheet)
4. Market Gates scenario tests (activation-rollback first)
5. Loop 7 outward stack
6. Daily-recurring market franchise (closes category gap vs 2sabi/Bayse)
7. H2H / social wager feature (closes gap vs Bayse)

---

## Naira Payments (Kora) — Status as of 2026-07-12

**Provider:** Kora (not Paycrest — Paycrest plan in `ACTION_PLAN.md`, last updated 2026-05-16, is superseded and should not be treated as current truth for payments).

**Current state:** Live in production, staged rollout — not yet at 100%. Deposits confirmed flowing with `reason_code='deposit_ngn'` in the ledger as of 2026-07-05 (referral funnels, platform stats, churn jobs, reconciliation all updated to include it — see `eng.md` / `.agents/memory/deposit-ngn-consumers.md`). Rollout percentage is controlled via `KORA_DEPOSIT_ROLLOUT_PERCENT` / `KORA_PAYOUT_ROLLOUT_PERCENT` env flags plus an internal QA allowlist (`server/integrations/kora/rollout.ts`) — actual live percentage lives in Replit env vars, not in-repo.

**Kora staging APIs are deployed on staging** (per operator, 2026-07-12) — separate from the production staged-rollout gating above. Confirm staging-vs-prod Kora credentials are not cross-wired before further staging test runs.

**Blocking items before wider rollout (full detail in `eng.md`):**
1. Charge-verification endpoint status is contradictory in code (`client.ts` treats it as unconfirmed/blocked; `verifier.ts` claims confirmed) — must be resolved, this is the trust boundary for crediting user wallets.
2. 9 CHECK constraints (incl. `withdrawals`, `trades`, `parimutuel_buckets`, `ledger_entries`) reverted from dev after Replit Publish DDL-generator bug — prod currently has zero DB-level guards on withdrawal status values.
3. Kora payout reconciliation job (`server/jobs/kora-payout-reconciliation.ts`) has no `worker_heartbeats` write — silent-failure risk on money-moving code.
4. Compliance/licensing — CAC registration complete under Tabula Digital; Kora KYC/KYB in progress as of 2026-07-12, gates live API keys. `ADR-003`'s Lagos State Lotteries Authority licensing question: decided continue as-is, no separate gaming license (2026-07-12).

Test coverage is solid (16 real test files against Kora mocks), but no confirmed end-to-end run against Kora's actual sandbox.

---

## Key Decisions Made

| Decision | Date | Rationale |
|---|---|---|
| Predicto 1 (Supabase/Vercel) shut down | 2026-04-03 | Kasiro (Replit/Drizzle) is sole codebase per ADR-001 |
| ~~USDT-only MVP (no Naira)~~ SUPERSEDED 2026-07-12 | — | Naira deposits/withdrawals via Kora are live in production, staged rollout. See Naira Payments (Kora) section below. |
| Hybrid engine (AMM + parimutuel) | — | Structural differentiator; no local competitor has this |
| No public founder voice | — | Operator anonymity requirement |
| Niche daily scan retired | 2026-05-07 | Scrape scripts missing from repo |
| Rebranded Predicto → Kasiro | 2026-04-06 | kasiro.app live; brand identity established |
| No separate gaming/lotteries license — continue as-is | 2026-07-12 | CAC-registered as Tabula Digital, tech-services objects clause; Kora KYC/KYB is the compliance gate that matters for payments, not a state gaming license |

---

## Current Open Items State
*(Update after each Product agent session)*

**Last Product session:** [DATE]
**Active sprint focus:** Check `C:\Dev\Kasiro\ACTION_PLAN.md`
**Highest-priority open item:** [UPDATE]
**Items closed this week:** [LIST]
**New items added:** [LIST]
