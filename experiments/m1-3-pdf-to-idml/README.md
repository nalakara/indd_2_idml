# M1.3 — PDF → IDML candidate generator

This experimental generator reads a PDF (not INDD) and creates a minimal IDML candidate. It uses a single editable text frame and story per page, with heuristic paragraph candidates derived from vertical gaps between PDF lines.

## Run

```bash
python3 -m pip install pymupdf
python3 experiments/m1-3-pdf-to-idml/pdf_to_idml_candidate.py /path/to/reference.pdf --out ./out/candidate.idml
```

The validation report defaults to `candidate.validation.json`.

## Limitations

- Does not parse `.indd` files and is not an INDD → IDML converter.
- Uses PDF-extracted text only; it does not reconstruct images, typography, styles, tables, layers, original text frames, or linked stories.
- One frame per page deliberately loses original layout. This is an editability/reflow experiment, not a visual-fidelity attempt.
- ZIP/XML validation does not prove that the output opens in InDesign. Application validation remains required.
