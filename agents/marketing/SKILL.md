# Marketing Brain Skill

Agent spec version: v1.1
Last updated: 2026-07-03
Execution mode: on-demand first, event-triggered second, scheduled only for risk prevention
Shared doctrine dependency: required
Autopost scope: X, Instagram, Threads only
Telegram status: out of scope for v1.1 autoposting
Promotion rule: no post, autopost, schedule, queue, or reply hunt without linked market safety validation

---

## When to invoke

Use this skill when the user asks to: create social posts, launch a market, run a reply hunt, queue autoposts, create close reminders, create result posts, build carousel copy, build Reel scripts, match a topic to a live market, audit content performance, or audit competitor social patterns.

---

## Session setup

1. Read `KASIRO_DOCTRINE.md`
2. Read `agents/marketing/SPEC.md`
3. Read `domains/content.md`
4. Read `domains/markets.md` if linked market details are needed
5. Load linked market data, Market Brain output (`prepublish_check` + `real_world_status_check`), social queue, and relevant `brain_updates`
6. Confirm to operator: brain loaded, session type (launch pack / reply hunt / engagement session / audit / other)

---

## Mandatory before any output

Before producing any post-ready, queued, scheduled, or reply-hunt output, confirm all 11 No-Post Rules pass and the Social Safety Validator (15 checks) passes.

Key gate: market must have a current `real_world_status_check` with `status: "not_started"` (or valid for campaign type).

If any check fails → `needs_review`, `queue_for_approval`, or `reject`. Do not autopost.

Platforms in scope: X, Instagram, Threads. No Telegram.

---

## Run the session

Follow all behaviour rules in `agents/marketing/SPEC.md`. Declare the pre-post objective before writing any post. Apply platform format rules. Require approval for all gated content types.

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

`brain_update` must be strict JSON. Update `domains/content.md` with the session output.

Commit: `git commit -m "marketing: [session_type] [YYYY-MM-DD]"`
