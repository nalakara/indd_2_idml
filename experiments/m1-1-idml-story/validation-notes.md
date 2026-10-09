# M1.1 — Multi-paragraph IDML structure prototype

## Result

**PASS for structural checks; not yet validated by an InDesign-compatible application.**

- IDML package size: 4,737 bytes
- ZIP entries: 13
- XML files parsed successfully: 12
- One TextFrame points to Story `u1`
- Paragraph ranges in that Story: 3
- `mimetype` is first in the ZIP and stored without compression.

## What this proves

The prototype data model can represent multiple paragraph ranges in one Story associated with one TextFrame. It does not model one object per visible line.

## What this does not prove

- It is not a converter for the supplied INDD documents.
- It does not recover original frame geometry, styles, linked-frame chains, images, layers, or master-page relationships.
- XML parsing and ZIP validity do not guarantee that Adobe InDesign will open the package. The next required test is opening this file in InDesign or another IDML-compatible application and checking actual text reflow.

## Paragraph fixture

1. This is paragraph one. It is deliberately longer than a single line so that the frame can reflow the text.
2. This is paragraph two. It lives in the same story and the same text frame as paragraph one.
3. This is paragraph three. Editing the frame width should cause text to reflow rather than split each line into a separate object.

## Validation JSON

```json
{
  "idml_path": "/mnt/data/indd2idml-m1_1/M1_1_multi_paragraph_story.idml",
  "bytes": 4737,
  "sha256": "844b73a0da8a053ba1618fe04f18e3ab487d16d63f6606e97cd5ba65df6b51bb",
  "zip_entry_count": 13,
  "xml_files_parsed": 12,
  "mimetype_first_and_uncompressed": true,
  "story_paragraph_count": 3,
  "text_frame_count": 1,
  "frame_parent_story": "u1",
  "paragraph_texts": [
    "This is paragraph one. It is deliberately longer than a single line so that the frame can reflow the text.",
    "This is paragraph two. It lives in the same story and the same text frame as paragraph one.",
    "This is paragraph three. Editing the frame width should cause text to reflow rather than split each line into a separate object."
  ],
  "validation_scope": "ZIP structure and XML well-formedness plus multi-paragraph story relationship only; not validated by Adobe InDesign or another IDML renderer."
}
```
