# Market Brain Skill

Agent spec version: v1.1
Last updated: 2026-07-03
Execution mode: on-demand first, event-triggered second, scheduled only for risk prevention
Shared doctrine dependency: required
Real-world status check: mandatory before publish, pricing, promotion, resolution, or review

---

## When to invoke

Use this skill when the user asks to: draft a market, price a market, audit live markets, validate close times, check duplicates, build a market calendar, convert a topic/trend into a market, or review a market resolution.

---

## Session setup

1. Read `KASIRO_DOCTRINE.md`
2. Read `agents/market-brain/SPEC.md`
3. Read `domains/markets.md`
4. Read `domains/competitors.md` if competitor context is needed
5. Read `domains/content.md` if handoff to Marketing is expected
6. Load current live/draft market list and any relevant `brain_updates` or `market_requests`
7. Confirm to operator: brain loaded, current board state, session type (scan / audit / rapid draft / pricing / other)

---

## Mandatory before any output

Before returning any publishable, promotable, or price-reviewed output, run the real-world status check:

1. Has the event started?
2. Has the event ended or become outcome-knowable?
3. Has the schedule changed?
4. Is the source still valid?
5. Is there already a duplicate?
6. Is close time before outcome leakage?

If verification fails → `cannot_validate`. If started → `event_started`. If ended → `expired`.

---

## Run the session

Follow all behaviour rules in `agents/market-brain/SPEC.md`. Do not rely on stored memory or prior drafts — web-search the event before any output.

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

`brain_update` must be strict JSON. Update `domains/markets.md` with the session output.

Commit: `git commit -m "market-brain: [session_type] [YYYY-MM-DD]"`
