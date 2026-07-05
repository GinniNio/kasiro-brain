# Kasiro Brain — Session Bootstrap

Agent spec version: v1.1
Last updated: 2026-07-05

---

## Purpose

This is the single entry point for all kasiro-brain sessions. It loads shared context before any brain-specific work begins, so the session starts anchored in Kasiro's current state — not a homepage dump.

## How to invoke

Mount the `kasiro-brain` folder in Cowork. At the start of any session, say:

> "Follow SKILL.md"

or

> "Open a Kasiro brain session"

---

## Step 1 — load shared context (do this before anything else)

1. Read `KASIRO_DOCTRINE.md` — 15 shared rules, execution mode, target audience, connected agent loop. These override everything.
2. Read `KASIRO_BRAIN.md` — agent index, domain files table, shared DB tables, current state.
3. Read the domain file(s) relevant to the session:
   - `domains/markets.md` — for market work
   - `domains/content.md` — for marketing/social work
   - `domains/product.md` — for product/prioritisation work
   - `domains/eng.md` — for engineering/bug work
   - Read all four if session type is unclear.

Do not read the Kasiro codebase (`C:\Dev\Kasiro`) unless the session explicitly requires code-level context. That is Engineering Brain's job, not session bootstrap.

---

## Step 2 — confirm to operator

After loading, confirm in one line:

> Kasiro Brain loaded. [List domain files read.] Which brain and session type?

Then list available commands:

```
Operator Brain (daily ops / weekly plan / risk check):
  /ops today
  /ops weekly-plan
  /ops risk-check

Market Brain (draft / audit / validate):
  /market morning-scan
  /market prepublish-check
  /market rapid-draft --topic [topic]
  /market calendar --days [n]

Marketing Brain (posts / reply hunt / autopost):
  /marketing launch-pack --market-id [id]
  /marketing reply-hunt --topic [topic]
  /marketing engagement-session

Product Brain (prioritise / spec / memo):
  /product weekly-cut
  /product decision-memo --topic [topic]
  /product feature-spec --feature [feature]

Engineering Brain (bug / Replit prompt / audit):
  /eng bug-diagnosis --issue [issue]
  /eng replit-prompt --spec [spec]
```

---

## Step 3 — load the brain SPEC and run

Once the operator names a command, load the relevant brain SPEC:

- Operator: `agents/operator-brain/SPEC.md`
- Market: `agents/market-brain/SPEC.md`
- Marketing: `agents/marketing/SPEC.md`
- Product: `agents/product/SPEC.md`
- Engineering: `agents/engineering/SPEC.md` + `C:\Dev\Kasiro\replit.md`

Follow all behaviour rules in that SPEC. Do not skip doctrine.

---

## Step 4 — session end

Every session must return:

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

`brain_update` must be strict JSON. Write back to the relevant domain file. Commit with the appropriate message format.
