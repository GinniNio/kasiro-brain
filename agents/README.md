# Kasiro Agent System — File Index
**System version:** 1.1 | **Last updated:** 2026-07-03

---

## Load order (every session)

1. `../KASIRO_DOCTRINE.md` — 15 shared rules, overrides everything
2. `../KASIRO_BRAIN.md` — master index, agent directory, domain files, shared state
3. Relevant domain file(s) for the session
4. Agent `SPEC.md` for the session

---

## Agent files

| Agent | SPEC | SKILL (Cowork) | PROMPT (Chat paste) |
|---|---|---|---|
| Operator Brain | `operator-brain/SPEC.md` | `operator-brain/SKILL.md` | `operator-brain/PROMPT.md` |
| Market Brain | `market-brain/SPEC.md` | `market-brain/SKILL.md` | `market-brain/PROMPT.md` |
| Marketing Brain | `marketing/SPEC.md` | `marketing/SKILL.md` | `marketing/PROMPT.md` |
| Product Brain | `product/SPEC.md` | `product/SKILL.md` | `product/PROMPT.md` |
| Engineering Brain | `engineering/SPEC.md` | `engineering/SKILL.md` | `engineering/PROMPT.md` |

---

## Domain files

| File | Owner | Updated when |
|---|---|---|
| `../domains/markets.md` | Market Brain | Every Market Brain session |
| `../domains/content.md` | Marketing Brain | Every Marketing Brain session |
| `../domains/competitors.md` | Market Brain + Marketing Brain | Competitor audit sessions |
| `../domains/product.md` | Product Brain | Every Product Brain session |
| `../domains/eng.md` | Engineering Brain | Every Engineering Brain session |

---

## Connected agent loop

```
Market opportunity
→ Market Brain validates/drafts
→ Marketing Brain distributes
→ Product Brain prioritises fixes/features
→ Engineering Brain creates Replit prompts
→ Operator Brain decides what ships/promotes/fixes today
→ brain_update writes back to domain files
```

---

## Session run order

1. Operator loads `KASIRO_DOCTRINE.md` + `KASIRO_BRAIN.md`
2. Operator selects the relevant brain for today's task
3. Brain reads its domain file(s)
4. Brain executes the declared command
5. Brain returns: output artifact + handoffs + `brain_update` JSON
6. Operator decides whether to execute
7. Operator (or Cowork SKILL) writes `brain_update` back to the relevant domain file
8. Handoffs route to the next brain

---

## Execution mode

All agents run on-demand only. Scheduled checks allowed only for:
- Market close reminders for already-live markets
- Resolution checks for markets past event end
- Social post queue retries
- Failed autopost checks
- High-priority ops issue reminders

---

## Smoke tests

See `operator-brain/SMOKE_TESTS.md` for repeatable pass/fail tests across all 5 brains.
Run these after any agent SPEC update to verify cross-brain behaviour holds.
