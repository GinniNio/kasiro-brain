# SEV2 — Parimutuel displayed odds disagree with settlement

**Status:** OPEN · **Found:** 2026-07-25 · **Scope:** parimutuel markets only (AMM tracked separately in `SEV1-amm-pricing-replit-prompt.md`)

**Not exploitable.** Parimutuel has no sell side — stakes are one-way until settlement — so there is no round-trip arbitrage. The settlement math itself is correct textbook parimutuel. This is a **consistency and trust** defect: the odds shown to traders do not match what settles.

**Errs in the trader's favour**, so no user is short-changed. The platform under-collects rake against its own stated model.

---

## 1. The mismatch

**Settlement** (`server/parimutuel.ts:506-514`) rakes only the **losing** pool:

```
prizePool = losingPoolsTotal × (1 − r)
payout    = stake + (stake / winningPoolTotal) × prizePool
```

**Every display surface** rakes the **whole** pool:

```
odds_shown = T × (1 − r) / W
```

Substituting `T = W + L`:

```
odds_actual = 1 + L(1−r)/W = T(1−r)/W + r = odds_shown + r
```

**Actual payout is exactly `+r` higher than advertised, every time.** At 8%:

| Card shows | Actually settles |
|---|---|
| ~2.36x | 2.44x |
| ~3.07x | 3.15x |
| ~6.57x | 6.65x |

---

## 2. Decision: standardise on RAKE-ON-LOSSES

Settlement is already correct; the display surfaces move to match it.

**Why rake-on-losses is the right convention:** it guarantees a correct prediction never returns less than 1.0× stake. Under rake-on-total, a one-sided market where `W = T` pays:

```
T × (1 − 0.08) / T = 0.92×
```

A trader who was *right* gets back less than they staked. That is indefensible and drives immediate churn.

Under rake-on-losses:

- **Two-sided market (L > 0):** operator collects `L × r`. Guaranteed positive.
- **One-sided market (L = 0):** multiplier is exactly 1.0×, full stake refunded. Operator earns 0, loses 0.
- **Void market:** 100% refunded. Operator earns 0, loses 0.

Parimutuel is player-versus-player — payouts are funded entirely by stakes, so the operator never takes inventory risk. Zero capital risk in all three cases.

**Canonical formula:**

```
M = 1 + (T − W)(1 − r) / W        where T = total pool, W = target outcome pool, r = feeBps/10000
```

---

## 3. ⚠️ OPEN DESIGN QUESTION — virtual seed weights (decide before coding)

`server/routes/markets.ts:356-362` blends **real stakes and virtual seed weight** into one figure:

```ts
const effectiveWeight = realStaked + virtualWeight;
const impliedOdds = (totalEffective * payoutMul) / effectiveWeight;
```

But settlement (`parimutuel.ts:380-381`) pays from **real `total_staked` only**. Virtual seed is notional — it is not capital anyone deposited.

**Consequence: on a virtual-seeded market with few real stakes, displayed odds diverge from settlement no matter which rake convention is used.** Changing the rake formula does not fix this; it is a separate and arguably larger trust gap.

### DECIDED 2026-07-25: **Option B — real-only odds**

| Option | Behaviour | Verdict |
|---|---|---|
| A. Indicative labelling | Keep blended odds, label as indicative | **Rejected** |
| **B. Real-only odds** | Multiplier from real stakes only; `—` until real stakes exist | **CHOSEN** |
| C. Operator-backed seed | Virtual seed becomes real operator capital | **Rejected** |

**Why A was rejected.** A label does not rescue a number the settlement engine cannot pay. A trader who stakes at a displayed 4.5x, wins, and receives 1.0x because no real losing stakes existed has been misled — "indicative" caption or not. Doctrine rule 1: trader trust beats market volume.

**Why C was rejected.** Backing virtual seed with house capital makes the operator an unhedged market maker and destroys the zero-inventory-risk property in §2, which is the structural reason parimutuel is safe to run solo.

### Option B display rules

| Real-pool state | Display |
|---|---|
| `T_real = 0` (no real stakes at all) | `—` / Unbacked |
| `W_real > 0, L_real = 0` (one-sided) | `1.0x` (refund) |
| `W_real > 0, L_real > 0` (two-sided) | exact rake-on-losses odds |

