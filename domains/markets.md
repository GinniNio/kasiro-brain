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

### Five Question-Structure Formats (added 2026-07-09)
The innovation lever is question *structure*, not obscure subject matter. Support these five named formats so familiar stories still produce differentiated markets:
- **Race:** Which of several defined events happens first? (e.g. NIN hits 140M vs mobile hits 190M vs broadband hits 57%)
- **Basket:** How many of N listed events happen within a window? (e.g. BBNaija first-week chaos index — 5 defined events, pool by count)
- **Attention battle:** Which topic/person gains the most measurable attention? (e.g. Google Trends race between Tyla/BBNaija/WAFCON/World Cup; Wikipedia pageview comparisons)
- **Reaction market:** What happens immediately after a known decision/release? (e.g. which NGX sector moves most after CBN MPC decision)
- **Index market:** Combine several observable sub-events into one score.
Use these to convert routine stories (earnings season, chart releases, election cycles) into non-template markets. Always require: one definitive source, a real deadline, mutually exclusive pool options, no invented candidates, a reason the market matters now.

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

**Current wave:** WC R16 wave live. R16 results so far: Morocco 3-0 Canada (Jul 4), France 1-0 Paraguay (Jul 4). Morocco vs France QF confirmed Jul 9 21:00 WAT. Remaining R16: Brazil/Norway + Mexico/England (Jul 5), Spain/Portugal + USMNT/Belgium (Jul 6), Argentina/Egypt + Colombia/Switzerland (Jul 7). WAFCON anchors start Jul 28 (Nigeria vs Malawi, Rabat).
**Last Market Brain session:** 2026-07-09 (rapid-draft + strategic review)
**Markets live:** 24 (pre-settlement of Jul 4 closers)
**Categories currently over-represented:** sports_football (~95%)
**Categories currently under-represented:** macroeconomy, entertainment, fx_crypto, african_internet, politics, future_africa (new category, see below)
**Settlement due:** Jul 4 match markets (Morocco/Canada → Morocco; France/Paraguay → France) — settle proactively per 2026-07-03 learning.

**Verified-and-ready queue (2026-07-09 session, all facts re-checked live, none invented):**
- 2027 Presidential Election Winner parimutuel (Tinubu/Obi/Atiku/Other) — highest-priority gap fill
- Osimhen transfer destination parimutuel (Real Madrid/Galatasaray/PSG/Chelsea/Other) — Mourinho actively pursuing, €150M figures reported
- Africa startup capital race Q3 (Kenya/Nigeria/SA/Egypt) — Kenya genuinely overtook Nigeria in 2025 ($984M), real rivalry
- Which Big Tech responds first to Nigeria's FCCPC news-content probe (Google/Meta/X/AI co./none) — Tinubu ordered investigation 6-7 Jul 2026, FCCPC already fined Meta $220M in 2025
- Nigeria's Digital Infrastructure Race (140M NIN / 190M mobile / 57% broadband / Kuiper commercial launch) — NIN at 136.0M (up from 123.9M Oct 2025), mobile 188.0M, broadband 55.67%, Kuiper licensed Feb 2026 but not yet retail-live
- Flutterwave IPO filing before 31 Dec 2026 — denied but Mono acquisition + $75M govt approval signal real tension
- Davido "ORIADÉ" #1 debut on TurnTable Charts Nigeria — album confirmed 31 Jul, lead single out
- Attention Wars: Google Trends race, Tyla/BBNaija/WAFCON/World Cup, 24-31 Jul — Tyla album confirmed 24 Jul, BBN premiere confirmed 26 Jul
- NGX weekly best/worst performer (rotating parimutuel pair) — replaces the stale fixed-threshold ASI market design flaw
- Nigeria vs Zambia WAFCON event-page bundle (win/clean sheet/score first/named scorer under one event) — Group C confirmed (Malawi, Zambia, Egypt)

