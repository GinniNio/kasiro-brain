# Proof of Completion Protocol

**Version:** 1.0  
**Owner:** Operator Brain  
**Applies to:** code changes, configuration changes, data fixes, production releases, automation changes, and artifact corrections.

## Core rule

A change is complete only when the evidence required for its risk class has been collected and the observed result matches the acceptance criteria. File presence, a commit, an implementation claim, or a screenshot of unrelated state is insufficient.

## Status values

| Status | Meaning |
|---|---|
| `VERIFIED` | All required checks passed and evidence identifies the tested version. |
| `PARTIAL` | Some checks passed, but one or more required checks remain. |
| `FAILED` | At least one acceptance criterion failed. |
| `UNVERIFIABLE` | Required access, environment, credentials, data, or production evidence was unavailable. |
| `SUPERSEDED` | A later verification record replaces this one. |

## Evidence ladder

1. **Requirement evidence**: exact requirement and measurable acceptance criteria.
2. **Source evidence**: authoritative repository, branch, commit, file, configuration, or canonical artifact.
3. **Implementation evidence**: changed code, configuration, formula, copy, or data.
4. **Static evidence**: typecheck, lint, schema validation, formula audit, or link validation.
5. **Build evidence**: successful build or export from the tested version.
6. **Runtime evidence**: affected route, command, job, bot, API, workbook, or presentation behaves correctly.
7. **Production evidence**: deployed version and live behaviour, when the claim concerns production.
8. **Regression evidence**: adjacent critical flows remain functional.
9. **Trace evidence**: timestamp, commit/version, environment, tester, and result are recorded.

## Risk classes

### R0: Editorial

Examples: spelling, formatting, labels with no behavioural impact.

Required: 1, 2, 3, 5, 9.

### R1: Local behaviour

Examples: isolated UI component, non-critical report, internal script.

Required: 1 through 6, plus 9.

### R2: User-facing or financial

Examples: market activation, pricing, wallet, scoring, settlement, model outputs, executive financial claims.

Required: 1 through 9.

### R3: Security, compliance, or irreversible operations

Examples: authentication, secrets, payments, deletion, legal claims, regulatory gating.

Required: 1 through 9 plus explicit operator approval before release.

## Mandatory verification record

```yaml
claim: ""
project: ""
risk_class: R0|R1|R2|R3
status: VERIFIED|PARTIAL|FAILED|UNVERIFIABLE|SUPERSEDED
authoritative_source: ""
branch_or_version: ""
commit_or_artifact_hash: ""
environment: local|staging|production|artifact
acceptance_criteria:
  - criterion: ""
    result: pass|fail|blocked
    evidence: ""
checks:
  static: ""
  build: ""
  runtime: ""
  production: ""
  regression: ""
remaining_gap: ""
verified_by: ""
verified_at: ""
```

## Stop conditions

Mark `FAILED` or `UNVERIFIABLE`; do not claim completion when:

- the tested commit or artifact version is unknown;
- production cannot be distinguished from local or staging state;
- acceptance criteria are subjective or absent;
- a required environment variable, migration, secret, or external dependency cannot be inspected;
- only implementation evidence exists for a runtime claim;
- the test uses stale data or an obsolete artifact;
- the observed output conflicts with the source of truth.

## Artifact-specific checks

For presentations, spreadsheets, PDFs, and proposals:

- identify the canonical source artifact;
- verify linked model values against the assumptions registry;
- inspect every exported page or slide for clipping and overflow;
- identify unresolved placeholders, source notes, and regulatory caveats;
- record which previous versions are superseded;
- assign `VERIFIED` only to the exact delivered file.

## Engineering-specific checks

For application changes:

- run lint, typecheck, tests, and build when available;
- test the affected route or API with representative data;
- inspect logs for errors;
- verify database migrations and environment-variable names;
- test one adjacent critical flow;
- confirm the live deployment contains the tested commit before making a production claim.
