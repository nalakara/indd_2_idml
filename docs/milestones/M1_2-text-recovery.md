# M1.2 — PDF Text Structure Recovery

## Goal

Extract text geometry from a reference PDF and build candidate text regions and paragraph groupings for future IDML reconstruction.

## Result summary

- Single-page benchmark: 32 PDF text-region candidates containing 35 extracted lines.
- Five-page benchmark: 138 PDF text-region candidates containing 324 extracted lines.
- These counts are drawn from local private benchmarks; no extracted text or recovery map is included in the repository.

## Method

The script extracts PDF text blocks and spans using PyMuPDF. It records text, bounding boxes, font names, and font sizes, then estimates paragraph boundaries from vertical gaps.

## Limitations

- PDF block grouping is not proof of original InDesign text frames.
- Vertical spacing is only a heuristic for paragraph breaks.
- The script does not parse INDD internals.
- It does not generate IDML.

## Next gate

Use these candidate regions to build an IDML page/story/frame package and then open it in compatible software to test editing and reflow.
