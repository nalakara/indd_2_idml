#!/usr/bin/env python3
"""Read-only INDD binary structure probe.

This is deliberately an evidence collector, not an INDD parser. It records
header bytes, printable ASCII runs with offsets, recurring markers, and coarse
window statistics so that researchers can compare files without modifying them.
It never emits recovered document text unless --include-strings is explicitly
requested; default reports contain only string lengths and SHA-256 digests.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
from collections import Counter
from pathlib import Path

MARKERS = (
    b"DOCUMENT", b"STORY", b"SPREAD", b"PAGE", b"TEXT", b"Graphic",
    b"Frame", b"FONT", b"x:xmpmeta", b"Adobe InDesign",
)


def entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = Counter(data)
    n = len(data)
    return round(-sum((c / n) * math.log2(c / n) for c in counts.values()), 4)


def probe(path: Path, min_run: int = 6, window_size: int = 4096,
          include_strings: bool = False) -> dict:
    data = path.read_bytes()
    runs = []
    for match in re.finditer(rb"[\\x20-\\x7e]{" + str(min_run).encode() + rb",}", data):
        raw = match.group()
        item = {
            "offset": match.start(),
            "length": len(raw),
            "sha256": hashlib.sha256(raw).hexdigest(),
        }
        if include_strings:
            item["text"] = raw.decode("latin1", "replace")
        runs.append(item)

    markers = {}
    for marker in MARKERS:
        offsets = [m.start() for m in re.finditer(re.escape(marker), data, re.I)]
        if offsets:
            markers[marker.decode("ascii")] = {
                "count": len(offsets),
                "first_offsets": offsets[:32],
            }

    windows = []
    for start in range(0, len(data), window_size):
        block = data[start:start + window_size]
        windows.append({
            "offset": start,
            "length": len(block),
            "entropy_bits_per_byte": entropy(block),
            "printable_ascii_ratio": round(sum(32 <= b < 127 for b in block) / len(block), 4),
        })

    return {
        "file": path.name,
        "size_bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "header_hex_first_64_bytes": data[:64].hex(),
        "printable_ascii_run_count": len(runs),
        "printable_ascii_run_total_bytes": sum(r["length"] for r in runs),
        "markers": markers,
        "windows": windows,
        "ascii_runs": runs,
        "limitations": [
            "Printable strings and marker offsets are not semantic object records.",
            "Repeated words such as PAGE, STORY, and FONT may occur in metadata or resources.",
            "Window entropy and string offsets cannot establish object ownership, geometry, or reading order.",
            "No input bytes are modified; output is an exploratory report, not a parsed document model.",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("indd", type=Path, nargs="+", help="INDD files to inspect read-only")
    parser.add_argument("--out", type=Path, required=True, help="JSON output path")
    parser.add_argument("--min-run", type=int, default=6)
    parser.add_argument("--window-size", type=int, default=4096)
    parser.add_argument("--include-strings", action="store_true",
                        help="Include recovered printable text; keep resulting reports private")
    args = parser.parse_args()
    results = []
    for path in args.indd:
        if not path.is_file():
            parser.error(f"File not found: {path}")
        results.append(probe(path, args.min_run, args.window_size, args.include_strings))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps({"files": results}, indent=2) + "\\n", encoding="utf-8")
    print(f"Wrote read-only probe report for {len(results)} file(s): {args.out}")
    print("This report is not an INDD parse and does not prove object reconstruction.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
