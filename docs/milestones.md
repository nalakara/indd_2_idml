# Milestone Plan

## M0 — Feasibility inspection
**Status:** initial audit completed.

Inspect source types, safe metadata, and raw printable strings. Do not infer document structure from metadata alone.

## M1 — Text evidence probe
**Status:** audit prototype completed.

Compare unique PDF tokens with printable ASCII strings in the corresponding INDD bytes. The score is a token-presence diagnostic only.

## M1.1 — Multi-paragraph IDML story
**Status:** prototype generated, application verification pending.

Generate a minimal IDML package with a single text frame linked to a story that contains several paragraph style ranges. Gate: open the package in compatible software and test editing/reflow.

## M1.2 — PDF text structure recovery
**Status:** heuristic prototype completed.

Extract PDF text spans/lines, bounding boxes, font metadata, text-region candidates, and tentative paragraph groups. Do not treat inferred PDF block boundaries as original InDesign frame boundaries.

## M1.3 — Recovery map to IDML candidate
**Next.**

Build an IDML candidate using inferred pages, frame bounds, and multi-paragraph stories. Preserve uncertainties in a machine-readable report.

## M1.4 — Open/edit/reflow test
**Pending.**

Confirm that the document opens, contains one frame with multiple paragraphs, and reflows after a frame-width change. Record the application/version used and any warnings.

## M1.5 — Real benchmark evaluation
**Pending.**

Use local, permission-cleared benchmark files. Record rendering differences and text-structure quality independently. Never commit source documents or recovered full text to this public repository.
