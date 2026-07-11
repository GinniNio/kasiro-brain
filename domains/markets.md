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

## Live State

Current wave count, category balance, the verified-ready queue, and rejected ideas are **not** kept in this file anymore. Doctrine (formats, schema, banned types) is stable and safe to trust across sessions; wave state is not — it goes stale within days and was causing real incidents (two sessions independently owning "the current queue" and diverging, per the 2026-07-11 merge conflict).

Live state now lives in **[`wave-state.md`](./wave-state.md)**, which carries an explicit staleness banner and is meant to be treated as a snapshot, not a source of truth. For actual current market counts and category balance, query `/api/markets` directly — it's more authoritative than any markdown file.

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
- Never accept or reject an external audit/counter-audit document wholesale — fact-check each specific claim independently. A 2026-07-11 counter-audit was right about two things (Google Trends' 5-term comparison cap; an invalid `african_internet_culture` category slug) and wrong about two others (falsely claimed BBNaija S11's date and a Comic Con Africa attendance source were unverifiable, when both checked out live). Treating it as fully right or fully wrong would have produced a worse doc either way (2026-07-11)
- A Google Trends "Attention Battle" market can only compare 5 topics/groups on one reproducible Trends comparison — any design with more outcomes needs to be cut to 5 or split into separately-calibrated batches (which isn't reliable without a formal calibration method). Check this before drafting any Attention Battle market (2026-07-11)
- Doctrine files must not hold fixed, fact-specific market lists (verified-ready queues, wave counts, category balance) — those decay within days and get cited as current by later sessions that skip re-verification. Split stable doctrine (formats, schema, banned types) from session snapshots; snapshots need an explicit staleness banner and should point back to the live API, not be trusted standalone. This file was itself violating its own "never draft off a document's claims without re-searching" rule until this session (2026-07-11)
- An AI session's self-report of what it did or didn't do to a shared repo is not reliable — a separate machine's session claimed it "only read the repository" and made no commits, but `git log origin/main` showed three real commits from that session that rewrote `markets.md` and reverted it to a stale state. Verify against git history, not the agent's own account of its actions (2026-07-11)
- When two sessions on different machines edit the same brain file, `git push` will reject on a non-fast-forward and force a `fetch`/`diff`/merge-or-resolve step — read the diff direction carefully (`HEAD vs origin/main`) before merging, since the "incoming" side is not automatically the newer or more correct one. In this incident the remote side was the regression, not the update (2026-07-11)
