# INDD → IDML

**Status: research prototype. Not a working converter.**

This repository investigates whether an InDesign `.indd` document can be reconstructed into an editable `.idml` package without requiring Adobe InDesign to be installed.

## Project goal

Explore a PDF-assisted recovery pipeline that aims to produce an editable IDML document while retaining useful visual similarity and text structure—especially multi-paragraph text frames and text reflow.

The current prototypes are separate research tools. **No end-to-end INDD → IDML conversion of a real source document has been demonstrated or validated.**

## Milestones

| Milestone | Scope | Status |
|---|---|---|
| M0 | Inspect inputs and assess feasibility | Initial inspection completed |
| M1 | Compare PDF tokens with printable strings in INDD bytes | Audit prototype completed; token overlap is not a fidelity metric |
| M1.1 | Generate a minimal IDML package with a multi-paragraph story and text frame | Prototype generated; not verified in InDesign-compatible software |
| M1.2 | Estimate text regions and paragraph groups from PDF geometry | Heuristic prototype completed |
| M1.3 | Convert recovery structure into a page/story/frame IDML candidate | Next |
| M1.4 | Verify opening, text editing, and reflow in IDML-capable software | Pending |
| M1.5 | Measure visual and structural fidelity against source benchmarks | Pending |

## Repository layout

- `docs/` — feasibility notes, architecture, and milestone gates.
- `experiments/` — isolated prototypes for each research stage.
- `tests/fixtures/` — synthetic or explicitly redistributable fixtures only.
- `tests/validation/` — validation checks and test notes.
- `src/` — reserved for the converter implementation after feasibility gates pass.

## Important limitations

- INDD is a proprietary, complex document format. Printable strings and basic file metadata cannot reconstruct its complete object model.
- A PDF can provide visible text, geometry, and layout clues, but does not reliably preserve original InDesign text-frame boundaries, story threading, styles, layers, or editable object relationships.
- The M1.2 prototype estimates PDF text-region and paragraph candidates using geometry heuristics. They are **not** the original InDesign structures.
- A ZIP archive with well-formed XML is not proof that an IDML document opens correctly or is editable.
- Visual similarity and editability must be tested and reported separately.

## Run the PDF recovery prototype

Python 3.10+ recommended.

```bash
python3 -m pip install pymupdf
python3 experiments/m1-2-text-recovery/recovery_structure.py /path/to/reference.pdf --out ./out
```

This writes a `recovery-structure.json` report to the selected output directory. It does not read the INDD file and does not generate IDML.

## Data hygiene

Do not commit private/customer `.indd` or `.pdf` documents, extracted text, or recovery maps from confidential documents into this public repository. Keep benchmark source files local and untracked. The scripts should read original inputs without modifying them and write outputs elsewhere.

## Licence

A licence has not been selected yet. Until one is added, do not assume the repository is licensed for reuse.
