# Kasiro Market Intelligence
**Domain owner:** Market Brain agent | **Last updated:** 2026-07-03

---

## Market Pipeline Doctrine

**The operator's job:** Keep a small, fresh, relevant, trustworthy market board live. Quality over quantity. Stale markets kill trust faster than empty boards.

**Hard truths:**
- Market relevance is the product
- A solo operator cannot run discovery-heavy market generation — use the Market Brain agent
- Markets must be staged in waves of 3–4, never flooded
- Every market must have a public primary source URL that resolves the exact claim
- Close time must precede the moment outcome information becomes publicly visible

---

## Market Formats

### Binary AMM
- Two outcomes: YES / NO
- AMM-priced with continuous liquidity
- Operator sets opening YES probability (0.01–0.99)
- Revenue: 2% fee on every trade (`feeBps: 200`)
- Best for: single-event questions with clear binary resolution

### Parimutuel Multi-Outcome
- Three or more outcomes pooled
- Pool closes at defined time; participants share proportionally
- Operator sets seed weights per outcome (must sum to 100)
- Revenue: 8% rake (`feeBps: 800`) — aggressively low vs 15–25% industry norm
- Best for: elections, tournaments, award categories, multi-team events

---

## Market Schema (Drizzle/Postgres)

```
category         text          — category slug
question         text          — the market question
description      text          — 1-2 sentence context
resolution_criteria text       — exact condition for settlement
close_at         timestamptz   — before outcome becomes visible
resolve_at       timestamptz   — after result is officially published
open_price       numeric       — opening YES probability (0.0–1.0)
mechanics_type   text          — 'amm' | 'parimutuel'
status           text          — 'draft' | 'open' | 'locked' | 'settled' | 'voided'
```

**Field rules:**
- Use `category` not `subcategory` (no subcategory column on markets table)
- Use underscored slugs for category values
- `openPrice` range: 0.0–1.0 (not percentage)
- `closeAt` must precede event kick-off or announcement window

---

## Market Categories

| Category | Examples |
|---|---|
| Sports — Football | WAFCON 2026, AFCON qualifiers, Nigerian league, WC 2026 |
| Sports — Other | Athletics, boxing, basketball, table tennis |
| Entertainment & Culture | Big Brother Naija, AFRIMA, Headies, AMVCA, Nollywood box office |
| Music & Creators | Afrobeats chart performance, album debut positions, streaming milestones |
| Macroeconomy | CBN MPR decisions, NGX index, Nigeria GDP, NBS inflation prints |
| FX & Crypto | USD/NGN NAFEM rate bands, USDT/NGN rail, CBN reserve levels |
| African Internet Culture | Trending X/Twitter topics, viral content outcomes, creator milestones |
| Awards & Recognition | Any award with defined announcement date and verifiable public result |
| Public Affairs | ASUU strike, grid collapse, government policy decisions |
| Politics | Gubernatorial elections, party primaries, INEC declarations |

---

## Discovery Strips (Story Clusters)

| Cluster | Strip | Editorial purpose |
|---|---|---|
| `africa_watch` | Africa Watch | Major continent-level events with broad African relevance |
| `nigeria_watch` | Nigeria Watch | Nigeria-specific economics, politics, entertainment, sport |
| `todays_stories` | Today's Stories | Markets closing or resolving within 48 hours |
| `closing_soon` | Closing Soon | Markets within 24 hours of close time |
| `biggest_pool` | Biggest Pool | Highest-volume markets regardless of category |
| `pulse` | Pulse | Trending cultural and social media-driven markets |

---

## Market Lifecycle

```
draft → open → locked → settled
                      → voided
```

- **draft:** created by operator or AI, not visible to users
- **open:** live and tradeable; AMM requires seeding on activation
- **locked:** past close time; no new trades; awaiting resolution
- **settled:** resolved YES or NO; payouts distributed
- **voided:** cancelled; all stakes refunded

**AMM activation rule:** SQL-direct activation bypasses `operatorSeedMarket`; always use admin dialog or call seed programmatically. Open→locked transition must atomically clear `feature`/`featured_rank` (auto-lock demote promo rule).

---

## Pricing Standards

### Binary AMM — opening YES probability
Derive from (in order of preference):
1. Public odds converted to implied probability (strip overround)
2. Polymarket or Jupiter current market price for equivalent events
3. Historical base rates for recurring events
4. Explicit 0.50 default when no meaningful prior exists

### Parimutuel — seed weights (sum to 100)
Derive from:
1. Sports odds converted to implied probability, normalised
2. Competitor market distributions (Bayse, 2sabi)
3. Equal weights (e.g. 33/33/34) when no benchmark available

**Rule:** Never invent probabilities. Always state benchmark source and confidence level.

---

## Stagger Rule

For batches >4 markets: split into waves of 3–4 every 3–5 days across mixed pillars.

---

## Permanently Banned Market Types

1. Markets based on rumours, private info, unverifiable screenshots, or deleted content
2. Kidnapping/captivity/ransom markets
3. Celebrity arrest or active criminal proceedings markets
4. Markets requiring subjective judgement with no verifiable oracle
5. Unverifiable transit or logistics markets (Apapa Port transit times, etc.)
6. Western political clickbait with no meaningful Nigerian/African relevance
7. Markets with unstable settlement parameters or high manipulation risk
8. Creator-influenced outcomes (where creator can manipulate the outcome)

---

## Terminology

| Use | Not |
|---|---|
| Pick YES / Pick NO | Back YES / Back NO |
| Pool | Pot / Betting pool |
| Return preview | Odds / Payout odds |
| Closes | Deadline / Lock / Cut-off |
| Resolves | Settles / Pays out |
| Source | Verification link |
| Market | Bet / Event / Line |

---

## Current Wave State
*(Update after each Market Brain session)*

**Current wave:** [OPERATOR TO UPDATE]
**Last Market Brain session:** [DATE]
**Markets live:** [COUNT]
**Categories currently over-represented:** [UPDATE]
**Categories currently under-represented:** [UPDATE]

---

## Rejected Ideas — Carry Forward
*(Paste from last Market Brain session output)*

```json
[]
```

---

## Key Learnings Accumulated
*(Appended by Market Brain agent after sessions)*

- BBN S11 announced before market was created — always verify event hasn't happened (2026-05-30)
- Always web-search the underlying event before recommending; verify prior is 20–80%
- Research before suggesting is non-negotiable — stale prior or post-facto event = immediate reject
