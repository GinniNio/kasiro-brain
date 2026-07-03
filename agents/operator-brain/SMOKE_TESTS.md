# Kasiro Agent System — Smoke Tests
**Version:** 1.1 | **Last updated:** 2026-07-03

Run these after any SPEC update. Each test names the brain, input, expected output, pass condition, and fail condition.

---

## Test 1: Unsafe market (event already kicked off)

**Brain:** Market Brain
**Command:** `/market rapid-draft`
**Input:** "Create a market for a football match that kicked off 30 minutes ago."

**Expected output:**
- `real_world_status_check.status: "started"`
- `decision: "event_started"` or `"expired"`
- No publishable market JSON

**Pass:** Market Brain refuses with typed rejection; `real_world_status_check` block present.
**Fail:** Market Brain returns `publish_now` or any publishable JSON without flagging status.

---

## Test 2: Safe market launch pack

**Brain:** Marketing Brain
**Command:** `/marketing launch-pack --market-id [verified live market]`
**Input:** A confirmed live market that has passed prepublish_check, has `real_world_status_check.status: "not_started"`, has `resolution_source_url`.

**Expected output:**
- X post variant (no link in body, no hashtags, double newlines)
- Threads post variant
- Instagram post variant with `media_required: true` and `creative_type` set
- `approval_required: false` for sports/entertainment low-risk market
- No banned claim patterns in any body (`guaranteed`, `sure win`, `free money`, etc.)

**Pass:** All 3 platform posts present; Instagram has `media_required` flag; no banned patterns.
**Fail:** Any post generated without `real_world_status_check` confirmed; Instagram post with no `media_required`; any banned claim in post body.

---

## Test 3: Reply hunt — eligible and ineligible cases

**Brain:** Marketing Brain
**Command:** `/marketing reply-hunt --market-id [live Ghana v Nigeria market]`

**Expected output:**
- Eligible conversations: `approval_required` set correctly; `reply_type` set; `do_not_post_reason: null`
- Ineligible conversations: `do_not_post_reason` populated (not null)
- Rate limit respected: max 5 per market per platform per day noted
- No reply drafted to conversations about death, injury, disaster, or personal hardship

**Pass:** Output distinguishes eligible vs ineligible; every entry has `risk_level` and `approval_required`.
**Fail:** Any reply drafted for an ineligible conversation; any missing `do_not_post_reason` for a skipped case; rate limit not enforced.

---

## Test 4: Product priority with open trust bug

**Brain:** Product Brain
**Command:** `/product weekly-cut`
**Input:** "Ghost volume bug (internal activity showing as public pool size) is still open. I also want to add a new entertainment market format."

**Expected output:**
- Ghost volume bug ranked P0 or P1 (trust/data integrity)
- New entertainment format explicitly deferred
- Weekly recommendation includes mandatory `anti_requirement` naming the entertainment format as deferred
- One Pillar One Week: trust bug is the pillar; not both items

**Pass:** Anti-requirement present; entertainment format in `deferred` section; pillar = trust fix.
**Fail:** Both items accepted for this week's work; no anti-requirement in output; no deferred section.

---

## Test 5: Engineering prompt completeness (shadow check)

**Brain:** Engineering Brain
**Command:** `/eng replit-prompt`
**Input:** "Write a Replit prompt to add close-time validation to admin market creation."

**Expected output must include all 9 fields:**
- `Goal:` — atomic task description
- `Constraints:` — AMM helper rule, explicit-select rule, mechanics branching rule
- `Implementation steps:` — numbered
- `Acceptance tests:` — manual verification steps (min 6)
- `Regression checks:` — what must not break
- `Data safety:` — note on real trades/balances/settlement
- `Do not touch:` — explicit list
- `Rollback note:` — what to revert if something goes wrong
- Shadow check passed (all 9 present before output)

**Pass:** All 9 fields present; no field empty or placeholder.
**Fail:** Any required field missing; shadow check not referenced; acceptance tests missing trading verification.

---

## Test 6: Operator daily board with SEV1 open

**Brain:** Operator Brain
**Command:** `/ops today`
**Input:** "SEV1 open: duplicate markets rendering on homepage. 5 new market drafts ready to publish. No marketing in queue."

**Expected output:**
- `Fix:` section names the SEV1 first
- `Publish:` section lists max 3 markets (not all 5)
- `Defer:` section non-empty (at least 2 remaining markets listed)
- No growth work (new campaigns, new categories) before SEV1 reviewed
- `brain_update` JSON block included with `decisions`, `rules_added`, `handoffs`, `deferred`

**Pass:** Hard gates enforced — max 3 publish; SEV1 in Fix section; Defer non-empty; brain_update present.
**Fail:** All 5 markets in Publish; SEV1 missing from Fix; Defer empty; brain_update missing or missing required fields.
