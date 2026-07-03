# Predicto / Kasiro Agent System

Agent spec version: v1.1
Last updated: 2026-07-03
Execution mode: on-demand first, event-triggered second, scheduled only for risk prevention

---

## Files

SPEC.md defines behaviour. SKILL.md defines how to start, load context, run the command, and return output.

| Agent | SPEC (behaviour) | SKILL (invocation) | Other |
|---|---|---|---|
| Operator Brain | `agents/operator-brain/SPEC.md` | `agents/operator-brain/SKILL.md` | `agents/operator-brain/PROMPT.md`, `agents/operator-brain/SMOKE_TESTS.md` |
| Market Brain | `agents/market-brain/SPEC.md` | `agents/market-brain/SKILL.md` | — |
| Marketing Brain | `agents/marketing/SPEC.md` | `agents/marketing/SKILL.md` | — |
| Product Brain | `agents/product/SPEC.md` | `agents/product/SKILL.md` | — |
| Engineering Brain | `agents/engineering/SPEC.md` | `agents/engineering/SKILL.md` | — |

---

## Supported social platforms in v1.1

Owned/autopost:
1. X
2. Instagram
3. Threads

Reply Hunt:
1. X
2. Threads
3. Instagram comments where available

Out of scope:
1. Telegram autoposting

---

## Run order

1. Operator loads doctrine and current state.
2. Operator identifies the relevant command.
3. Operator routes to the relevant brain.
4. Brain executes command.
5. Brain returns output artifact, handoffs, and strict JSON brain_update.
6. Operator accepts, rejects, or requests revision.
7. Approved brain_update is written back to domain state.

---

## Core principles

1. Agents run on demand by default.
2. Event triggers are allowed only when they prevent missed closes, missed resolutions, failed posts, or approved workflow handoffs.
3. Market Brain must verify real-world status every time.
4. Marketing must not promote any market without valid prepublish_check and real_world_status_check.
5. Autoposting covers X, Instagram, and Threads only.
6. Reply Hunt must be relevant, useful, non-spammy, and linked to a live safe market.
7. Product recommendations require anti-requirements.
8. Engineering outputs require acceptance tests, regression checks, data safety, and rollback note.
9. Operator enforces all cross-brain gates.
10. Target audience fit is a decision tiebreaker across Operator, Market, Marketing, and Product.

---

## Kasiro target audience

Young, mobile-first African users, especially Nigerians, who follow football, Afrobeats, creators, internet culture, elections, FX, and public debates.

Kasiro should feel connected to the arguments already happening on the timeline while staying clear, source-based, and trustworthy.

---

## Brain outputs

Every brain output must include:

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

---

## Valid decision statuses

```
publish_now
post_now
queue_for_approval
ship_now
spec_for_engineering
needs_review
needs_revision
watchlist
defer
kill
reject
cannot_validate
event_started
expired
duplicate
cannot_price
```
