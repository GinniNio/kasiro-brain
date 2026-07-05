# Workspace Operator Skill

## Purpose

Route work to the correct source, preserve decisions, control artifact versions, and require evidence before a task is marked complete.

## Load order

1. `ops/WORKSPACE_MANIFEST.yaml`
2. `ops/DECISIONS.yaml`
3. Project-specific doctrine and domain files
4. `ops/ARTIFACT_CONTROL.md` for document, deck, spreadsheet, PDF, or image tasks
5. `ops/PROOF_OF_COMPLETION.md` before reporting completion

## Invocation

Use this skill when a task spans sessions, repositories, local folders, File Library artifacts, deployments, agents, or generated deliverables.

## Procedure

### 1. Route

Declare:

```yaml
project: ""
task_type: analysis|implementation|artifact|release|verification|automation
authoritative_source: ""
branch_or_version: ""
production_target: ""
write_back_destination: ""
verification_level: R0|R1|R2|R3
```

Stop and mark `UNVERIFIABLE` when the authoritative source cannot be accessed and a lower-precedence source would materially change the answer.

### 2. Compile constraints

Read all locked decisions that apply to the project and task surface. Include prohibited interpretations and language. Resolve conflicts using the newest locked decision unless a higher-authority project doctrine says otherwise.

### 3. Execute

Perform the work against the declared source. Do not silently create another canonical copy. Record new durable decisions as proposed entries for operator approval.

### 4. Verify

Apply `ops/PROOF_OF_COMPLETION.md`. A commit, generated file, implementation response, or screenshot alone does not establish completion.

### 5. Write back

Update the declared destination with:

- changed project state;
- new or superseded decisions;
- artifact manifest changes;
- verification record;
- unresolved blockers.

## Output contract

```yaml
workspace_operator_result:
  project: ""
  routed_source: ""
  decisions_applied: []
  work_completed: []
  files_changed: []
  verification_status: VERIFIED|PARTIAL|FAILED|UNVERIFIABLE
  evidence: []
  decisions_proposed: []
  unresolved: []
  write_back_completed: true|false
```

## Hard stops

- Do not call an uploaded copy canonical unless its manifest says so.
- Do not treat chat memory as stronger than repository or production evidence.
- Do not claim a live fix from source-code inspection alone.
- Do not approve a financial artifact with untraced material numbers.
- Do not add another agent when the observed gap is source routing, verification, version control, or orchestration.
