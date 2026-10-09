# M1.6c — Targeted native INDD recovery decision

**Decision: STOP the current native-binary-parser approach for now. This is a scoped stop, not proof that all possible reverse engineering is impossible.**

## Experiments performed

1. Identified the native file header and checked whether each sample is a ZIP, gzip, or SQLite container. The four tested samples are not directly readable as any of those formats.
2. Ran a read-only printable-string/marker probe on four local INDD files from multiple InDesign generations.
3. Examined byte neighborhoods around known text and generic markers.
4. Checked duplicate occurrences of known text. For example, several TR_PLAN strings occur in more than one region, which means a text match alone cannot establish which occurrence is the authoritative visible story.
5. Reviewed public ecosystem evidence for open-source native INDD parsers and IDML toolkits.

## Observed evidence

- The native files have an InDesign database signature and are not simple ZIP packages.
- Text is recoverable as printable byte runs in these samples.
- Generic marker strings such as `PAGE`, `STORY`, `SPREAD`, `FONT`, and `Frame` occur, but contextual inspection shows some terms occur inside plugin/resource/metadata names. Their presence is not proof of semantic object records.
- The text neighborhoods contain control bytes and numeric-looking fields, but no stable record schema or reference graph has been established.
- We have not identified reliable original text-frame coordinates, story ownership, style ranges, object IDs, or page-item relationships.
- Public IDML libraries parse the XML-based IDML format; their documentation does not claim to parse the proprietary native INDD binary format. Public references continue to describe native INDD reverse engineering as incomplete or difficult. See the repo's linked feasibility research and the current upstream documentation.

## Why the current route is stopped

Continuing to count strings, inspect entropy, or guess offsets would generate more observations without a demonstrated path to an object model. A parser built on those guesses would risk producing plausible but incorrect page/story/style associations.

**Do not build a production converter on the current binary-probe code.** Keep it as an evidence collector only.

## What is still viable

### Route A — PDF-assisted reconstruction (our code)

We have a minimal IDML candidate generated from PDF text. The user confirmed that DesignCraft opens it, allows selection of a text frame, and exhibits frame-width reflow; text editing was also demonstrated. The current generator does not preserve the original layout and styling, and it has not been shown to reconstruct native objects. This route can still be improved, but its acceptance criteria must distinguish:
- full-page visual preservation,
- editable/reconstructed text,
- original object-level editability.

A possible next engineering branch is to create an IDML document with a full-page PDF as a linked visual base and selectively reconstructed editable text. This requires a separate IDML graphic-placement prototype and a DesignCraft open test. It will not make all page objects individually editable.

### Route B — Existing converter as a benchmark

A third-party product, INDD2IDML, publicly claims local recovery from recognized INDD structure, matching PDFs, previews, and recovered text. It explicitly warns that full visual identity and complete object-level editability are not guaranteed. This is a useful comparison candidate, not evidence that we can reproduce its implementation.

### Route C — Native INDD parser

Resume only if new evidence becomes available: an existing compatible parser/library, a documented record format, more diverse controlled samples, or a reverse-engineering breakthrough that maps records to independently verified objects.

## Final gate

- **Native INDD parsing with our current experiments:** blocked / stop.
- **PDF-derived editable text IDML:** demonstrated as a limited prototype.
- **Original visual fidelity and object-level editability:** not yet achieved.
- **Recommended immediate path:** prototype PDF visual-page placement in IDML and test in DesignCraft; compare against the third-party converter if the user chooses to evaluate it.

Private source documents, raw string inventories, and neighborhood reports remain local and must not be committed to the public repository.
