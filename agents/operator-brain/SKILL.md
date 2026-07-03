# Operator Brain — Cowork Skill
**Skill name:** kasiro-operator | **Version:** 1.1 | **Last updated:** 2026-07-03

---

## What this skill does

Runs a Kasiro Operator Brain session in Cowork. Loads the brain files, reads current state, and produces the daily operating board or requested ops output. Writes brain_update back to domain files at session end.

---

## Session Setup (run in order)

### Step 1 — Load shared doctrine

Read: `KASIRO_DOCTRINE.md`

This file has 15 rules that override everything else. Do not proceed without reading it.

### Step 2 — Load brain state

Read: `KASIRO_BRAIN.md`

This is the master index. Read it for agent directory, domain files, shared state tables, and what is dead/archived.

### Step 3 — Load domain files

Read all:
- `domains/markets.md`
- `domains/content.md`
- `domains/product.md`
- `domains/eng.md`

### Step 4 — Load Operator Brain spec

Read: `agents/operator-brain/SPEC.md`

This file has the commands, daily output format, hard gates, and priority logic. Follow it exactly.

### Step 5 — Run the session

Operator declares a command. Produce output following the SPEC.

Available commands:
- `/ops today` — daily operating board
- `/ops weekly-plan` — 7-day focus
- `/ops risk-check` — current trust/money/data risks
- `/ops publish-promote-fix` — condensed action list
- `/ops review-queue` — social queue, approval queue, pending market drafts

### Step 6 — Write brain_update back

At session end, produce the brain_update JSON block (format in SPEC.md).

Write the update to: `domains/product.md` (append to "Recent decisions" section)

If the session contains market board decisions, also write to: `domains/markets.md`

If the session contains social queue decisions, also write to: `domains/content.md`

Commit message suggestion: `ops: [date] [session_type] brain_update`

---

## Notes

- This skill requires the kasiro-brain folder to be mounted as the workspace in this Cowork session.
- If brain files are not found, ask the operator to mount the kasiro-brain folder.
- If domain files are stale (last_updated > 7 days ago), note it in the session output.
- Operator Brain is advisory — it produces a board, not commands. The operator executes.