**Virtual seed weights are restricted to the visual distribution bar only** (`poolShare` / `displayPct`). They must never enter a return multiplier.

### ⚠️ Accepted cost — the board goes visually empty

Measured on production 2026-07-25: **6 of 8 parimutuel markets have exactly 1 trade.** A single trade puts all real stake on one outcome, so `L_real = 0`. Under Option B a 5-outcome card renders as one `1.0x` and four `—`.

### DECIDED 2026-07-25: adopt operator seeding in the same change

Place small **real** operator stakes at activation so `W_real > 0` and `L_real > 0` from block zero. No maths special-casing, settlement unchanged, and the board is populated with truthful odds.

**Allocate proportional to `virtual_seed_weight`, never uniformly.** The weights encode a genuine prior — e.g. the Golden Boot market runs Mbappé 31 / Messi 33 / Haaland 14 / field 10. A flat $1 per outcome would render every outcome at an identical multiplier, which is worse than the current state. Seeding by weight *promotes the prior into real money*; the virtual weights stop being a cosmetic substitute and become the allocation key, and can retire once real staking dominates.

Specify a **total** seed distributed by weight, with a per-outcome floor — otherwise a 6%-weight outcome receives dust and displays an absurd multiplier.

Doctrine rule 3 is satisfied: the schema already separates `operator_volume` from `user_volume` (see the `isOperator ? 0 : …` pattern in `amm-sell.ts`). Operator stakes must also be excluded from `stakerCount`.

**⚠️ Honest caveat — this is a bounded departure from the zero-risk property in §2.** With seeding, the operator is a participant holding a position, not a neutral house. If no users join, everything is recovered (sole staker, and the rake returns to the operator). With users, operator P&L depends on whether the seed prior was accurate. This is capped by the seed size and is far weaker than Option C's open-ended backstop — but §2's "zero inventory risk" now reads "zero risk beyond the seed".

---

## 4. Call-site inventory (verified against commit `c00f743`)

### Sites that COMPUTE the multiplier — all three must change

| # | File | Lines | Current | Feeds |
|---|---|---|---|---|
| 1 | `server/routes/markets.ts` | 360-362 | `(totalEffective × payoutMul) / effectiveWeight` | market payload `impliedOdds` → trading panel, market page |
| 2 | `server/parimutuel.ts` | 158-162 | `(postStakeTotalPool × payoutMultiplier) / postStakeOutcomePool` | post-stake odds returned on trade; Telegram bot |
| 3 | `client/src/lib/marketDistribution.ts` | 131, 133, 137 | `feeMult × (totalPool / staked[i])`, `feeMult × (totalSeed / weights[i])`, `feeMult × n` | all market cards (home, hero, standard) |

### Site that is CORRECT — do not change

| # | File | Lines | Note |
|---|---|---|---|
| 4 | `server/parimutuel.ts` | 506-514 | Settlement. Already rake-on-losses. This is the reference. |

### Pure consumers — display only, no math, no change

- `client/src/lib/parimutuel-math.ts:22` `formatPariMultiplier`, `:32` `calculatePariEstReturn`
- `client/src/components/ParimutuelTradingPanel.tsx` — L69, 132, 211, 246, 478, 543, 564
- `client/src/pages/market.tsx` — L127, 1084, 1205
- `client/src/components/markets/HeroFeaturedCard.tsx` — L205, 212
- `client/src/components/markets/StandardPoolCard.tsx`
- `client/src/pages/home.tsx` — L30
- `server/bot/execute-trade.ts:93` — passes `impliedOdds` through to Telegram

### Tests that encode the OLD convention — will fail, and should

- `tests/market-distribution.test.ts` — L79-82 (`feeMult * 2`), L227 (`feeMult=0.92`), L234 (`feeMult=0.95`)
- `tests/parimutuel.test.ts`, `tests/parimutuel-math.test.ts`
- `tests/payout-hint-empty-state.test.ts`, `tests/ghost-liquidity-smoke.test.ts` — check for odds assertions

> `server/social-meta.ts` and `server/routes/seo.ts` were checked — **neither computes a multiplier.** No change needed.

