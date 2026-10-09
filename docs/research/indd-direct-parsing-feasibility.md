# INDD Direct-Parsing Feasibility Audit

**Date:** 2026-10-09  
**Status:** Research checkpoint — direct INDD object reconstruction remains unproven.

## Decision summary

Do not treat printable-string extraction as an INDD parser. The current prototype can detect readable text and metadata, but has not recovered the native object graph needed to reconstruct text frames, stories, typography, placed assets, layers, or geometry reliably.

The best next engineering step is a bounded read-only parser spike against local benchmark files, not UI work and not a claim of full conversion. Continue to preserve source files and write outputs only to a separate directory.

## Evidence from our existing local audit

The prior M0 audit recorded that:
- Both inspected INDD samples expose substantial readable text in printable strings.
- Their headers and XMP metadata identify InDesign generations.
- The audit did not recover semantic page objects, frame geometry, story relationships, placed-asset links, or a valid IDML package directly from the INDD bytes.
- The paired PDFs provide positioned text and geometry clues, but those are proxies, not proof of original InDesign object boundaries.

Token overlap is a text-presence diagnostic only. It must not be presented as layout fidelity, editability, or conversion accuracy.

## External format research

- Adobe describes INDD as its native InDesign document format and lists IDML as a supported interchange format. The native INDD format is not documented as a simple open XML package. See [Adobe's INDD overview](https://www.adobe.com/in/creativecloud/file-types/image/vector/indd-file.html) and [supported formats](https://helpx.adobe.com/indesign/desktop/get-started/system-and-product-info/supported-file-formats.html).
- The IDML specification describes IDML as an XML representation of InDesign documents, including text and graphic frames, stories, and other layout data. See the [IDML File Format Specification mirror](https://community.adobe.com/havfw69955/attachments/havfw69955/indesign/632652/1/idml-specification.pdf).
- Public libraries such as [valkyoth/indesign-idml](https://github.com/valkyoth/indesign-idml) parse and generate IDML. They are useful downstream for validating or editing generated IDML, but their stated scope is IDML, not a native INDD binary parser.
- Adobe community guidance characterizes parsing native INDD without InDesign as a substantial reverse-engineering task and recommends IDML where available: [Adobe Community discussion](https://community.adobe.com/questions-671/is-it-poissible-to-read-andwrite-data-from-a-document-without-opening-indeisgn-in-net-framework-c-842826).

This research did not establish a mature, broadly validated open-source parser that reconstructs native INDD object structure across document generations. That is a research finding, not proof that no such implementation exists.

## Recommended bounded spike

1. Keep the current string/XMP scanner read-only and label its outputs as evidence, not a parsed document model.
2. Inspect binary structure systematically: header/version markers, object/chunk boundaries, repeated record patterns, and any references to text or resources. Avoid assuming that printable strings retain reading order or object ownership.
3. Test whether the same candidate object records can be identified across more than one INDD generation using local, permission-cleared samples.
4. Compare any inferred text/frame/object relationships against the matching PDF and screenshots, recording confidence and ambiguity.
5. Stop or reassess if the spike cannot recover stable object relationships without document-specific heuristics. In that case, keep the product scope explicitly PDF-assisted and distinguish editable reconstructed text from flattened visual content.

## Architecture implication

Keep two separate paths until evidence justifies combining them:

- **Native INDD recovery:** exploratory; no stable object parser demonstrated yet.
- **PDF-assisted reconstruction:** current prototype; text can be turned into editable frames, but original frame/story/style relationships are inferred or lost.

A hybrid route may use a PDF page as a visual base while overlaying reconstructed editable text, but this creates a serious trade-off: text may be duplicated or visually flattened, and overlay alignment may be imperfect. Do not choose that route without a clear policy and visual tests.

## Product acceptance rules

- Report visual preservation, editable text, native object editability, and missing assets/fonts as separate dimensions.
- Do not claim 80–90% fidelity until a rendered comparison is defined and measured.
- Do not describe a visually accurate flattened page as fully editable.
- Keep all private benchmark files, generated IDMLs, extracted full text, and private screenshots out of the public repository.
