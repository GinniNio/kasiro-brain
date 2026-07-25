# Market Integrity — doctrine, guards, and admin UI scope

**Created:** 2026-07-25 · **Status:** doctrine ACTIVE; build phased below
**Related:** `SEV1-amm-pricing-replit-prompt.md`, `SEV2-parimutuel-rake-convention.md`, `MIGRATION_HANDOFF.md`

---

## 1. Doctrine — adopt now

> **Prices may move because traders and funded operator accounts transact. Administrative controls may keep markets accurate and operational, but they may not rewrite executed economics.**

Framing for the codebase and for any future agent:

> This framework separates operational market administration from changes that rewrite executed market economics. Ledger-backed transactions may change prices and projected payouts; administrative controls may not alter pool reserves, recorded positions or contractual terms after external capital enters.

**Add to `KASIRO_DOCTRINE.md` as rule 16.**

### Why — the demonstrated fact behind it

`poolsFromPrice()` preserves `R_y + R_n` but **not** `k = R_y · R_n`:

```
reprice 65% → 50%   (pool total held at 100)
  before: yes=35.00 no=65.00   y+n=100   k=2275
  after : yes=50.00 no=50.00   y+n=100   k=2500     → k +9.9%
```

`k` is the liquidity invariant the entire cost function is built on. `adjust-price` therefore **manufactures depth with no funded transaction**, and every existing holder's exit price is recomputed against a curve no trade produced. That is the difference between a trade (transfers value, moves price) and an administrative reserve rewrite (creates or removes value outside the ledger).

The parimutuel equivalent: rebalancing already-committed operator seed changes `W` and `L`, and therefore changes what existing stakers are owed. Worked example — 2 outcomes, 8% rake, seed 5.0, user stakes 100 on A:

```
seed 2.5 / 2.5    → user payout 102.24
seed 4.8 / 0.2    → user payout 100.18    ← profit cut 92%
seed 0.2 / 4.8    → user payout 104.41
```

Principal intact is not the same as the bargain intact.

---

## 2. IMMEDIATE — before cutover

### `adjust-price` is a pre-existing concurrency defect, tracked separately from the governance work

`handleAdminAdjustPrice` (`server/routes/admin-markets.ts:883`) performs an **unlocked** pool-state write — no `BEGIN`, no `FOR UPDATE`. It can overwrite the result of a concurrent trade (classic lost update). This is a defect **today**, independent of any policy question.

**Minimum safe interim (≈10 lines), preserving the useful case:**

```ts
// wrap the whole handler in a transaction
BEGIN;
SELECT * FROM markets WHERE id = $1 FOR UPDATE;   // lock FIRST — see lock order below
// refuse if the market has any trades at all
if (total_trades > 0) return 409 { code: "MARKET_HAS_TRADES" };
// ... existing poolsFromPrice write ...
COMMIT;
```

This keeps the tool available for correcting a mispriced brand-new market — the only case it is actually used for — and removes the lost-update risk. Full disable is the alternative if zero code changes are preferred before cutover.

Restore the broader capability, scoped to pre-external-trade markets, **only after** market-row locking and the protection state below are implemented.

---

## 3. POST-CUTOVER — backend protection state

Deploy schema, production-data backfill, transaction locks and guards **together**, after the hosting cutover. Run reconciliation before restoring any admin financial control.

### 3.1 Irreversible marker

Do **not** derive "external trading has started" from current positions. A full AMM exit deletes the position row (`server/trades/amm-sell.ts:126`, `DELETE FROM positions WHERE id = $1` when `remainingShares <= DUST_THRESHOLD`), so a positions-derived check flips back to `false` and reopens the controls.

Add `markets.external_trading_started_at`. Write it only as:

```sql
UPDATE markets
SET external_trading_started_at = COALESCE(external_trading_started_at, NOW())
WHERE id = $1;
```

**No admin endpoint may accept this field. No ordinary update may clear it.**

Set it on the **first committed non-operator trade** — "committed", not "completed", because the schema has no lifecycle state and needs none: all five `INSERT INTO trades` sites run inside transactions orchestrated by `execute.ts`, so a failed trade rolls back and leaves no row. Trade history is already authoritative.

### 3.2 "Operator" keys off `users.is_operator`, never `PLATFORM_USER_ID`

`PLATFORM_USER_ID` is an **environment variable that changes at cutover**. Guards keyed to it would misclassify every operator position the moment prod data lands in an environment with a different value. `is_operator` is a column on `users` / `wallets` that travels with the data through dump and restore (`server/operator.ts:45`, `server/detectors/rake.ts:52`).

### 3.3 Idempotent backfill — required, or the whole board reads as never-traded

