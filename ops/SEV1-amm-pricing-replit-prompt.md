# SEV1 — Inverted AMM pricing + round-trip arbitrage

**Status: RESOLVED — verified live on production 2026-07-25** · **Found:** 2026-07-25 · **Scope:** AMM binary markets only (parimutuel tracked in `SEV2-parimutuel-rake-convention.md`)

## RESOLUTION — verified against `POST /api/markets/:id/quote` on kasiro.app

Fixed in two passes. Pass 1 (`c00f743`): `amm.ts` quadratics + `amm-buy.ts` / `amm-sell.ts` switched to the helpers. Pass 2 (`16137bc`): the four call sites pass 1 missed — `routes/markets.ts` quote handler (sell formula, pool updates, liquidity bound), `bot/execute-trade.ts` `sharesFromCost`, and the client Max button in `market.tsx`.

Live verification on the Davido market (pools 34.037/63.212, quoted YES 0.65):

```
                pricePerShare      price after        direction
BUY  YES 0.001   0.6500023   →  yesPrice 0.6500047    ✓ rises
SELL YES 0.001   0.6499977   →  yesPrice 0.6499953    ✓ falls
BUY  NO  0.001   0.3500023   →  noPrice  0.3500047    ✓ rises
SELL NO  0.001   0.3499977   →  noPrice  0.3499953    ✓ falls
```

- **Marginal cost equals quoted price** on both sides (was 0.5385 buy / 1.8571 sell).
- **Round trip closed:** buy 0.00065000 vs sell 0.00064999 before fees. Was +235% per round trip.
- **Price impact correct:** 5-share buy quotes 0.6615/share vs 0.65 spot — larger orders now cost more, not less. Independently checked against the quadratic: `c = (98.86379 − 92.248717)/2 = 3.30754` vs API `3.3075621`. Exact.
- **Quote/execution divergence impossible by construction:** `handleQuote` and the trade path both call `poolsAfterBuy`/`poolsAfterSell`. One implementation, not two that agree by coincidence.

### Deployment lesson worth keeping

After pass 2, Render (auto-deploys from GitHub `main`) was correct while kasiro.app still served the old build — Replit needs a **manual republish**. That left production in the worst intermediate state: `amm.ts` fixed so execution priced correctly, but the quote handler old, so every web sell hard-failed on the `minProceeds` slippage guard. **Two hosts, two deploy mechanisms — verify both, always.**

### Still unverified

The client **Max button** (`market.tsx:254,304`) ships in the JS bundle and cannot be checked by API probe. Click Max on a live market and confirm the filled share count is affordable.

---

**Original report follows.**

**Scope:** AMM binary markets only (parimutuel unaffected)

**Severity downgraded SEV0 → SEV1 on 2026-07-25.** Operator confirmed **no real users and no real trades**. The 18 users, 335 trades and $11,060.22 balance visible in the database are the operator's own test activity. No user has been financially harmed, so no refund, clawback or reconciliation work is required.

**Residual risk (why this is still SEV1, not SEV3):** kasiro.app is publicly reachable with open signup and grants ₦6,835 demo credit. Demo accounts cannot withdraw (`server/routes/account.ts:169`, `server/routes/withdrawals-ngn.ts:87`), but `is_demo` clears on first real deposit (`trongrid.ts:294`, `tatum.ts:301`, `ngn-payments.ts:770`) **and the demo credit is not clawed back when it flips**. A stranger could therefore deposit a token amount, unlock withdrawals, run the round-trip pump to inflate their balance, and withdraw — bounded only by the real USDT the platform holds. Kora NGN deposits (live at 45% rollout) are a second on-ramp.

**Fix before any user-acquisition push, and ideally before the Render cutover.** The cost of this defect rises sharply the moment real users arrive, because at that point it does generate refund and reconciliation obligations.

---

## 0. Containment — conditional

No emergency circuit breaker is required while traffic is zero.

**If any marketing or user-acquisition is running,** pause the AMM branch until the fix lands. The correct guard is inside `server/trades/execute.ts`, after the market row loads and before the AMM branches at lines 170 (sell) and 203 (buy):

```ts
if (market.mechanics_type === "amm") {
  throw new TradeError(
    "amm_paused",
    "AMM trading is temporarily paused for maintenance.",
    503
  );
}
```

Do **not** stub `/api/trades/amm/buy` or `/api/trades/amm/sell` — **those routes do not exist**. All trading flows through a single endpoint, `POST /api/trades/execute` (`server/routes.ts:301`), which dispatches on `mechanics_type` (parimutuel at `execute.ts:120`). Registering handlers for the non-existent paths deploys green and pauses nothing — false containment, worse than none.

