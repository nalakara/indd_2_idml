# M1.6b — Text-neighborhood analysis

**Status: readable text neighborhoods confirmed; semantic mapping still unproven.**

A second read-only experiment inspected byte neighborhoods around representative PDF-derived text tokens and generic marker words in three local INDD files.

## Findings

1. In the TR_PLAN sample, multiple product-list strings occur as contiguous printable ASCII sequences, separated by carriage-return bytes and interspersed with short binary-looking fields. This supports the earlier finding that some story-like text payloads may be recoverable from raw bytes.
2. In the Proposal Rise Up sample, Indonesian prose also appears in long printable sequences. Similar text is found at multiple offsets, so a raw occurrence cannot be assumed to be the unique authoritative story or the visible placement.
3. The generic word `SPREAD` appears in a context that reads as a plugin name (`Spread.InDesignPlugin`), while `FONT`, `Graphic`, and `Frame` also occur in plugin/resource-name contexts. This demonstrates why marker-word counts alone are not evidence of page/object records.
4. The inspected ASCII text did not appear as UTF-16LE for the sampled tokens; the observed text runs were ASCII-compatible. This is only a result for these token probes, not a complete encoding analysis.

## Interpretation

We have evidence for **text payload extraction candidates**, but not for native object parsing. The binary bytes around the text include repeated numeric-looking fields and control bytes, yet no reliable schema has been established for those fields. We cannot currently infer:
- which occurrence belongs to which story or page,
- whether a string is current, duplicated, stale, or hidden,
- original frame coordinates or dimensions,
- text style runs and paragraph-style references,
- threaded story relationships or object ownership.

## Next experiment

Build a private local report that groups contiguous printable runs, records neighboring bytes, and compares identical text neighborhoods across files. Keep recovered text out of public artifacts. Only promote a byte pattern into a parser hypothesis when it repeats across multiple documents and can be independently checked against the corresponding PDF or an application export.

**Gate remains unchanged:** no native INDD object graph or reliable direct INDD → IDML conversion has been demonstrated.
