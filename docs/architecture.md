# Architecture Notes

## Intended pipeline

1. **Input inspection** — detect file type/version and gather safe metadata without modifying source files.
2. **Evidence extraction** — where a reference PDF exists, extract text, font/size clues, coordinates, and page geometry.
3. **Structure inference** — estimate text regions, paragraphs, image regions, and page-level relationships; label uncertain inferences explicitly.
4. **IDML assembly** — construct a ZIP package with design map, stories, spreads, text frames, style resources, and required metadata.
5. **Package validation** — validate ZIP ordering/contents, XML well-formedness, referenced component paths, and internal IDs.
6. **Application validation** — open in compatible desktop-publishing software; edit text, resize frames, and test reflow.
7. **Fidelity evaluation** — render output to PDF/images and compare with the reference, while separately measuring text structure/editability.

## Key design rule

Keep evidence separate from inference. For example, a PDF text block is evidence of text coordinates grouped by the PDF exporter; it is not proof of an original InDesign text frame.

## Candidate technology direction

The earlier concept was a native macOS app with a SwiftUI front end and a Rust conversion engine. This remains provisional. Converter feasibility and IDML package validation must pass before the implementation stack is frozen.

## Data safety

- Treat source files as immutable inputs.
- Write generated files to a separate output location.
- Do not overwrite source files.
- Batch conversion should preserve original names, avoid collisions, and report per-file failures.
- Private benchmark files and derived full-text maps remain local and untracked.
