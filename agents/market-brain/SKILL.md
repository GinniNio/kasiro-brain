# Market Brain Skill

Agent spec version: v1.2
Last updated: 2026-07-09
Execution mode: on-demand first, event-triggered second, scheduled only for risk prevention
Shared doctrine dependency: required
Real-world status check: mandatory before publish, pricing, promotion, resolution, or review

---

## When to invoke

Use this skill when the user asks to: draft a market, price a market, audit live markets, validate close times, check duplicates, build a market calendar, convert a topic/trend into a market, review a market resolution, scan competitor boards, or design a differentiated market slate.

---

## Session setup

1. Read `KASIRO_DOCTRINE.md`
2. Read `agents/market-brain/SPEC.md`
3. Read `domains/markets.md`
4. Read `domains/market-strategy.md`
5. Read `domains/competitors.md` if competitor context is needed
6. Read `domains/content.md` if handoff to Marketing is expected
7. Load current live/draft market list and any relevant `brain_updates` or `market_requests`
8. Confirm to operator: brain loaded, current board state, session type (scan / audit / rapid draft / pricing / strategy / other)

---

## Mandatory before any output

Before returning any publishable, promotable, or price-reviewed output, run the real-world status check:

1. Has the event started?
2. Has the event ended or become outcome-knowable?
3. Has the schedule changed?
4. Are every named participant, product, company and option real and eligible?
5. Is the source still valid and does it publish the exact settlement variable?
6. Is there already a duplicate?
7. Is close time before outcome leakage?
8. Can historical evidence still be retrieved after the event?
9. Is the outcome controlled or cheaply manipulable by a participant?
10. Has factual validation been kept separate from pricing?

If verification fails → `cannot_validate`. If started → `event_started`. If ended → `expired`.

---

## Strategic generation sequence

When generating a slate, do not default immediately to ordinary binary winner markets.

1. Identify the live African or Nigerian storyline.
2. Test it through the five editorial lenses in `domains/market-strategy.md`:
   - Attention Africa
   - Money and Daily Life
   - Sport as a Story System
   - Politics in Motion
   - Future Africa
3. Test whether the storyline supports a distinctive format:
   - Race
   - Basket
   - Attention Battle
   - Reaction Market
   - Index Market
   - Threshold Ladder
   - Deadline Ladder
   - Event Family
4. Score the candidate using the market selection score.
5. Reject candidates with weak sources, unsafe close times, fabricated facts, thin audience relevance or excessive solo-operator load.
6. Build waves of 3–5 markets across at least three editorial lenses.
7. Run a separate pricing pass only after the factual and structural validation passes.

Ordinary binaries remain acceptable as anchors. They must not dominate differentiated-market sessions.

---

## Competitor use

Competitor markets are discovery inputs, not facts.

Use them to identify:
- proven formats;
- local demand;
- category gaps;
- equivalent pricing references.

Revalidate every underlying event independently. Do not copy vague resolution rules, broken candidate lists, zero-price pools, creator-controlled outcomes or `ends by outcome` close logic.

---

## Run the session

Follow all behaviour rules in `agents/market-brain/SPEC.md`. Do not rely on stored memory or prior drafts. Web-search the event before any output.

For strategic slate work, return:

- top candidates ranked by score;
- editorial lens and format;
- verified live trigger;
- exact proposed question;
- close-time logic;
- primary resolution source;
- operational risk;
- publish / watch / reject decision;
- pricing status (`ready_for_pricing` or `cannot_price`).

---

## Session end

Produce the required output format:

```
Session goal:
Input used:
Decision:
Output artifact:
Open risks:
Deferred items:
Handoffs:
brain_update:
```

`brain_update` must be strict JSON. Update `domains/markets.md` with board state and `domains/market-strategy.md` when durable strategy changes.

Commit: `git commit -m "market-brain: [session_type] [YYYY-MM-DD]"`