Do **not** freeze withdrawals. The value pump is in the trading path; freezing withdrawals does not stop it and penalises users for a platform defect.

Blocking `/api/trades/execute` wholesale would also stop parimutuel trading, which is unaffected and should stay open.

---

## 1. The defect

`server/amm.ts` contains two mutually inconsistent AMM models.

**Price function (correct)** — complete-sets convention, reserves are outcome-token inventories:

```
yesPrice = noPool / (yesPool + noPool)
```

`poolsFromPrice` agrees: seed 0.65 → `yesPool=35, noPool=65` → price 0.65 ✓

**Cost function (wrong)** — a plain 2-token DEX swap:

```
cost = (pool1 × shares) / (pool2 − shares)
```

Its marginal price is `yesPool/noPool` = `(1−p)/p` — the **odds ratio**, not the probability `p`.
`calculateSellProceeds` has the mirrored defect: marginal `noPool/yesPool` = `p/(1−p)`.

The two errors point in opposite directions, producing a money pump. Simulated on live pools (`34.037/63.212`, quoted 0.65):

```
BUY  0.3658 YES → pay      0.19812 USDT  (marginal 0.5385)
SELL 0.3658 YES → receive  0.66440 USDT  (marginal 1.8571 — exceeds max payout of 1.0)
                            ─────────
RISK-FREE PROFIT  +0.46629 USDT (+235%), instant, no price movement
```

`k` is preserved at every step, so all invariant tests pass. There is no cooldown or hold period; `minProceeds` is a user-supplied slippage guard, not a safety limit.

**Verified against the live production UI:**

| Market | Quoted | Correct cost | Actually quoted |
|---|---|---|---|
| Davido YES 65%, ₦500 return | 0.65 | ₦325 | **₦271** |
| Chebbak YES 24%, ₦100 return | 0.24 | ₦24 | **₦318** |

Favourites are sold at a discount; underdogs at a multiple of true price. The Chebbak panel displays *"Cost exceeds max payout — reduce stake"* — but the ratio is constant in size (3.175 at s=0.05, 3.179 at s=0.073), so no stake makes it viable and the guidance is wrong.

---

## 2. ⚠️ CRITICAL — where the live math actually lives

Production **does not** route through the helpers. Patching `server/amm.ts` alone **makes production worse**:

| File | Cost formula | Pool update |
|---|---|---|
| `server/trades/amm-buy.ts` | calls `calculateBuyCost` (L97, L101) | **INLINED** (L98–99, L102–103) |
| `server/trades/amm-sell.ts` | **INLINED** (L78, L82) | **INLINED** (L80, L84) |

- Patching `calculateBuyCost` alone → new quadratic cost driving the **old** inlined update rule → **the constant-product invariant breaks outright** and pools drift arbitrarily.
- Patching `calculateSellProceeds` alone → **no effect on production**; `amm-sell.ts` never calls it. The 235% sell leg survives untouched.

The only current consumers of all four helpers are `tests/amm.test.ts`.

> The file is `server/trades/amm-sell.ts`. There is no `server/routes/amm-sell.ts`.

---

## 3. Correct mathematics

Complete-sets constant product. Buying `s` shares for cost `c` mints `c` complete sets; the trader takes `s`, the remainder enters the pools.

```
BUY   (Ry + c − s)(Rn + c) = Ry·Rn
      c² + c(Ry + Rn − s) − s·Rn = 0
      c = [ −(Ry+Rn−s) + √((Ry+Rn−s)² + 4·s·Rn) ] / 2
      Ry' = Ry + c − s      Rn' = Rn + c

SELL  (Ry − w + s)(Rn − w) = Ry·Rn
      w² − w(Ry + Rn + s) + s·Rn = 0
      w = [ (Ry+Rn+s) − √((Ry+Rn+s)² − 4·s·Rn) ] / 2
      Ry' = Ry − w + s      Rn' = Rn − w
```

For BUY/SELL NO, swap: `Ry = noPool`, `Rn = yesPool`.

Verified on live pools: buy `c = 0.2381` vs `0.65 × 0.3658 = 0.2378` ✓ (marginal cost equals quoted price, as required). Sell `w = 0.2375`, marginally below buy — the correct spread direction.

Discriminants are always non-negative: buy is `b² + 4sRn > 0`; sell is `(Ry+Rn+s)² ≥ 4s(Ry+Rn) ≥ 4s·Rn` by AM–GM. Throw on a negative discriminant rather than `Math.max(0, …)`, which would silently mask a `NaN`.

---

## 4. REPLIT PROMPT