---

## 5. REPLIT PROMPT

```
SEV2: Parimutuel displayed odds use rake-on-total; settlement uses rake-on-losses.
Displayed odds are understated by exactly the rake rate (0.08) on every market.

DECISION ALREADY MADE: standardise on RAKE-ON-LOSSES. Settlement is correct and
must NOT change. All three display sites move to match it.

VIRTUAL SEED DECISION: OPTION B — REAL-ONLY ODDS.
  Virtual seed weight may drive the distribution bar (poolShare / displayPct) ONLY.
  It must NEVER enter a return multiplier. Multipliers use real stakes exclusively.

CONFIRM APPROACH AND LIST FILES BEFORE WRITING CODE.

TASK 1 — Create the single source of truth.

  New file: shared/parimutuel-odds.ts

    export interface ParimutuelOddsParams {
      totalPool: number;    // REAL stakes only, all outcomes
      outcomePool: number;  // REAL stakes only, target outcome
      userStake?: number;   // incoming stake, for post-stake dilution
      rakeBps?: number;     // default 800
    }

    /**
     * Canonical parimutuel payout multiplier. Rake-on-losses.
     *   M = 1 + (T - W)(1 - r) / W
     * Matches settlement in server/parimutuel.ts resolveParimutuelMarket().
     * Returns a RAW unrounded value.
     */
    export function calculateParimutuelOdds(p: ParimutuelOddsParams): number

  Required behaviour:
    - W = outcomePool + userStake ; T = totalPool + userStake ; L = T - W
    - W <= 0  -> return 0    (UNBACKED sentinel; callers already gate on `mult > 0`.
                 Do NOT return 1.0 — an unbacked outcome has the BEST odds, and
                 showing 1.0x suppresses the stakes that balance the book.)
    - L <= 0  -> return 1.0  (one-sided: full stake refund, no rake)
    - else    -> 1 + L * (1 - rakeBps/10000) / W

  DO NOT round inside this function. No toFixed, no Math.round. Rounding here makes
  acceptance test P1 (raw equality with settlement to 1e-6) impossible to satisfy.
  Display rounding already exists in client/src/lib/parimutuel-math.ts
  formatPariMultiplier(). Server display sites round at the call site as they do today.

  The `userStake` parameter is REQUIRED, not optional in practice:
  server/parimutuel.ts:156-157 deliberately adds the incoming stake before computing
  so the trader sees the diluted odds they will actually receive. Do not lose that.

TASK 2 — server/parimutuel.ts lines 156-163.
  Replace the inlined calculation with parimutuelMultiplierAfterStake(...).
  Do NOT touch resolveParimutuelMarket (lines 506-514) — it is the reference
  implementation and is already correct.

TASK 3 — server/routes/markets.ts lines 356-362. THIS IS THE MOST IMPORTANT FILE.
  This is the ONLY site where real and virtual weights are blended, and therefore
  the site where Option B is actually implemented. It currently does:

      const effectiveWeight = realStaked + virtualWeight;
      const impliedOdds = (totalEffective * payoutMul) / effectiveWeight;

  Split the two concerns:
    - impliedOdds -> calculateParimutuelOdds({ totalPool: totalRealStaked,
                       outcomePool: realStaked, rakeBps })
                     REAL STAKES ONLY. Virtual weight must not appear.
    - poolShare   -> keep using effectiveWeight / totalEffective (unchanged).
                     The distribution bar continues to use virtual weights.

  You will need a totalRealStaked sum alongside the existing totalEffective.

TASK 4 — client/src/lib/marketDistribution.ts lines 127-138.
  Same split: multipliers real-only, displayPct unchanged.
    - "real" branch (L131): calculateParimutuelOdds({ totalPool, outcomePool: staked[i], rakeBps })
    - "seed" branch (L133): return 0. This branch exists precisely BECAUSE there are
      no real stakes, so under Option B there is no backed multiplier. The bar still
      renders from virtual weights via displayPct.
    - "equal fallback" (L137): return 0, for the same reason.
  DO NOT strip virtual weights from the displayPct calculation — that would flatten
  every distribution bar. Only the multiplier becomes real-only.
  Update the doc comment at L36 which still describes "feeMult * totalWeight / myWeight".

TASK 4b — Verify the UI renders the unbacked state.
  With multiplier 0, formatPariMultiplier() already returns "—" (parimutuel-math.ts:23).
  Confirm every consumer gates on mult > 0 and does not print "0.00x":
    ParimutuelTradingPanel.tsx L69,132,211,246,478,543,564
    market.tsx L1084 ; HeroFeaturedCard.tsx L212 ; StandardPoolCard.tsx

NOT IN SCOPE — server/social-meta.ts and server/routes/seo.ts.
  Both were checked at commit c00f743. NEITHER computes a payout multiplier.
  Do not modify them. Do not invent an odds calculation to replace.

TASK 4c — OPERATOR SEEDING (new behaviour, ships with this change).

  WHERE: server/routes/admin-markets.ts, the parimutuel ACTIVATION branch
  (around L571-593, where virtual seed weights are currently written). This mirrors
  the AMM path which calls activateAmmMarket at L537.

  NOT at market creation. Markets are created as draft and must clear the
  clarity_lint / source_check / risk_compliance gates before opening. Capital must
  not enter a market that may never activate.

  NOT in server/parimutuel.ts — that file records stakes, it does not own activation.

  WHAT: after gates pass and virtual weights are written, place REAL operator stakes
  from PLATFORM_USER_ID across every outcome, then open the market.

  ALLOCATION — proportional to virtual_seed_weight. NEVER uniform.

    Uniform allocation would render every outcome at an identical multiplier and
    destroy the operator's prior. Example prior in production today:
    Golden Boot -> Mbappe 31, Messi 33, Haaland 14, field 10.

    DO NOT use: stake_i = max(FLOOR, TOTAL * w_i / sum_w)
    A bare max() breaks two things: the sum exceeds TOTAL whenever any outcome
    floors (so the constant no longer describes what is spent), and each floored
    outcome ends up holding MORE capital than its weight implies, giving it better
    odds than the prior intended. On a 12-outcome market with a 2% tail,
    5.00 * 0.02 = 0.10 floors to 0.20 — doubling that outcome's capital and halving
    its multiplier relative to intent.

    USE — floor, then renormalise the remainder:
      1. raw_i = TOTAL * w_i / sum_w
      2. FLOORED = { i : raw_i < FLOOR } ; assign stake_i = FLOOR for those
      3. REST    = TOTAL - (|FLOORED| * FLOOR)
         distribute REST across the remaining outcomes by their RELATIVE weights
      4. if REST <= 0, or any remaining outcome would still fall below FLOOR,
         raise TOTAL or reject activation — do not silently distort the prior
      5. assert sum(stake_i) == TOTAL to within rounding tolerance

  AMOUNT: introduce an explicit constant, e.g. PARIMUTUEL_SEED_TOTAL_USDT
  (start at 5.00) and PARIMUTUEL_SEED_FLOOR_USDT (start at 0.20), as a TOTAL across
  all outcomes — NOT per outcome. Ambiguity here is an 8x cost error on an
  8-outcome market. Mirror the existing VIRTUAL_POOL_SIZE_USDT naming.

  REQUIREMENTS:
    - Stakes must be real rows in parimutuel_pools.total_staked and the ledger,
      debited from the operator wallet. Not notional.
    - Operator exclusion: is_operator is an EXISTING column on users and wallets
      (see server/operator.ts:45 and server/detectors/rake.ts:52). It is NOT a
      per-trade flag. Do NOT add a column or write a migration. Derive operator-ness
      from the staking user exactly as server/trades/amm-sell.ts does
      (`isOperator ? 0 : ...` when accumulating user_volume), and apply the same
      exclusion to total_trades and pool.stakerCount.
    - recordParimutuelStake enforces a per-currency minimum stake — the seeding path
      must satisfy or explicitly bypass it.
    - Fail activation loudly if the operator wallet cannot fund the seed. Do NOT
      silently open an unseeded market — that reintroduces the empty board on
      exactly the markets nobody is watching.
    - Idempotent: re-running activation must not double-seed.

  ACCEPTANCE:
    S1  After activating an N-outcome parimutuel market, every outcome has
        total_staked > 0 and calculateParimutuelOdds returns > 1.0 for all of them.
    S2  Seed distribution matches virtual_seed_weight proportions within the floor
        tolerance. A market with weights 31/33/14/10 must NOT produce equal odds.
    S3  Public user_volume, total_trades and stakerCount all read 0 immediately
        after seeding.
    S4  Re-running activation does not double-seed.
    S5  sum(stake_i) == PARIMUTUEL_SEED_TOTAL_USDT to within rounding, INCLUDING
        markets where one or more outcomes hit the floor.
    S6  Long-tail case: 12 outcomes with a 2% tail weight. Assert the floored
        outcomes did not inflate the total and that un-floored outcomes retain
        their relative proportions.
    S7  Activation FAILS (does not open the market) when the operator wallet
        cannot fund PARIMUTUEL_SEED_TOTAL_USDT.

  OPERATOR RISK — recorded, since §2 claims zero inventory risk:
    Max loss per market is bounded by PARIMUTUEL_SEED_TOTAL_USDT.
    No-trade case recovers exactly 100% and never voids (every outcome is seeded,
    so winningPoolTotal > 0 always):
      payout = S_w + (S_total − S_w)(1 − r)   plus rake back  (S_total − S_w)·r
             = S_w + (S_total − S_w) = S_total

TASK 5 — server/parimutuel.ts lines 284-285.
  Docstring says "after 15% rake". Actual default is feeBps=800 (8%), which matches
  KASIRO_BRAIN.md. Correct the comment.

TASK 6 — Update tests that encode the old convention:
  tests/market-distribution.test.ts L79-82, L227, L234.
  Also check tests/parimutuel.test.ts, tests/parimutuel-math.test.ts,
  tests/payout-hint-empty-state.test.ts, tests/ghost-liquidity-smoke.test.ts.

ACCEPTANCE TESTS

  P1  CROSS-SUBSYSTEM (the assertion that would have caught this):
      For random (T, W, r) across many ratios, assert
        parimutuelMultiplier(T, W, r) * stake
      equals the payout produced by the ACTUAL settlement code path in
      resolveParimutuelMarket, to 1e-6.
      Call the real settlement function or extract a shared helper both use.
      Do NOT reimplement settlement inside the test — that is how the AMM defect
      survived for months.

  P2  Property test, >= 500 random pool distributions: multiplier >= 1.0 always.
      A correct prediction can never return less than stake.

  P3  Edge cases:
        L = 0 (one-sided)      -> exactly 1.0
        W = 0 (unbacked)       -> exactly 0 (sentinel, not 1.0)
        single staker          -> 1.0
        N-outcome, N in 2..10  -> multipliers finite and >= 1.0
        feeBps = 0             -> M = T/W exactly
        feeBps = 10000         -> M = 1.0 exactly

  P4  No float flakes: assert with explicit tolerance 1e-6 on raw values, and
      separately assert the 2dp rounded display value. Do not mix the two.

  P5  Regression: T=1000, W=400, r=800bps -> M = 1 + 600*0.92/400 = 2.38
      (old rake-on-total gave 2.30).

DO NOT
  - Do not change resolveParimutuelMarket. Settlement is the reference.
  - Do not touch AMM code paths.
  - Do not return 1.0 for an unbacked outcome.
  - Do not write to production.
```

---

## 6. Why this matters beyond the numbers

This is the **same disease as the AMM defect**, caught earlier: one piece of maths copied to several surfaces, which then drift.

The AMM ended up with five copies (`amm.ts`, `amm-buy.ts`, `amm-sell.ts`, `routes/markets.ts` quote handler, `bot/execute-trade.ts`, plus a sixth in the client Max button). Parimutuel is at four. The fix is not to re-sync copies — it is to delete the copies.

Hence `shared/parimutuel-odds.ts` rather than three parallel patches. If the next surface (a new card type, an OG image renderer, an email) needs a multiplier, it imports the function. That is the only structural defence.

**And P1 is the load-bearing test.** Not "does the formula compute what I think" but "does the displayed number equal what settlement pays". Every AMM test passed while the AMM was inverted, because they all tested one subsystem against its own assumptions. Assert across the boundary.
