# Market Integrity — doctrine, guards, and admin UI scope

**Created:** 2026-07-25 · **Revision 2** · **Status:** doctrine ACTIVE (rule 16); build phased below
**Related:** `SEV1-amm-pricing-replit-prompt.md`, `SEV2-parimutuel-rake-convention.md`, `MIGRATION_HANDOFF.md`

---

## 0. Terminology — precise, because the guards depend on it

Three facts were previously conflated. They are not the same:

| Phrase | Knowable? |
|---|---|
| "non-operator trade" | **Yes** — `users.is_operator IS NOT TRUE` |
| "external user" | Partially |
| "external capital" | **No** — a user may trade promotional or operator-funded credit |

**Canonical definition, used in every technical rule:**

> **Protected state begins when the first committed trade by a non-operator account occurs.**

"External trading" remains acceptable as a **UI label only**. All code, guards, SQL and tests use *non-operator trade*.

---

## 1. Doctrine — ACTIVE as rule 16

> **Prices may move because traders and funded operator accounts transact. Administrative controls may keep markets accurate and operational, but they may not rewrite executed economics.**

Expanded framing:

> This framework separates operational market administration from changes that rewrite executed market economics. Ledger-backed transactions may change prices and projected payouts; administrative controls may not alter pool reserves, recorded positions or contractual terms after a non-operator trade commits.

### The demonstrated fact behind it

`poolsFromPrice()` preserves `R_y + R_n` but **not** `k = R_y · R_n`:

```
reprice 65% → 50%   (pool total held at 100)
  before: yes=35.00 no=65.00   y+n=100   k=2275
  after : yes=50.00 no=50.00   y+n=100   k=2500     → k +9.9%
```

`k` is the liquidity invariant the cost function is built on. `adjust-price` therefore **manufactures depth with no funded transaction**, and every holder's exit price is recomputed against a curve no trade produced.

Parimutuel equivalent — rebalancing committed operator seed changes `W` and `L`, so it changes what existing stakers are owed. 2 outcomes, 8% rake, seed 5.0, user stakes 100 on A:

```
seed 2.5 / 2.5    → user payout 102.24
seed 4.8 / 0.2    → user payout 100.18    ← profit cut 92%
seed 0.2 / 4.8    → user payout 104.41
```

Principal intact ≠ bargain intact.

---

## 2. IMMEDIATE — before cutover

### `adjust-price` is a pre-existing concurrency defect, tracked separately from governance

`handleAdminAdjustPrice` (`server/routes/admin-markets.ts:883`) performs an **unlocked** pool-state write — no `BEGIN`, no `FOR UPDATE`. It can overwrite a concurrent trade's result (lost update). A defect **today**, independent of policy.

**Interim control — acceptance criteria, not pseudocode:**

- Market row is locked (`SELECT … FOR UPDATE`) **before** the trade-count query.
- The trade-count query and the reserve update use the **same transaction client**.
- The reserve update makes **no** separate storage call outside the transaction.
- **Every early return rolls back.**
- `409 MARKET_HAS_TRADES` produces **no** market, pool or ledger mutation.
- Two concurrent reprice requests: exactly one commits.
- A concurrent trade either commits first and blocks the reprice, or the reprice commits first and the trade reads post-reprice state. No interleaving.
- **"Any trades" includes operator trades** for this interim control. The objective is eliminating lost updates with minimum logic, not expressing final policy.

Full disable is the alternative if zero code before cutover is preferred. Restore the broader capability — scoped to pre-non-operator-trade markets — only after §3 ships.

---

## 3. POST-CUTOVER — protection state

Deploy schema, production backfill, row locks and guards as **one release**. Reconcile before restoring any admin financial control.

### 3.1 Irreversible marker

Do **not** derive protection from current positions: a full AMM exit deletes the row (`server/trades/amm-sell.ts:126`, `DELETE FROM positions … WHEN remainingShares <= DUST_THRESHOLD`), so a positions-derived check flips back to `false`.

Add `markets.external_trading_started_at`. Written only as:

```sql
UPDATE markets
SET external_trading_started_at = COALESCE(external_trading_started_at, NOW())
WHERE id = $1;
```

