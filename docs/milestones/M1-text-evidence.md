# M1 — Text Evidence Probe

M1 compared unique tokens extracted from reference PDFs against printable strings scanned from raw INDD bytes.

## Benchmark summary

- Single-page benchmark: 68 unique PDF tokens; all were found in the INDD printable-string scan.
- Five-page benchmark: 433 unique PDF tokens; 431 were found (99.54%).
- The benchmark files are private and their contents are intentionally not stored in this repository.

## Interpretation

These results show high overlap for this specific token scan. They do not establish visual fidelity, object structure, formatting retention, or IDML editability. Case-insensitive token overlap can conceal errors such as text order, missing line breaks, and incorrect frame relationships.
