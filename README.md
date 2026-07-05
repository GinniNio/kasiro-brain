# kasiro-brain

Private knowledge base, agent system, and operating-control layer for Kasiro and related operator workflows.

## What this is

A second brain and a set of AI agents for the Kasiro operator. The brain holds persistent knowledge about Kasiro: product state, market intelligence, competitor snapshots, engineering rules, content decisions, source routing, artifact control, and completion evidence. Agents read the brain to execute tasks and write back when state changes.

## Structure

```text
kasiro-brain/
├── KASIRO_BRAIN.md
├── KASIRO_DOCTRINE.md
├── ops/
│   ├── WORKSPACE_MANIFEST.yaml  ← source precedence and project routing
│   ├── DECISIONS.yaml           ← durable cross-project decision ledger
│   ├── ARTIFACT_CONTROL.md      ← canonical file and version rules
│   └── PROOF_OF_COMPLETION.md   ← evidence required before completion claims
├── domains/
│   ├── markets.md
│   ├── content.md
│   ├── competitors.md
│   ├── product.md
│   └── eng.md
└── agents/
    ├── workspace-operator/
    │   └── SKILL.md             ← routes sources, compiles constraints, verifies work
    ├── operator/
    ├── market-brain/
    ├── marketing/
    ├── product/
    └── engineering/
```

## Mandatory task sequence

For work that spans sessions, repositories, local folders, File Library artifacts, production, or generated deliverables:

1. Load `agents/workspace-operator/SKILL.md`.
2. Route the task through `ops/WORKSPACE_MANIFEST.yaml`.
3. Apply locked entries from `ops/DECISIONS.yaml`.
4. Apply `ops/ARTIFACT_CONTROL.md` for decks, spreadsheets, PDFs, reports, proposals, or images.
5. Apply `ops/PROOF_OF_COMPLETION.md` before claiming that work is complete.
6. Write durable state changes back to the declared source of truth.

## Agent use

### From Cowork

Invoke the relevant skill by name. The skill loads `KASIRO_BRAIN.md`, its domain files, and the shared control layer when applicable. Each session returns or commits a state update.

### From chat

Open the relevant `PROMPT.md`, copy its contents into the session, and return the resulting `brain_update` to the mounted repository. Cross-session work should also include the Workspace Operator output contract.

## Source rules

- `ops/WORKSPACE_MANIFEST.yaml` defines which repository, production environment, artifact, or local path is authoritative.
- Production observations describe deployed state. Repository sources describe intended implementation. Conflicts must be recorded.
- Uploaded files and File Library copies are review copies unless a manifest explicitly marks them canonical.
- Chat memory is never stronger than repository, production, decision-ledger, or canonical-artifact evidence.
- Inaccessible sources are marked `UNVERIFIABLE`; they are not reconstructed from assumptions.

## Updating the brain

| Trigger | Action |
|---|---|
| Agent session changes durable state | Commit the relevant domain or decision file |
| Chat session returns a `brain_update` | Review and write it into the authoritative repository |
| A decision changes | Add or supersede an entry in `ops/DECISIONS.yaml` |
| An artifact becomes canonical | Update its project manifest and archive the prior version |
| A fix is reported complete | Add a proof-of-completion record with tested version and evidence |

## Cross-machine setup

1. Clone the authoritative repositories on each machine.
2. Mount the cloned workspace.
3. Install the required `SKILL.md` files.
4. Pull before starting work.
5. Route the task using `ops/WORKSPACE_MANIFEST.yaml`.
6. Commit every approved write-back with a descriptive message.

## Rules

- Only the operator approves durable brain changes and production actions.
- Every write-back is traceable to a commit or canonical artifact version.
- Domain files remain the source of truth for Kasiro domain state; `KASIRO_BRAIN.md` is the index.
- A code change, generated file, or implementation claim is not proof that the task is complete.
- Do not add another agent when source routing, verification, artifact control, or orchestration is the actual gap.