```
SEV1: Inverted AMM pricing and round-trip arbitrage on asymmetric pools.

CONTEXT
server/amm.ts mixes two AMM models. calculateYesPrice/poolsFromPrice use the
complete-sets convention (price = noPool/(yesPool+noPool)). calculateBuyCost and
calculateSellProceeds implement a plain DEX swap whose marginal price is the odds
ratio (1-p)/p, not p. Result: buying YES at a quoted 65% costs 0.5385/share, selling
returns 1.8571/share. An instant buy->sell round trip yields +235% risk-free. The
constant-product invariant k is preserved throughout, so every existing test passes.

There are no real users and no real trades. Do not write migration or refund logic.

CONFIRM APPROACH AND LIST FILES BEFORE WRITING CODE.

TASKS

1. server/amm.ts — replace calculateBuyCost and calculateSellProceeds with the
   complete-sets quadratics:
     BUY:  c = [-(Ry+Rn-s) + sqrt((Ry+Rn-s)^2 + 4*s*Rn)] / 2
     SELL: w = [ (Ry+Rn+s) - sqrt((Ry+Rn+s)^2 - 4*s*Rn)] / 2
   where Ry/Rn = yesPool/noPool for YES, swapped for NO.
   Throw a RangeError on a negative discriminant. Do not silently clamp to 0.

2. server/amm.ts — update poolsAfterBuy / poolsAfterSell to the matching state updates:
     BUY YES:  yesPool + cost - shares,     noPool + cost
     BUY NO:   yesPool + cost,              noPool + cost - shares
     SELL YES: yesPool - proceeds + shares, noPool - proceeds
     SELL NO:  yesPool - proceeds,          noPool - proceeds + shares
   Assert k is preserved to 6dp inside the helpers in non-production builds.

3. server/trades/amm-buy.ts — DELETE the inlined pool arithmetic at lines 97-103.
   Replace the entire block with a single poolsAfterBuy call. This is REQUIRED:
   leaving the inlined updates with the new cost formula breaks the invariant.

4. server/trades/amm-sell.ts — DELETE the inlined proceeds and pool arithmetic at
   lines 78-84. Replace with a single poolsAfterSell call. This file currently
   never calls the helper at all, so it is the live arbitrage surface.

5. server/trades/amm-buy.ts lines 55-62 — the MAX_LIQUIDITY_USAGE guard tests
   `shares >= noPool * MAX` for a YES buy. That bound belongs to the old model.
   Re-derive it for the complete-sets model and state the new bound in a comment.

6. tests/amm.test.ts — the suite encodes the bug. Fix it:
   a) DELETE "buying YES moves YES price down" (L194) and "buying NO moves NO price
      down" (L201). Replace with assertions that buying an outcome RAISES that
      outcome's price.
   b) Every behavioural test uses balanced pools (100,100) — the one configuration
      where buy marginal (y/n) and sell marginal (n/y) are both 1.0 and the bug is
      invisible. Re-point them at asymmetric pools.

ACCEPTANCE TESTS (all must pass, all on ASYMMETRIC pools)

  A1  For pools (35,65),(76,24),(10,90): marginal buy cost for s=0.001 equals
      calculateYesPrice within 1e-4. This is the assertion that would have caught
      the bug on day one.
  A2  Buying YES strictly increases calculateYesPrice. Buying NO strictly increases
      calculateNoPrice.
  A3  Round trip on (34.037, 63.212), s=0.3658: sell proceeds < buy cost, before fees.
  A4  Sell proceeds per share <= 1.0 for every outcome and every pool ratio tested.
  A5  k preserved to 6dp after buy, after sell, and across a buy->sell round trip.
  A6  Regression, exact values: pools (34.037051, 63.211666), s=0.3658, BUY YES
      -> cost 0.2381 +/- 0.0005 (was 0.19812).
      Pools (60.871346, 19.22253), s=0.07315, BUY YES -> cost 0.01756 +/- 0.0005
      (was 0.23269).
  A7  Property test, 1000 random asymmetric pool pairs: buy-then-sell of identical
      share counts never returns more than it cost.

DO NOT
  - Do not change calculateYesPrice, calculateNoPrice or poolsFromPrice. They are correct.
  - Do not touch parimutuel code paths.
  - Do not write to production.
```

---

## 5. Historical audit — NOT APPLICABLE

**Skipped: no real users, no real trades.** The 335 trades are operator test activity.

Retained only as method, should it ever be needed. The bug is exactly invertible from stored data: buggy marginal = `(1−p)/p`, therefore `p = 1 / (1 + price_per_share)`. Verified: Davido `0.5385 → p=0.65` ✓, Chebbak `3.175 → p=0.2395` ✓. No state replay required.

