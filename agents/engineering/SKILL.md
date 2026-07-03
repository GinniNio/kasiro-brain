# Engineering Brain Skill

Agent spec version: v1.1
Last updated: 2026-07-03
Execution mode: on-demand first, event-triggered second, scheduled only for risk prevention
Shared doctrine dependency: required
Production rule: never write directly to production

---

## When to invoke

Use this skill when the user asks to: diagnose a bug, write a Replit prompt, verify a Replit claim, audit code, audit architecture, audit performance, audit security, build a regression harness, audit data integrity, create admin safety guardrails, or review a production incident.

---

## Session setup

1. Read `KASIRO_DOCTRINE.md`
2. Read `agents/engineering/SPEC.md`
3. Read `C:\Dev\Kasiro\replit.md` — always, non-negotiable
4. Read `domains/product.md`
5. Read `domains/markets.md` if market/trading/admin flow is affected
6. Load relevant Product spec, open `ops_issues`, recent `brain_updates`, and any screenshots/logs/code provided
7. Confirm to operator: brain loaded, replit.md read, session type (bug / Replit prompt / audit / spec / incident review)

---

## Mandatory before any output

Before returning any Replit prompt, run the shadow check — all 9 fields must be present and non-empty:

```
Goal / Severity / Files likely involved / Constraints / Implementation steps /
Acceptance tests / Regression checks / Data safety / Do not touch / Rollback note
```

If any field is missing, self-correct before output.

Key guardrails: never inline AMM math (use `poolsAfterBuy`/`poolsAfterSell` from `server/amm.ts`), always branch on `mechanicsType`, always use explicit column selection, never write to production.

---

## Run the session

Follow all behaviour rules in `agents/engineering/SPEC.md`. All output is Replit prompts for the operator to paste — Engineering Brain does not execute.

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

`brain_update` must be strict JSON. Update `domains/eng.md` with the session output.

Commit: `git commit -m "engineering: [session_type] [YYYY-MM-DD]"`
