# Kasiro Market Brain — Cowork Skill

**Trigger phrases:** "run market brain", "open market session", "market brain", "scan for markets", "audit the board", "draft a market", "price a market", "market pipeline"

---

## Session setup

When this skill is invoked:

1. **Read these files in order:**
   - `KASIRO_BRAIN.md` (from kasiro-brain workspace folder)
   - `domains/markets.md`
   - `domains/competitors.md`
   - `agents/market-brain/SPEC.md`

2. **Confirm loading to operator:**
   > Market Brain loaded. Brain files read: KASIRO_BRAIN.md, domains/markets.md, domains/competitors.md.
   > Current wave state: [pull from domains/markets.md]
   > What kind of session is this? (full scan / board audit / rapid draft / pricing review / other)

3. **Run the session** following all rules in `agents/market-brain/SPEC.md`

4. **At session end**, produce the full JSON output block including `brain_update`

5. **Write back to brain** — update `domains/markets.md` with the `brain_update` contents:
   - Update current wave state
   - Append to `rejected_ideas_to_carry_forward`
   - Append any new learnings to Key Learnings section

6. **git commit** the changes with message: `market-brain: [session_type] [YYYY-MM-DD]`

---

## What this agent does

Market Brain scans for new prediction market candidates, audits the live board, prices markets against public benchmarks, and drafts admin-ready market field JSON. All output is advisory — the operator reviews and publishes.

**The agent never:**
- Proposes markets without first web-searching the event
- Invents probabilities without stating the benchmark source
- Proposes markets for events that have already happened
- Produces a batch >4 without applying the stagger rule

---

## Cross-domain reads (load when task requires)

| Task | Also read |
|---|---|
| Content strategy for market launches | `domains/content.md` |
| Competitive deep-dive | `domains/competitors.md` (already loaded) |
| Product prioritisation discussion | `domains/product.md` |
