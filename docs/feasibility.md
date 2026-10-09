# Feasibility Notes

## Current evidence

- M0 inspected the input files and confirmed that a raw printable-string scan is an incomplete view of the document.
- M1 compared case-insensitive unique PDF tokens against printable strings from INDD bytes. On the two private benchmark pairs, token presence was high (100% for the single-page benchmark; 99.54% for the five-page benchmark). This indicates recoverable text overlap only; it is not a measure of layout fidelity or editability.
- M1.1 created a small IDML package prototype containing one text frame linked to a story with three paragraphs. The package ZIP/XML structure passed local checks, but it has not been opened and tested in InDesign-compatible software.
- M1.2 extracted PDF text coordinates and estimated text-region/paragraph candidates from vertical spacing. The output is heuristic and is not a conversion result.

## Main unknowns

1. Can a minimal generated IDML package be opened reliably in a compatible application?
2. Does text in a single frame reflow as expected after resizing the frame?
3. Can PDF geometry be mapped to useful text frames without fragmenting text into one object per line?
4. How well can non-text objects, images, fonts, paragraph/character styles, and linked stories be reconstructed?
5. Is the result good enough to justify proceeding without access to InDesign's own export path?

## Decision gate

Do not call this a converter, publish fidelity claims, or freeze the native-app architecture until at least one generated IDML candidate opens, preserves multi-paragraph editing, and passes a controlled reflow test.
