# M1.1 — Multi-paragraph Story Prototype

## Goal

Test a basic IDML data model in which a single text frame references one story containing multiple paragraph style ranges. This avoids designing the converter around the flawed assumption that one visual line should become one independent text object.

## Prototype

A synthetic IDML package was generated with one page, one text frame, and one story containing three paragraphs.

## Validation performed

- ZIP package readability and entry listing.
- XML well-formedness / structural inspection of the package components.
- Inspection confirmed the text frame's `ParentStory` reference and three paragraph style ranges in that story.

## Not yet validated

The package has not been opened in Adobe InDesign or another IDML-compatible application. Therefore, application-level validity, editing, and reflow remain unknown. The fixture should not be treated as proof that a converter works.
