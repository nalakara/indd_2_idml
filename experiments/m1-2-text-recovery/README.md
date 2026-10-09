# M1.2 — PDF text structure recovery

`recovery_structure.py` produces a `recovery-structure.json` report of PDF text-region candidates, lines, bounding boxes, font metadata, and heuristic paragraph candidates.

```bash
python3 -m pip install pymupdf
python3 recovery_structure.py /path/to/reference.pdf --out ./out
```

This script is read-only with respect to the PDF. It does not parse INDD files and does not generate IDML. Keep output from private benchmarks untracked.
