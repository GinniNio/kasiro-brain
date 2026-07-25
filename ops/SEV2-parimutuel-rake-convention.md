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

Three options — **pick one before the agent starts:**

| Option | Behaviour | Trade-off |
|---|---|---|
| **A. Indicative labelling** | Keep blended odds; label them clearly as indicative until real liquidity exists | Cheapest. Honest only if the label is prominent. |
| **B. Real-only odds** | Compute odds from real stakes alone; show "—" until stakes exist | Truthful, but a fresh market shows no odds — worse cold-start |
| **C. Operator-backed seed** | Treat virtual seed as real operator capital that genuinely pays out | Odds become guaranteed, but the operator takes real inventory risk — contradicts the zero-risk property in §2 |

Recommendation: **A** for now (cheapest, preserves cold-start UX), with the disclosure wired to the existing `PARI_POOL_DISCLOSURE` constant in `client/src/lib/parimutuel-math.ts`. Revisit once real volume exists.

**Do not let the agent silently choose.** If unspecified it will likely apply the rake-on-losses formula to blended weights, which is mathematically coherent and still wrong in practice.

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

VIRTUAL SEED DECISION: <<< OPERATOR: fill in A, B or C from section 3 before running >>>

CONFIRM APPROACH AND LIST FILES BEFORE WRITING CODE.

TASK 1 — Create the single source of truth.

  New file: shared/parimutuel-odds.ts

    /**
     * Canonical parimutuel payout multiplier. Rake-on-losses.
     *   M = 1 + (T - W)(1 - r) / W
     * Matches settlement in server/parimutuel.ts resolveParimutuelMarket().
     */
    export function parimutuelMultiplier(
      totalPool: number,
      outcomePool: number,
      feeBps: number = 800,
    ): number

  Required behaviour:
    - outcomePool <= 0            -> return 0  (UNBACKED sentinel; callers already
                                     gate on `mult > 0`. Do NOT return 1.0 — an
                                     unbacked outcome has the BEST odds, and showing
                                     1.0x suppresses the stakes that balance the book.)
    - totalPool <= outcomePool    -> return 1.0  (L = 0: full stake refund, no rake)
    - otherwise                   -> 1 + (totalPool - outcomePool) * (1 - feeBps/10000) / outcomePool
    - Round to 2dp to match existing display precision. Do NOT change to 4dp.

  Also export, for post-stake quoting:

    export function parimutuelMultiplierAfterStake(
      totalPoolBefore: number,
      outcomePoolBefore: number,
      stake: number,
      feeBps?: number,
    ): number
      // = parimutuelMultiplier(totalPoolBefore + stake, outcomePoolBefore + stake, feeBps)

  This post-stake variant is REQUIRED. server/parimutuel.ts:156-157 deliberately adds
  the incoming stake before computing so the trader sees the diluted odds they will
  actually receive. Do not lose that.

TASK 2 — server/parimutuel.ts lines 156-163.
  Replace the inlined calculation with parimutuelMultiplierAfterStake(...).
  Do NOT touch resolveParimutuelMarket (lines 506-514) — it is the reference
  implementation and is already correct.

TASK 3 — server/routes/markets.ts lines 356-362.
  Replace the inlined calculation with parimutuelMultiplier(totalEffective,
  effectiveWeight, rakeBps). Apply the virtual-seed decision from the header here —
  this is the only site where real and virtual weights are blended.

TASK 4 — client/src/lib/marketDistribution.ts lines 127-138.
  Replace all three branches with parimutuelMultiplier:
    - "real" branch (L131): parimutuelMultiplier(totalPool, staked[i], feeBps)
    - "seed" branch (L133): parimutuelMultiplier(totalSeed, weights[i], feeBps)
    - "equal fallback" (L137): parimutuelMultiplier(n, 1, feeBps)
      (n equal outcomes: T = n, W = 1. At 8% and n=4 this gives 3.76x, not the
       old 3.68x. This change is expected.)
  Update the doc comment at L36 which still describes "feeMult * totalWeight / myWeight".

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
