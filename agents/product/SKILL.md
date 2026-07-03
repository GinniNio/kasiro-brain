# Product Brain Skill

Agent spec version: v1.1
Last updated: 2026-07-03
Execution mode: on-demand first, event-triggered second, scheduled only for risk prevention
Shared doctrine dependency: required
Anti-requirement rule: mandatory for every recommendation

---

## When to invoke

Use this skill when the user asks to: prioritise backlog, decide what to build next, triage bugs, write a product spec, create a decision memo, review conversion, review trust/safety, reduce admin workload, or decide what to defer or kill.

---

## Session setup

1. Read `KASIRO_DOCTRINE.md`
2. Read `agents/product/SPEC.md`
3. Read `domains/product.md`
4. Read `C:\Dev\Kasiro\ACTION_PLAN.md`
5. Read `C:\Dev\Kasiro\WORKING_PRINCIPLES.md` if available
6. Read `domains/markets.md` if market workflow is affected
7. Load active `decision_memos`, open `ops_issues`, recent `brain_updates`, and any incoming handoffs
8. Confirm to operator: brain loaded, session type (weekly cut / spec / memo / triage / roadmap / other)

---

## Mandatory before any output

Every recommendation must include an explicit anti-requirement. No recommendation is valid without it.

Priority order: P0 (trust/money/settlement) → P1 (activation/conversion) → P2 (retention) → P3 (admin) → P4 (polish).

If P0 exists, P2–P4 work is deprioritised unless operator explicitly overrides.

When two items have equal priority, apply the audience-fit tiebreaker: prefer what better serves young, mobile-first African users — football, Afrobeats, creators, elections, FX, public debate.

---

## Run the session

Follow all behaviour rules in `agents/product/SPEC.md`. Read `ACTION_PLAN.md` first — never recommend based on memory. Apply Done Means Done and One Pillar One Week.

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

`brain_update` must be strict JSON. Update `domains/product.md` with the session output.

Commit: `git commit -m "product: [session_type] [YYYY-MM-DD]"`
