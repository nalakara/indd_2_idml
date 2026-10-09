# M1.4 — Open/edit/reflow validation

**Status: partial pass — DesignCraft visual open and frame reflow observed; text editing and application/version details not yet recorded.**

## Test target

- Candidate: local `TR_PLAN_candidate.idml`, generated from the private `TR_PLAN.pdf` benchmark.
- Application: DesignCraft (ArtCraft).
- Application version / platform: not recorded.
- Source document and candidate remain local; neither is included in this public repository.

## Observations from user-provided screenshots

1. The candidate was opened and rendered by DesignCraft.
2. A text frame could be selected; the application displayed a bounding box and resize handles.
3. After the frame width was reduced, the heading `BUKA ONLINE SHOP` wrapped onto two lines and long text near the bottom wrapped to additional lines.
4. This is evidence that the displayed text participates in frame-width reflow.

## What this does and does not prove

- **Observed:** candidate opens and renders in DesignCraft; a text frame can be selected; visible text reflows when the frame narrows.
- **Not yet verified:** direct text editing; whether all content is present; whether paragraphs and story boundaries match the intended structure; whether the app showed import warnings; repeatability across documents.
- **Not measured:** visual fidelity against the source INDD/PDF.
- **Not demonstrated:** end-to-end conversion from INDD. The candidate was generated from PDF text and geometry, not from the original INDD object model.

## Next checks

1. Edit a short phrase in the frame and confirm the change persists.
2. Save, close, and reopen the candidate to check round-trip stability.
3. Repeat the open/edit/reflow test on the second private benchmark.
4. Compare source and candidate separately for content completeness, frame/story structure, and visual similarity.

Do not commit source files, candidate IDMLs, screenshots containing private document content, or extracted full text.
