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

## M1.3 — PDF-to-IDML candidate generator
**Status:** generator and synthetic structural smoke test committed; application verification partially observed.

Generate an IDML candidate from PDF-extracted text, with one text frame and story per page and paragraph groups inferred from geometry. Structural checks cover ZIP layout, XML well-formedness, and package references. These checks do not prove the package opens in InDesign or preserves visual fidelity. A real candidate was subsequently opened in DesignCraft and frame-width reflow was observed; direct text editing and round-trip save/reopen remain unverified.

## M1.4 — Open/edit/reflow test
**Status: partial pass in DesignCraft; see [M1.4 validation notes](../tests/validation/m1_4-designcraft-validation.md).**

A user-provided screenshot shows the candidate rendering and a selectable text frame. Narrowing the frame causes visible text to wrap. Application version, import warnings, direct text editing, and save/reopen behavior have not yet been recorded.

## M1.5 — Real benchmark evaluation
**Pending.**

Use local, permission-cleared benchmark files. Record rendering differences and text-structure quality independently. Never commit source documents, generated candidates, screenshots with private content, or recovered full text to this public repository.
