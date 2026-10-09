#!/usr/bin/env python3
"""Read-only INDD/PDF feasibility inspector for the INDD→IDML M0 experiment.

This tool does not modify inputs, does not create IDML, and does not claim to
reconstruct InDesign layout. It inspects the public INDD header convention,
printable strings, embedded XMP metadata, and optional PDF text overlap.
Uses Python standard library; pdfinfo/pdftotext are optional helpers.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

GUID = bytes.fromhex("0606edf5d81d46e5bd31efe7fe74b71d")
DB_TYPES = {
    b"DOCUMENT": "InDesign document/template container",
    b"BOOKBOOK": "InDesign book container",
    b"LIBRARY4": "InDesign library container",
    b"LIBRARY2": "Legacy InDesign library container",
}
VERSION_NAMES = {
    (1, 0): "InDesign 1.0", (1, 5): "InDesign 1.5", (2, 0): "InDesign 2.0",
    (3, 0): "InDesign CS", (4, 0): "InDesign CS2", (5, 0): "InDesign CS3",
    (6, 0): "InDesign CS4", (7, 0): "InDesign CS5", (7, 5): "InDesign CS5.5",
    (8, 0): "InDesign CS6", (9, 0): "InDesign CC", (10, 0): "InDesign CC 2014",
    (11, 0): "InDesign CC 2015", (12, 0): "InDesign CC 2017",
    (13, 0): "InDesign CC 2018", (14, 0): "InDesign CC 2019",
    (15, 0): "InDesign 2020", (15, 1): "InDesign 2020 (15.1)",
    (16, 0): "InDesign 2021", (17, 0): "InDesign 2022", (18, 0): "InDesign 2023",
    (19, 0): "InDesign 2024", (20, 0): "InDesign 2025", (21, 0): "InDesign 2026",
}
SIGS = {
    "PDF": b"%PDF-", "ZIP local header": b"PK\x03\x04",
    "JPEG": b"\xff\xd8\xff", "PNG": b"\x89PNG\r\n\x1a\n",
    "GIF87a": b"GIF87a", "GIF89a": b"GIF89a",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def detect_version(data: bytes) -> dict:
    result = {
        "guid_matches_known_indesign_guid": data[:16] == GUID,
        "database_type": None,
        "endian_flag": None,
        "major_version": None,
        "minor_version": None,
        "version_label": None,
    }
    if len(data) < 40:
        result["error"] = "File too small for the common InDesign header check."
        return result
    result["database_type"] = DB_TYPES.get(data[16:24], data[16:24].decode("latin1", "replace"))
    endian = data[24]
    result["endian_flag"] = endian
    if result["guid_matches_known_indesign_guid"] and data[16:24] in DB_TYPES:
        if endian == 1:
            major, minor = data[29], data[33]
        elif endian == 2:
            major, minor = data[32], data[36]
        else:
            result["error"] = f"Unrecognized object-stream endian flag: {endian}"
            return result
        result["major_version"] = major
        result["minor_version"] = minor
        result["version_label"] = VERSION_NAMES.get((major, minor), f"InDesign database version {major}.{minor}")
    return result


def ascii_runs(data: bytes, minimum: int = 4) -> list[str]:
    return [m.group().decode("latin1", "replace") for m in re.finditer(rb"[\x20-\x7e]{" + str(minimum).encode() + rb",}", data)]


def xmp_blocks(data: bytes) -> list[dict]:
    blocks = []
    start_re = re.compile(rb"<x:xmpmeta\b")
    close = b"</x:xmpmeta>"
    for m in start_re.finditer(data):
        end = data.find(close, m.start())
        if end < 0:
            continue
        raw = data[m.start():end + len(close)]
        item = {"offset": m.start(), "length": len(raw), "parsed": False}
        try:
            root = ET.fromstring(raw)
            def vals(local_name: str) -> list[str]:
                return sorted({el.text.strip() for el in root.iter() if el.tag.rsplit("}", 1)[-1] == local_name and el.text and el.text.strip()})
            item.update({
                "parsed": True,
                "creator_tools": vals("CreatorTool"),
                "create_dates": vals("CreateDate"),
                "modify_dates": vals("ModifyDate"),
                "metadata_dates": vals("MetadataDate"),
                "font_names": vals("fontName"),
                "font_families": vals("fontFamily"),
                "font_faces": vals("fontFace"),
                "document_ids": vals("DocumentID"),
                "original_document_ids": vals("OriginalDocumentID") + vals("originalDocumentID"),
            })
        except ET.ParseError as exc:
            item["parse_error"] = str(exc)
        blocks.append(item)
    return blocks


def run_command(args: list[str]) -> str | None:
    try:
        p = subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, errors="replace")
        return p.stdout
    except (OSError, subprocess.CalledProcessError):
        return None


def pdf_report(pdf_path: Path, indd_strings: list[str]) -> dict:
    data = pdf_path.read_bytes()
    info_text = run_command(["pdfinfo", str(pdf_path)]) if shutil.which("pdfinfo") else None
    text = run_command(["pdftotext", "-layout", str(pdf_path), "-"]) if shutil.which("pdftotext") else None
    info = {}
    if info_text:
        for line in info_text.splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                if k.strip() in {"Creator", "Producer", "CreationDate", "ModDate", "Pages", "Page size", "PDF version", "Encrypted"}:
                    info[k.strip()] = v.strip()
    if not info.get("Pages"):
        info["Pages"] = len(re.findall(rb"/Type\s*/Page\b", data)) or None
    result = {"path": str(pdf_path), "size_bytes": len(data), "sha256": sha256(data), "pdf_info": info,
              "pdftotext_available": text is not None}
    if text is not None:
        pdf_words = set(re.findall(r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)*", text.lower()))
        ind_words = set(re.findall(r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)*", " ".join(indd_strings).lower()))
        matched = pdf_words & ind_words
        result["text_overlap"] = {
            "unique_pdf_word_tokens": len(pdf_words),
            "unique_ascii_tokens_found_in_indd": len(matched),
            "overlap_ratio": round(len(matched) / len(pdf_words), 4) if pdf_words else None,
            "interpretation": "Text-token overlap only; not a measure of layout fidelity, object recovery, or editability.",
        }
    return result


def inspect(path: Path, pdf_path: Path | None = None) -> dict:
    data = path.read_bytes()
    strings = ascii_runs(data)
    xmp = xmp_blocks(data)
    signature_hits = {name: [m.start() for m in re.finditer(re.escape(sig), data)] for name, sig in SIGS.items()}
    signature_hits = {k: v for k, v in signature_hits.items() if v}
    latest_valid_xmp = next((x for x in reversed(xmp) if x.get("parsed")), None)
    result = {
        "input": {"path": str(path), "filename": path.name, "size_bytes": len(data), "sha256": sha256(data)},
        "header": detect_version(data),
        "raw_string_scan": {
            "ascii_runs_min_4_chars": len(strings),
            "distinct_ascii_word_tokens": len(set(re.findall(r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)*", " ".join(strings).lower()))),
            "contains_xml_plist_markers": b"<!DOCTYPE plist" in data,
            "xmp_block_count": len(xmp),
            "latest_parseable_xmp": latest_valid_xmp,
            "common_embedded_file_signatures": signature_hits,
            "caveat": "Signature scan is a heuristic; no hits do not prove that no embedded assets exist.",
        },
        "pdf_comparison": pdf_report(pdf_path, strings) if pdf_path else None,
        "scope_warning": "This is forensic inspection only. It does not parse INDD objects, reconstruct layout, or generate IDML.",
    }
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("indd", type=Path, help="Path to an INDD/INDT file")
    ap.add_argument("--pdf", type=Path, help="Optional matching PDF reference")
    ap.add_argument("--out", type=Path, help="Write JSON report to this path; stdout if omitted")
    ns = ap.parse_args()
    if not ns.indd.is_file():
        ap.error(f"INDD file not found: {ns.indd}")
    if ns.pdf and not ns.pdf.is_file():
        ap.error(f"PDF file not found: {ns.pdf}")
    result = inspect(ns.indd, ns.pdf)
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if ns.out:
        ns.out.write_text(rendered, encoding="utf-8")
        print(f"Wrote read-only audit report: {ns.out}")
    else:
        print(rendered, end="")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
