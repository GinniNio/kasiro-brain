# Kasiro Engineering Intelligence
**Domain owner:** Engineering agent | **Last updated:** 2026-07-03

---

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js (Replit) |
| Backend | Express.js + TypeScript |
| Frontend | React + Vite + TypeScript |
| ORM | Drizzle ORM |
| Database | PostgreSQL (Replit managed) |
| Deposit rail | TRC-20 USDT on Tron (TronGrid API) |
| Deployment | Replit (primary) |
| Session / auth | Express sessions |
| Schema migrations | Drizzle Kit (`npm run db:push`) |

**Canonical source of truth for engineering:** `C:\Dev\Kasiro\replit.md` — read this before any engineering session.

---

## AMM Rules (non-negotiable)

**The single most dangerous class of bug in Kasiro is inline pool math.**

The 2026-05-03 Oyebanji market incident was caused by copy-paste of AMM math that diverged from the canonical helper. This took down an active market.

### Rule: All AMM writes must use helpers from `server/amm.ts`

```typescript
// ALWAYS — call the helper
import { poolsAfterBuy, poolsAfterSell } from './amm';
const { yesPool, noPool } = poolsAfterBuy(currentYesPool, currentNoPool, amount, 'YES');

// NEVER — inline the constant-product math
const k = yesPool * noPool;
const newNoPool = k / (yesPool + amount); // FORBIDDEN
```

**Why:** The helper is the source of truth. Inline math diverges silently. Divergence = incorrect prices = unhappy traders = voided markets.

### AMM constants
- `feeBps: 200` — 2% on every trade
- Constant-product invariant: `yes_pool * no_pool = k`
- Opening price set by operator in 0.0–1.0 range (this is `openPrice`)
- Seeding done by `operatorSeedMarket` — DO NOT bypass with SQL-direct activation

### AMM activation rule
SQL-direct activation (`UPDATE markets SET status='open'`) bypasses `operatorSeedMarket`. For AMM markets this leaves pools notional with no operator capital. Always use the admin dialog or call `operatorSeedMarket` programmatically.

### Pool re-pin after seeding
After `operatorSeedMarket`, 3 of 4 call sites re-pin pools. The unmasked vector was draft→open PATCH. Re-pin is now added. Never remove the re-pin step.

---

## Parimutuel Rules

- `feeBps: 800` — 8% rake (low vs 15–25% industry norm)
- Seed weights per outcome must sum to exactly 100
- Pool closes at `closeAt`; no new trades after lock
- Participants share the final pool proportionally (minus rake)
- Seeding skips `operatorSeedMarket` entirely — DO NOT add AMM seeding to parimutuel activation path

### Branching rule
Market mechanics type must always gate the activation path:

```typescript
if (market.mechanicsType === 'amm') {
  // seed pools via operatorSeedMarket
} else if (market.mechanicsType === 'parimutuel') {
  // no seeding — just open
}
```

**Never collapse this branch.** The 2026-05-03 bug was partly caused by a collapsed activation path.

---

## Database Guardrails

### Raw SQL snake/camel drift
Three incidents in 2026-05-30 from this exact bug:
- Raw SQL uses `snake_case` column names
- Drizzle schema uses `camelCase`
- When you do `select *` or omit columns from `explicit-select()`, the mapping silently drops or misnames fields

**Rule:** Always use Drizzle's `explicit-select()` — never `select *` in raw SQL or Drizzle queries. List every column you need. Undefined fields silently break the client.

### Auto-lock must demote promo_status
When a market transitions `open → locked`, the auto-lock job must atomically clear `feature` and `featured_rank`.

**Why:** Locked markets with feature badges leak into the ⭐ Featured rail. This happened with the 2026-05-30 Rabat incident — a locked market appeared featured for hours.

```typescript
// Required in auto-lock transition:
await db.update(markets)
  .set({ status: 'locked', feature: null, featured_rank: null })
  .where(eq(markets.id, marketId));
```

### operatorSeedMarket self-healing
3 of 4 call sites re-pin pools after seeding, masking potential pool state bugs. Draft→open PATCH was the unmasked vector. Keep the re-pin. Do not optimise it away.

---

## Market Gates (v0.1, shipped 2026-05-22)

Two activation gates block poorly formed markets from going live:

| Gate | What it checks | Blocks on |
|---|---|---|
| `clarity_lint` | Market question is well-formed, unambiguous, has clear resolution | Vague questions, missing resolution criteria |
| `source_check` | At least one public URL provided that will definitively resolve the claim | Missing or unreachable source URL |
| `risk_compliance` | Banned market types, manipulation risk, settlement stability | Any banned category match |

**Pattern:** `risk_compliance` uses a saga/compensating-action pattern — it rolls back if any risk check fails. Do not break the saga flow.

**Outstanding:** 5 scenario tests pending; activation-rollback is the highest-leverage test.

---

## Key Files (Kasiro repo)

| File | What it is |
|---|---|
| `C:\Dev\Kasiro\replit.md` | Master AI session context — read first for all engineering |
| `C:\Dev\Kasiro\server\amm.ts` | AMM helpers — source of truth for all pool math |
| `C:\Dev\Kasiro\MANUAL_DATABASE.md` | All 30+ tables with schema and field descriptions |
| `C:\Dev\Kasiro\ACTION_PLAN.md` | Running open items list |
| `C:\Dev\Kasiro\docs\ADR-001` through `ADR-009` | Architecture decision records |
| `C:\Dev\Kasiro\OPERATIONS_MANUAL.md` | Day-to-day operations |
| `C:\Dev\Kasiro\WORKING_PRINCIPLES.md` | 3 operating gates: Convention-by-Enforcement, Done Means Done, One Pillar One Week |

---

## Deployment

**Platform:** Replit (primary). All implementation work goes via Replit agent or direct Replit file edits.

**Rule for Engineering agent:** Output must be Replit-ready. Default output format is a Replit agent prompt — a clear, precise instruction that can be pasted directly into the Replit agent chat. Not a pull request. Not a GitHub action. A Replit prompt.

**Local environment:** Claude Code CLI available at `C:\Dev\Kasiro` for code reading, auditing, and spec work. Not for direct file writing in production.

**Schema changes:** Always use `npm run db:push` (Drizzle Kit). Never write raw `ALTER TABLE` in production.

---

## Engineering Guardrail Summary

| Guardrail | Rule |
|---|---|
| AMM math | Never inline — always use `poolsAfterBuy`/`poolsAfterSell` from `amm.ts` |
| Activation branching | Always gate on `mechanicsType` — AMM and parimutuel are different paths |
| AMM seeding | Use admin dialog or `operatorSeedMarket` — never SQL-direct activation |
| Pool re-pin | Always re-pin after seed — never remove |
| Auto-lock | Must atomically clear `feature`/`featured_rank` |
| Drizzle selects | Always `explicit-select()` — never `select *` |
| Schema drift | Use `db:push` not raw SQL DDL |
| Market gates | Never remove or bypass `clarity_lint`, `source_check`, `risk_compliance` |

---

## Open Engineering Items
*(Update after each Engineering agent session)*

**Last Engineering session:** [DATE]
**Current focus:** Check `C:\Dev\Kasiro\ACTION_PLAN.md`
**Outstanding P0 items:** [UPDATE]
**Recent incidents:** [UPDATE]
