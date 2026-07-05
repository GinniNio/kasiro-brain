# Artifact Control Standard

**Version:** 1.0  
**Applies to:** presentations, spreadsheets, PDFs, proposals, runbooks, reports, images, and exported review copies.

## Directory model

```text
project/
  manifest.yaml
  source/
    PROJECT_MASTER.pptx
    PROJECT_MODEL_MASTER.xlsx
  exports/
    PROJECT_REVIEW.pdf
  evidence/
    verification.yaml
  archive/
    YYYY-MM-DD_vNN/
```

## Naming rules

1. One logical artifact has one canonical source filename.
2. `MASTER` identifies an editable canonical source, never an export.
3. `REVIEW` identifies a generated delivery or inspection copy.
4. Do not create duplicate files with `(1)`, `(2)`, `final`, `final-final`, or timestamps as the only differentiator.
5. Before replacing a canonical source, archive the prior version under its version directory.
6. Every delivered export must record the source version and source hash.

## Required manifest

```yaml
project: ""
artifact_family: ""
canonical_version: 1
status: draft|internal_review|approved|superseded|archived
canonical_sources:
  deck: ""
  model: ""
generated_outputs: []
source_hashes: {}
supersedes: []
consumes_decisions: []
consumes_assumptions: []
unresolved_items: []
verified_file: ""
verified_at: ""
```

## Release gates

An artifact may be marked `approved` only when:

- its canonical source is identified;
- all material numbers trace to a model, source, or assumption ID;
- unsupported factual claims are removed or cited;
- currencies, periods, denominators, and scenario labels agree;
- regulatory assumptions are visibly distinguished from confirmed positions;
- all pages or slides have been visually inspected;
- the exact delivered file has a completed proof-of-completion record.

## Supersession rule

A new version must state what it supersedes. Superseded files remain archived and must not be presented as current. File Library uploads are treated as review copies unless their manifest explicitly identifies them as canonical.

## Cross-artifact consistency

Use stable assumption IDs and decision IDs in models, decks, proposals, and briefs. A changed assumption requires checking every dependent artifact before approval.
