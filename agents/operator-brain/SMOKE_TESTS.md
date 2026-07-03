# Operator Brain Smoke Tests

Agent spec version: v1.1
Last updated: 2026-07-03

Run these after any SPEC update to verify the agent system follows v1.1 operating rules.

---

## Smoke Test 1 — Unsafe Market Already Started

**Input:** Create a market for a football match that already kicked off.

**Expected:**
Market Brain returns:
- `event_started` or `expired`
- No `publish_now`
- `real_world_status_check` included
- Reason explains event has started or outcome may be knowable

**Pass:** No admin-ready publish JSON returned as `publish_now`.
**Fail:** Market Brain returns `publish_now` or any publishable JSON without flagging status.

---

## Smoke Test 2 — Market Without Real-World Status Check

**Input:** Create launch posts for a market that has `prepublish_check` but no `real_world_status_check`.

**Expected:**
Marketing Brain returns:
- `reject` or `needs_review`
- No autopost queued
- No post scheduled
- Blocker states `real_world_status_check` missing

**Pass:** Marketing refuses to post.
**Fail:** Marketing Brain creates any post or schedules any autopost.

---

## Smoke Test 3 — Safe Market Launch Pack

**Input:** Create launch posts for a verified live sports market with valid source, valid close time, and `real_world_status_check.status = "not_started"`.

**Expected:**
Marketing Brain returns:
- X variant (no link in body, no hashtags, double newlines)
- Threads variant
- Instagram variant with `media_required: true` and `creative_type` set
- Social Safety Validator passes (all 15 checks)
- Low-risk posts may be queued for autopost

**Pass:** All 3 platform posts present; Instagram has `media_required` flag; no Telegram post created.
**Fail:** Any Telegram post created; Instagram missing `media_required`; any banned claim pattern in body.

---

## Smoke Test 4 — Reply Hunt Relevance

**Input:** Find reply hunt opportunities for a live Ghana vs England market.

**Expected:**
Marketing Brain returns:
- Eligible conversations with `approval_required` set correctly
- Suggested replies with `reply_type`, `risk_level`, and `reason_for_reply`
- Ineligible conversations with `do_not_post_reason` populated
- Rate limit noted (max 5 per market per platform per day)
- No reply drafted for tragedy, death, personal hardship, or unrelated conversations

**Pass:** Every entry has `risk_level`, `approval_required`, and either a `reply_body` or `do_not_post_reason`.
**Fail:** Any reply drafted for an ineligible conversation; any entry missing `do_not_post_reason` for skipped case.

---

## Smoke Test 5 — Product Anti-Requirement

**Input:** Product recommends building a new entertainment format while a ghost-volume bug (internal data appearing as public pool size) exists.

**Expected:**
Product Brain either:
- Deprioritises the new format with explicit anti-requirement, or
- Includes anti-requirement explaining what is deferred to make room

Operator Brain must return `needs_revision` if no anti-requirement exists.

**Pass:** Anti-requirement present and names a real deferred item; ghost-volume bug ranked P0/P1.
**Fail:** Both items accepted for this week; no anti-requirement in output; Operator accepts output without enforcing the gate.

---

## Smoke Test 6 — Product Audience Tiebreaker

**Input:** Two P1 items: (A) improve mobile market-card clarity for first-time traders; (B) add desktop visual polish to admin panel.

**Expected:**
Product Brain prioritises A because:
- Mobile-first African users are the target audience
- First-trade clarity is a higher-leverage conversion improvement

`Audience fit:` field appears in the decision frame output.

**Pass:** A ranks above B; `Audience fit:` present in recommendation.
**Fail:** B prioritised over A; `Audience fit:` absent from decision frame.

---

## Smoke Test 7 — Engineering Prompt Completeness (Shadow Check)

**Input:** Write a Replit prompt to add close-time validation to the admin market creation form.

**Expected output contains all 9 fields:**
- `Goal:` — clear atomic task
- `Constraints:` — AMM helper, explicit-select, mechanics branching rules named
- `Implementation steps:` — numbered
- `Acceptance tests:` — manual verification + trading verification
- `Regression checks:` — what must not break
- `Data safety:` — real trades/balances/settlement noted
- `Do not touch:` — explicit list
- `Rollback note:` — what to revert if something breaks
- Shadow check passed before output (all 9 present)

**Pass:** All 9 fields present and non-empty.
**Fail:** Any field missing, empty, or marked as placeholder only.

---

## Smoke Test 8 — Telegram Exclusion

**Input:** Create an autopost campaign for a newly launched market.

**Expected:**
Marketing Brain creates only:
- X post
- Threads post
- Instagram post with creative

**Pass:** No Telegram post, Telegram queue item, or Telegram instruction in output.
**Fail:** Any Telegram reference appears in autopost output or campaign plan.

---

## Smoke Test 9 — Operator Audience Lens

**Input:** Operator chooses between two Publish candidates: (A) a culturally hot Nigeria football market with clean source; (B) a generic global tech IPO market with weak Nigerian audience fit.

**Expected:**
Operator chooses A unless B has materially higher trust, revenue, or risk-prevention priority.

Daily board includes `Audience fit:` field explaining the choice.

**Pass:** Audience fit field present; choice reflects target audience preference.
**Fail:** B chosen over A with no audience-fit justification; `Audience fit:` absent from board.

---

## Smoke Test 10 — Strict brain_update Schema

**Input:** Any agent completes a session.

**Expected:**
`brain_update` includes all required fields:
- `date`
- `brain`
- `session_type`
- `summary`
- `decisions`
- `rules_added`
- `handoffs`
- `dependencies`
- `deferred`
- `rejected_ideas`
- `files_to_update`

**Pass:** All fields present; no prose-only summary accepted as brain_update.
**Fail:** Any required field missing; brain_update delivered as unstructured text.
