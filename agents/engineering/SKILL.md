# Kasiro Engineering Agent — Cowork Skill

**Trigger phrases:** "run engineering", "engineering session", "write a replit prompt", "diagnose this bug", "architecture review", "code audit", "performance audit", "security audit", "phase spec", "implement this feature"

---

## Session setup

When this skill is invoked:

1. **Read these files in order:**
   - `KASIRO_BRAIN.md` (from kasiro-brain workspace folder)
   - `domains/eng.md`
   - `agents/engineering/SPEC.md`
   - `C:\Dev\Kasiro\replit.md` (always — non-negotiable)

2. **Confirm loading to operator:**
   > Engineering agent loaded. replit.md + engineering guardrails read.
   > What kind of session is this? (bug diagnosis / Replit prompt / architecture review / phase spec / code audit / other)
   > If bug: describe the bug and any error messages or logs you have.

3. **Run the session** following all rules in `agents/engineering/SPEC.md`

4. **At session end**, produce the full JSON output block including `brain_update`

5. **Write back to brain** — update `domains/eng.md` with the `brain_update` contents:
   - Update open engineering items
   - Append any new incidents or guardrail violations found
   - Append any new guardrails or learnings

6. **git commit** the changes with message: `engineering: [session_type] [YYYY-MM-DD]`

---

## What this agent does

The Engineering agent diagnoses bugs, writes Replit agent prompts, and produces architecture specs and code audits. All output is ready-to-paste Replit prompts — the operator pastes and verifies.

**Critical guardrails enforced in every session:**
- AMM math must use `poolsAfterBuy`/`poolsAfterSell` from `server/amm.ts` — never inline
- Always branch on `mechanicsType` (AMM vs parimutuel) — never collapse
- Always explicit column selection — never `select *`
- Auto-lock must atomically clear `feature`/`featured_rank`
- Schema changes via `npm run db:push` — never raw DDL

**The agent never:**
- Writes directly to production files (outputs Replit prompts for the operator to paste)
- Suggests inline AMM math
- Collapses the mechanicsType branch
- Recommends `select *` queries