Set on the **first committed non-operator trade**. "Committed", not "completed": all five `INSERT INTO trades` sites run inside transactions orchestrated by `execute.ts`, so a failed trade rolls back and leaves no row. `trades` has **no `status` column** — any `status = 'completed'` filter will error.

**Irreversibility must be enforced by the database, not convention.** A generic storage update, migration or future endpoint could otherwise clear it:

```sql
CREATE OR REPLACE FUNCTION prevent_external_trading_marker_reset()
RETURNS trigger AS $$
BEGIN
  IF OLD.external_trading_started_at IS NOT NULL
     AND (
       NEW.external_trading_started_at IS NULL
       OR NEW.external_trading_started_at > OLD.external_trading_started_at
     )
  THEN
    RAISE EXCEPTION 'external_trading_started_at is irreversible';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

May be preserved, or moved **earlier** during an audited corrective backfill. May never be cleared or moved later. No admin endpoint accepts this field.

### 3.2 Actor classification — `users.is_operator`, with known limits

Key off `users.is_operator`, **never** `PLATFORM_USER_ID` — that is an environment variable which **changes at cutover**, so guards keyed to it misclassify every operator position once prod data lands in a new environment.

**But `is_operator` is mutable historical data.** The backfill classifies old trades by the flag's *current* value; adding, removing or correcting a flag later reclassifies history. Required controls:

- `is_operator` must not be casually editable — treat as privileged.
- Before running the backfill, **enumerate and verify every operator account**.
- The backfill must report: affected market count, earliest timestamp set, and any unmatched users, for review before commit.
- **Longer term:** store actor classification on the trade row or in immutable audit history, so classification is fixed at execution time.

### 3.3 Idempotent backfill — required, or the whole board reads as unprotected

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

`LEAST` only moves the marker earlier, so it satisfies the trigger. Run against **production** data post-restore (via `db-deploy`), never the dev clone.

### 3.4 Lock order — established; do not invert

```
1. market    FOR UPDATE   server/trades/execute.ts:86
2. wallet    FOR UPDATE   server/trades/execute.ts:110
3. position  FOR UPDATE   server/trades/amm-sell.ts:54   (buy takes no position lock)
```

Market locks **first**, so new guards slot in at position 1. `seedWeights` already conforms; `adjust-price` is the only outlier.

**Every protected path acquires the market row first, and never acquires wallet or position before it.** Inverting deadlocks against live trades rather than serialising — presenting as intermittent hung admin requests under load.

Applies to: AMM buy, AMM sell, parimutuel stake, `adjust-price`, `seedWeights`, delete, reopen.

```sql
BEGIN;
SELECT external_trading_started_at FROM markets WHERE id = $1 FOR UPDATE;
/* validate, then perform trade or admin action */
COMMIT;
```

### 3.5 Reconciliation — define what "passed" means

A named test is not a definition. Passing requires **all** of:

1. Every trade has its expected wallet and ledger movements.
2. Current positions reproduce from trade history.
3. Market pools reproduce from applicable trades plus approved seed state.
4. Wallet balance equals the ledger-derived balance.
5. Refund and settlement liabilities are fully covered.
6. No pool-changing admin action exists outside recognised audited operations.

```ts
interface ReconciliationResult {
  status: "passed" | "warning" | "failed";
  checkedAt: Date;
  marketStateVersion: string;      // e.g. last trade id included
  failures: ReconciliationFailure[];
}
```

`marketStateVersion` is required because a result goes stale the instant another trade commits. The UI must say **"Passed against market state through trade #1842"** — a timestamp alone cannot show what was checked.

### 3.6 Fail-closed deployment and rollback

- Financial admin controls stay **disabled** until schema, backfill and guard verification all pass.
- If the backfill fails or returns unexpected counts, **deployment stops**.
- Application versions that do not understand `external_trading_started_at` **must not run** after the migration.
- Rollback may revert application code only to a version that preserves the marker and guards.
- **Reconciliation failure** blocks reprice, seed changes, settlement execution, void execution and wallet adjustments. **Suspend stays available** — it reduces risk.
- **Settlement and void need a controlled recovery path.** Blocking them permanently on a failed reconciliation could trap user funds. Failed reconciliation blocks *immediate execution* while allowing preview, diagnosis and a documented repair route.

### 3.7 Build order

1. Add irreversible `external_trading_started_at` + trigger
2. Set atomically on first committed non-operator trade, inside the existing trade transaction
3. All financial admin guards read that single field under `FOR UPDATE`
4. Give `adjust-price` a transaction and row lock
5. Block post-protection `adjust-price` / `controls.probability`
6. Freeze post-protection `seedWeights`
7. Reconciliation per §3.5
8. Block direct wallet balance writes lacking ledger entries
9. Pre-launch validation gate
10. `closeAt` cannot move into the past; reason code on post-protection schedule changes

---

## 4. Acceptance tests — every safety claim becomes executable

| Scenario | Expected |
|---|---|
| Brand-new AMM, no trades | Reprice permitted |
| AMM, operator trade only | Interim: blocked (any trades). Final: permitted — marker is set only by non-operator trades |
| AMM after non-operator buy | Reprice permanently blocked |
| User buys then fully sells (position row deleted) | Protection remains active |
| Parimutuel, operator seed only | Seed weights editable |
| Parimutuel after non-operator stake | Seed weights permanently frozen |
| `PLATFORM_USER_ID` env value changes | Protection state unchanged |
| DB dump + restore into new environment | Protection state and `is_operator` both preserved |
| `is_operator` flag changed after a historical trade | Marker unchanged |
| First non-operator trade races admin reprice | Exactly one state transition wins; no lost update |
| Reprice fails after acquiring lock | Transaction rolls back fully; no partial write |
| Backfill runs twice | Identical result |
| Admin attempts to clear marker | Database rejects (trigger) |
| Admin attempts to move marker later | Database rejects (trigger) |
| Corrective backfill moves marker earlier | Permitted |
| Reconciliation fails | Financial actions blocked; Suspend available; settle/void offer preview + repair route |
| Close time set in the past | Rejected |
| Cosmetic edit after protection | Allowed and logged |
| Criteria or outcome edit after protection | Blocked; void-and-relist route shown |

---

## 5. Admin UI — reduced first release

Build **only after** the backend is authoritative. UI first would force the frontend to infer protection from mutable data — the exact defect §3.1 removes.

### Ship

1. Persistent protection-state banner
2. Locked economic fields with **specific** explanations — never a bare greyed-out input
3. Parimutuel seed weights read-only once protected
4. `adjust-price` unavailable once protected
5. Pre-launch validation checklist gating **Activate**
6. Stored reconciliation result + `marketStateVersion` + financial-action blocking
7. **Suspend stays available during reconciliation failure**

### Defer

Admin operator-trading panels (use: log in as the operator account and trade normally — no impersonation endpoint) · automated Class B clarification workflows · schedule-change publication previews · settle/void financial-impact modals · full audit-history interface · source-authority exception workflows.

Settle, void, suspend and clone endpoints already exist — deferring costs ergonomics, not capability.

### Data-source rules

- **"First external trade"** reads `external_trading_started_at`. Never inferred from positions or volume.
- **"External traders"** = distinct historical count where `users.is_operator IS NOT TRUE`. `unique_trader_count` is **not confirmed** to exclude operator stakes — verify before exposing, or the header lies where it exists to be truthful.
- **Reconciliation is a stored result**, never a live four-store query on render. Show status, `checkedAt`, and `marketStateVersion`; show staleness explicitly.

### Cannot be automated — attestation, not check

- **"Outcome is not materially known"** (resume gate) — operator attestation with recorded reason.
- **Class B "clarification that cannot alter any plausible outcome"** — documented policy; enforce only the cosmetic allowlist in code; route substantive errors to void-and-relist.

### Prerequisite

**Fix the price formatters first.** Two confirmed defects (`₦65` for a ₦890 share price; `$100.00` for a ₦100 minimum) while amount formatters are correct. This UI adds six new price surfaces; building them on broken formatters propagates the defect into the tools used to diagnose it.

---

## 6. Sequence

1. Doctrine (rule 16) — **done**
2. Lock or disable `adjust-price` — **before cutover**
3. Complete hosting cutover
4. Deploy marker + trigger + prod backfill + row locks + guards as one release
5. Reconcile and verify
6. Restore admin financial controls
7. Build reduced admin UI