**Watchlist (mechanic ready, needs cast/nominee reveal before outcomes can be fixed):**
- Which BBNaija S11 housemate gains the most Instagram followers in 72 hours — needs official cast reveal
- Headies 18th edition award-category parimutuel — ceremony confirmed Oct 25 Toronto, nominees not yet published

---

## Rejected Ideas — Carry Forward
*(Paste from last Market Brain session output)*

```json
[
  {
    "idea": "Egypt to advance vs Argentina (binary AMM)",
    "reason_rejected": "Implied prior ~16% — below 20% floor. Reframed as 3-outcome parimutuel match market instead (proposed 2026-07-05)",
    "revisit_when": "n/a — superseded by parimutuel framing"
  },
  {
    "idea": "Who wins WC 2026? parimutuel (8 outcomes)",
    "reason_rejected": "QF field incomplete until Jul 7 R16 concludes — cannot fix outcome list yet",
    "revisit_when": "2026-07-08 morning, after final R16 matches"
  },
  {
    "idea": "Headies 2026 award category parimutuel bundle (ceremony Oct 25, Toronto — verified 2026-07-05)",
    "reason_rejected": "Nominee lists per category not yet verified — cannot fix parimutuel outcomes",
    "revisit_when": "When 18th Headies nominees are published (check theheadies.com)"
  },
  {
    "idea": "CBN MPC July decision market (meeting verified: Jul 20-21, 2026, MPC #306)",
    "reason_rejected": "Current MPR level and analyst consensus not verified this session — cannot price",
    "revisit_when": "Next afternoon-draft — verify MPR + consensus, then draft"
  },
  {
    "idea": "USD/NGN NAFEM rate band market (rate ~N1,370 as of Jul 3 — verified 2026-07-05)",
    "reason_rejected": "Band construction needs Kalshi-style reference-rate methodology pass, not done in morning scan",
    "revisit_when": "Next afternoon-draft — closes fx_crypto category gap"
  }
]
```

---

## Key Learnings Accumulated
*(Appended by Market Brain agent after sessions)*

- BBN S11 announced before market was created — always verify event hasn't happened (2026-05-30)
- Always web-search the underlying event before recommending; verify prior is 20–80%
- Research before suggesting is non-negotiable — stale prior or post-facto event = immediate reject
- Never assert round names, scores, or match status from memory — always verify via live web search. The Morocco/France "Round of 16" flag in the 2026-07-03 audit was entirely wrong; a search showed both teams had already played R32 and their July 4 match was correctly R16. One search would have prevented a false flag. (2026-07-03)
- Any-team-to-QF style meta-markets can resolve early if a qualifying match precedes the close time — settle proactively once outcome is known, don't wait for close time (2026-07-03)
- Pool-forming state on parimutuel markets suppresses trader entry — consider minimal operator seed to show initial price signal (2026-07-03)
- Competitor-board scans (Jupiter, Bayse) are most useful for stealing *question structure* and *market architecture* (event-page bundling, race/basket/attention-battle formats, deadline ladders), not literal topics — most of Jupiter's volume is Western political clickbait with zero African relevance and doesn't transfer (2026-07-09)
- Bayse's board proves personality-driven politics and activity-count formats work with real Nigerian users, but Bayse also runs banned-type markets (individual tweet-count = creator-influenced; active-criminal-proceedings market on Sowore/DSS) — copy the mechanic, never the object, and always re-run banned-type checks before adapting a competitor pattern (2026-07-09)
- A prior AI-generated market-ideas document is not a source — several of its cited "facts" (Tyla album date, NIMC enrolment figures, Kenya/Nigeria funding rivalry, FCCPC investigation) turned out to be accurate on re-verification, but they were re-checked live rather than trusted, per doctrine. Never draft off a document's claims without independently re-searching each fact (2026-07-09)
- Fixed-threshold macro markets (e.g. "NGX ASI above X on date") go stale fast when the index has strong momentum and can end up mispriced against reality within days; prefer rotating weekly-winner/loser formats for recurring macro categories (2026-07-09)