```sql
UPDATE markets m
SET external_trading_started_at =
  CASE
    WHEN m.external_trading_started_at IS NULL THEN sub.first_trade
    ELSE LEAST(m.external_trading_started_at, sub.first_trade)
  END
FROM (
  SELECT t.market_id, MIN(t.created_at) AS first_trade
  FROM trades t
  JOIN users u ON u.id = t.user_id
  WHERE u.is_operator IS NOT TRUE
  GROUP BY t.market_id
) sub
WHERE m.id = sub.market_id;
```

Note: `trades` has **no `status` column** — any filter on `status = 'completed'` will error. Run the backfill against **production** data post-restore (via `db-deploy`), not against the dev clone.

### 3.4 Lock order — already established, do not invert

```
1. market    FOR UPDATE   server/trades/execute.ts:86
2. wallet    FOR UPDATE   server/trades/execute.ts:110
3. position  FOR UPDATE   server/trades/amm-sell.ts:54   (buy takes no position lock)
```

Market is locked **first**, so new guards slot in at position 1 with no reordering. `seedWeights` already conforms. `adjust-price` is the only outlier.

**Constraint: every protected path acquires the market row first, and never acquires wallet or position before it.** Inverting deadlocks against live trades instead of serialising with them — presenting as intermittent hung admin requests under load, and miserable to diagnose.

Applies to: AMM buy, AMM sell, parimutuel stake, `adjust-price`, `seedWeights`, delete, and any reopen workflow. Locking only the admin route leaves the race alive.

```sql
BEGIN;
SELECT external_trading_started_at FROM markets WHERE id = $1 FOR UPDATE;
/* validate, then perform trade or admin action */
COMMIT;
```

### 3.5 Build order

1. Add irreversible `external_trading_started_at`
2. Set it atomically on the first committed non-operator trade, inside the existing trade transaction
3. All financial admin guards read that single field under `FOR UPDATE`
4. Give `adjust-price` a transaction and row lock
5. Block post-trade `adjust-price` / `controls.probability`
6. Freeze post-trade `seedWeights`
7. Cross-store reconciliation test — positions / pools / wallets / ledger
8. Block direct wallet balance writes lacking ledger entries
9. Pre-launch validation gate
10. `closeAt` cannot move into the past; reason code required on post-trade schedule changes

---

## 4. Admin UI — reduced first release

Build **only after** the backend is authoritative. Building UI first forces the frontend to infer protection state from mutable data — the exact bug §3.1 exists to remove.

### Ship

1. Persistent external-trading status banner
2. Locked economic fields with **specific** explanations — never a bare greyed-out input
3. Parimutuel seed weights become read-only once external trading starts
4. `adjust-price` unavailable once external trading starts
5. Pre-launch validation checklist gating **Activate**
6. Stored reconciliation result + timestamp + financial-action blocking
7. **Suspend stays available during reconciliation failure** — it reduces risk, so it must not be gated

### Defer

Admin operator-trading panels · automated Class B clarification workflows · schedule-change publication previews · financial-impact modals for settle/void · full internal audit-history interface · source-authority exception workflows.

The endpoints for settle, void, suspend and clone already exist, so deferring costs ergonomics, not capability.

### Data-source corrections carried into the UI spec

- **"First external trade"** reads from `external_trading_started_at`. Never inferred from current positions or volume.
- **"External traders"** comes from a distinct historical count where `users.is_operator IS NOT TRUE`. `unique_trader_count` has **not** been confirmed to exclude operator stakes — verify the query before exposing the number, or the header lies in exactly the place it exists to be truthful.
- **Reconciliation is a stored result, not a live query.** A four-store check on every admin page render will not scale. Display:

  ```
  Reconciliation passed
  Last checked: 25 Jul 2026, 14:30 WAT
  ```

  Show staleness explicitly. "Passed" must never imply a live query.

### Two things that cannot be automated

- **"Outcome is not materially known"** (resume gate) is a judgment call, not a check. Make it an explicit operator attestation with a recorded reason, or it becomes a control that looks objective and isn't.
- **Class B "clarification that cannot alter any plausible outcome"** — same problem. Keep as documented policy; enforce only the cosmetic allowlist in code, and route substantive errors to **void and relist**.

### Prerequisite

**Fix the price formatters first.** Two confirmed bugs (`₦65` rendered for a ₦890 share price; `$100.00` for a ₦100 minimum) while amount formatters are correct. The UI above adds six new price surfaces — indicative payout, implied probability, estimated multipliers, average execution price, estimated payout after stake, price impact. Building them on broken formatters propagates the defect into the tools used to diagnose it.

---

## 5. Sequence

1. Land doctrine (rule 16) — now
2. Disable / lock `adjust-price` — **now, before cutover**
3. Complete hosting cutover
4. Deploy schema + prod backfill + locks + guards together
5. Run reconciliation
6. Restore admin financial controls
7. Build reduced admin UI
