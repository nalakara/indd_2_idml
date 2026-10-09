# M0 — Feasibility Inspection

M0 was an exploratory, read-only inspection of INDD/PDF sample pairs. The aim was to decide whether the inputs offered enough evidence to attempt reconstruction.

## Findings

- Raw byte scans can reveal some printable strings, but they do not decode the full InDesign document model.
- Metadata and token presence are useful diagnostics, not a reconstruction strategy.
- The source documents and paired PDFs are retained as private local benchmarks and are intentionally not included in this public repository.

## Outcome

Proceed to controlled prototypes, keeping original inputs untouched. Require a separate application-opening/editability test before declaring IDML generation successful.
