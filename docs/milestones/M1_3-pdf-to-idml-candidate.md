# M1.3 — PDF-to-IDML Candidate Generator

## Purpose

Turn the PDF text-recovery work into a first IDML candidate that tests multi-paragraph text structure. This is the next technical gate, not the finished converter.

## Design choice

The prototype creates **one text frame and one story per PDF page**. PDF text is extracted and grouped into heuristic paragraph candidates. This is intentionally simpler than attempting to recreate every visual text region immediately: it tests whether page text can be represented in an editable story without a one-object-per-line model.

## Validation

The script checks:
- `mimetype` is the first ZIP member and is stored without compression;
- all XML files parse;
- every `src` reference in `designmap.xml` resolves to a package member;
- each page has one text frame and one corresponding story.

It does not test application opening, actual text editing, reflow, or visual fidelity.

## Known limitations

One frame per page will not reproduce the original page layout. Text order is heuristic, and PDF vertical spacing does not reliably identify paragraph breaks. Images, styles, fonts, tables, original frame boundaries, and linked stories are not reconstructed. The original INDD is not read.

## Run and test

```bash
python3 -m pip install pymupdf
python3 experiments/m1-3-pdf-to-idml/pdf_to_idml_candidate.py /path/to/reference.pdf --out ./out/candidate.idml
python3 tests/validation/test_m1_3_generator.py
```

## Required next test

Open a generated candidate in an IDML-capable application, check for warnings, edit text, resize the frame, and verify reflow. Record the application and version. If opening fails, treat that as the next blocker rather than claiming success from XML checks.