```sql
SELECT t.id, t.user_id, t.market_id, t.side, t.outcome, t.shares,
       t.price_per_share                            AS charged_per_share,
       1.0 / (1.0 + t.price_per_share)              AS implied_true_prob,
       t.total_cost                                 AS actually_paid,
       t.shares * (1.0 / (1.0 + t.price_per_share)) AS should_have_paid,
       t.total_cost - t.shares * (1.0/(1.0 + t.price_per_share)) AS delta_usdt
FROM trades t
WHERE t.side = 'buy'
ORDER BY abs(t.total_cost - t.shares * (1.0/(1.0 + t.price_per_share))) DESC;
```

> Note for any future version of this query: `trades` columns are `side`, `outcome`, `shares`, `price_per_share`, `fee_amount`, `total_cost`. There is no `is_yes`, `cost_usdt` or `type`. There is **no pool snapshot on `trades`**, so joining `markets` yields *current* reserves, not execution-time reserves — any query doing that is invalid.

---

## 6. Refunds and remediation — NOT APPLICABLE

**Skipped: nobody was harmed.** No refunds, no clawbacks, no balance adjustments, no reconciliation.

Recorded for the future, because this becomes mandatory the moment real users trade:

- Refunds must be **ledger-backed**. Reconciliation derives balances as a sum over `ledger_entries` (rewritten during the Kora NGN work). A direct `available_balance` write with no matching ledger row desynchronises the two permanently. Correct pattern is the demo-credit block in `server/routes/auth.ts`: one transaction, `UPDATE wallets` **plus** `INSERT ledger_entries` with a `reason_code` and an idempotency key derived from the trade id.
- Policy, if ever needed: refund the overcharged, absorb the undercharged, review round-trip extractors case by case. Settlement math is unchanged either way ($1.00 per winning share).

---

## 7. Post-fix — clean re-seed

With no real positions to preserve, skip pool reconciliation entirely and reset to a known-good state.

1. Wipe test trades and positions on AMM markets.
2. Re-seed every open AMM market's pools from `poolsFromPrice(open_price, seedTotal)`.
3. Re-run the two live checks that caught this:
   - Davido 65% market → ~₦325 for a ₦500 return
   - Chebbak 24% market → ~₦24 for a ₦100 return
4. Confirm CI is green on `main` — outstanding since the 07-19 push (6 failing tests, fix dispatched, never reconfirmed).

---

## 8. How this shipped — process note

Worth recording, because the mechanism will recur.

1. **A test canonised the bug.** `tests/amm.test.ts:194` asserts *"buying YES moves YES price down"*. Someone observed the inverted behaviour and wrote a passing test around it rather than questioning it.
2. **Every behavioural test used balanced pools (100,100)** — lines 195, 202, 241, 256, 265. At `yesPool == noPool` the buy marginal (`y/n`) and sell marginal (`n/y`) are both exactly 1.0, so the arbitrage vanishes. The suite tested the single configuration in which the defect is invisible.
3. **The tested invariant (`k` preserved) is necessary but not sufficient.** The broken code preserves `k` perfectly. The missing assertion ties the two halves of the model together: **marginal cost must equal quoted price** (A1 above).

Lesson for future numeric work: test asymmetric inputs by default, and assert relationships *between* subsystems, not just invariants within one.

---

## 9. Also found during the same session

Unrelated to the AMM defect, logged so they aren't lost:

- **Trade panel currency mixing (USDT mode).** "Min stake: $100.00" renders the Naira figure (100) with a `$` prefix instead of converting — a 1,367× error on a money-facing label. Quick-stake buttons stay in ₦ while the panel is in USDT. "Available: $5.00 ($5.00 USDT)" is duplicated. Two contradictory minimums appear on the same panel.
- **Payout multiplier inconsistency.** The market header shows "1.5x payout" for YES 65% (= 1/0.65) while the trade panel returns ₦500 on ₦274 = 1.82x. After the AMM fix the header figure becomes correct; verify they agree.
- **Fee documentation drift.** `KASIRO_BRAIN.md` states 2% on AMM trades. Live markets carry `fee_bps=100` (prod) and `fee_bps=250` (dev clone). One of the two is stale.
- **Duplicate markets (dev clone only; prod clean).** 19 markets, 11 distinct questions. Two bulk creates a day apart — the 9 Jul batch has `proposition_fingerprint = NULL`, so the 10 Jul batch passed the dedupe gate because `NULL` never matches. **Production still has 1 market with a NULL fingerprint**, invisible to the same gate. Backfill fingerprints or add `NOT NULL` going forward.
- **API 404s return HTML.** Unknown `/api/*` paths fall through to the SPA catch-all instead of a JSON 404.
- **CSP allows `connect-src https://api.anthropic.com`** — likely a leftover that shouldn't ship to production.
