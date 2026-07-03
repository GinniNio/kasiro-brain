# kasiro-brain

Private knowledge base and agent system for Kasiro (kasiro.app).

## What this is

A second brain and a set of AI agents for the Kasiro operator. The brain holds persistent knowledge about Kasiro — product state, market intelligence, competitor snapshots, engineering rules, content decisions. The agents read the brain to execute tasks and write back to it when something changes.

## Structure

```
kasiro-brain/
├── KASIRO_BRAIN.md          ← master index + cross-domain summary
├── domains/
│   ├── markets.md           ← market intelligence, pipeline state, rejected ideas
│   ├── content.md           ← brand voice, channel rules, content calendar state
│   ├── competitors.md       ← live snapshots of Bayse, 2sabi, Wysemarket, globals
│   ├── product.md           ← decisions, open items, conversion strategy, roadmap
│   └── eng.md               ← tech stack, AMM rules, engineering guardrails
└── agents/
    ├── market-brain/
    │   ├── SPEC.md           ← full behavioral specification
    │   ├── SKILL.md          ← Cowork skill invocation file
    │   └── PROMPT.md         ← self-contained chat prompt (no file dependencies)
    ├── marketing/
    │   ├── SPEC.md
    │   ├── SKILL.md
    │   └── PROMPT.md
    ├── product/
    │   ├── SPEC.md
    │   ├── SKILL.md
    │   └── PROMPT.md
    └── engineering/
        ├── SPEC.md
        ├── SKILL.md
        └── PROMPT.md
```

## How to use

### From Cowork
Invoke the skill by name. The skill auto-loads `KASIRO_BRAIN.md` and its domain file, runs the session, and writes back any changes at session end.

### From chat (claude.ai or any interface)
Open the agent's `PROMPT.md`, copy the full contents, paste at the start of a chat session. At session end, the agent returns a `brain_update` block. Bring that block back to Cowork and say "update the brain with this."

## Updating the brain

| Trigger | How |
|---|---|
| After a Cowork agent session | Agent writes back automatically |
| After a chat session | Paste the agent's `brain_update` block into Cowork, say "update the brain" |
| Ad-hoc realisation | Tell Cowork directly: "update the brain — we decided X" |

## Cross-machine setup

1. Clone this repo on each machine
2. Mount the cloned folder as a Cowork workspace folder
3. Install each agent's `SKILL.md` as a Cowork skill once per machine
4. `git pull` keeps brain + specs current across machines

## Rules

- Only the operator updates the brain — never an agent acting alone in production
- Every agent write-back is a git commit with a descriptive message
- Domain files are the source of truth; KASIRO_BRAIN.md is the index
- Agents read their own domain file + KASIRO_BRAIN.md index; they load other domain files only when the task requires cross-domain context
