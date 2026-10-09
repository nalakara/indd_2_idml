# M1.6 — INDD binary probe checkpoint

**Status: exploratory probe executed; native object parsing not achieved.**

## Method

A read-only script was added at `experiments/m1-6-indd-binary-probe/indd_binary_probe.py`. It records:
- file size and SHA-256,
- printable ASCII runs and their offsets,
- occurrences of generic strings such as `STORY`, `SPREAD`, `PAGE`, `TEXT`, `FONT`, and `Frame`,
- coarse per-window entropy and printable-byte ratios.

It does not modify source files. The detailed JSON report was generated locally and is intentionally **not committed**, because the inputs are private benchmark documents and string inventories may expose their content.

## Results on three local INDD samples

The probe completed for all three files. Aggregate observations:

- File sizes ranged from approximately 1.5 MB to 3.8 MB.
- It found thousands of printable ASCII runs in each file.
- Generic marker strings appeared many times, including `PAGE` and `FONT`; `STORY`, `SPREAD`, `TEXT`, `Graphic`, and `Frame` also appeared.
- 4 KiB window entropy varied substantially within each file, from near-zero windows to windows around 7.8 bits per byte.

These results confirm that the files contain a mixture of readable metadata/text and non-text/binary regions. They **do not** establish that the marker occurrences are object records. Words like `PAGE`, `STORY`, and `FONT` can occur in metadata, resource names, or unrelated byte sequences. Entropy is descriptive only.

## Finding

This bounded probe did **not** identify stable object boundaries, object IDs, text-to-frame ownership, frame geometry, or story threading. Therefore it has not advanced the project to a native INDD parser.

The next useful experiment should be more targeted: inspect the bytes surrounding known text strings, compare the same structures across two files, and test whether a repeatable record boundary/reference pattern exists. Until that evidence appears, avoid building a parser around guessed offsets.

## Reproducibility

Run locally; do not publish the resulting report for private documents:

```bash
python3 experiments/m1-6-indd-binary-probe/indd_binary_probe.py \
  /path/to/sample-a.indd /path/to/sample-b.indd \
  --out ./private-output/indd-probe.json
```

To include recovered printable strings in the JSON, pass `--include-strings`. Treat that output as confidential and keep it out of version control.

## Gate decision

- Read-only probe runs: **pass**
- Stable semantic object records identified: **not demonstrated**
- Native INDD-to-IDML reconstruction: **still unproven**
- Recommended next step: targeted string-neighborhood and cross-file pattern analysis, with an explicit stop/reassess criterion.
