#!/usr/bin/env python3
"""M1.2 heuristic PDF text-structure recovery prototype.

Read-only: extracts PDF text spans and estimates text-frame/paragraph candidates.
It does not read or modify INDD internals and does not generate IDML.
Requires: python3 -m pip install pymupdf
"""
from __future__ import annotations
import argparse, json, re
from pathlib import Path
import fitz

def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()

def span_line_key(span):
    b = span["bbox"]
    # Group spans on a common baseline, allowing minor font/baseline variation.
    return round((b[1] + b[3]) / 2, 1)

def extract_page(page):
    raw = page.get_text("dict", sort=True)
    blocks_out = []
    for block in raw.get("blocks", []):
        if block.get("type") != 0:
            continue
        lines = []
        for line in block.get("lines", []):
            spans = [s for s in line.get("spans", []) if norm(s.get("text", ""))]
            if not spans:
                continue
            text = norm("".join(s["text"] for s in spans))
            bbox = [
                min(s["bbox"][0] for s in spans), min(s["bbox"][1] for s in spans),
                max(s["bbox"][2] for s in spans), max(s["bbox"][3] for s in spans)
            ]
            heights = [max(0.1, s["bbox"][3]-s["bbox"][1]) for s in spans]
            lines.append({
                "text": text, "bbox": [round(v,2) for v in bbox],
                "font_names": sorted(set(s.get("font","") for s in spans)),
                "font_sizes_pt": sorted(set(round(float(s.get("size",0)),2) for s in spans)),
                "mean_height": round(sum(heights)/len(heights),2)
            })
        if not lines:
            continue
        # Preserve source block as a frame candidate. PDF block boundaries are
        # only a heuristic and are not proof of original InDesign text frames.
        lines.sort(key=lambda l: (l["bbox"][1], l["bbox"][0]))
        paras, current = [], []
        prev = None
        for line in lines:
            if prev is None:
                current = [line]
            else:
                gap = line["bbox"][1] - prev["bbox"][3]
                baseline_delta = line["bbox"][1] - prev["bbox"][1]
                typical_h = max(1.0, (line["mean_height"] + prev["mean_height"]) / 2)
                # A noticeably larger vertical gap is treated as a paragraph break.
                # Keep this conservative: PDF line spacing does not uniquely encode paragraphs.
                if gap > max(2.0, typical_h * 0.62) or baseline_delta > typical_h * 1.9:
                    paras.append(current)
                    current = [line]
                else:
                    current.append(line)
            prev = line
        if current:
            paras.append(current)
        para_objects = []
        for p in paras:
            txt = " ".join(x["text"] for x in p)
            para_objects.append({
                "text": norm(txt),
                "line_count": len(p),
                "bbox": [
                    round(min(x["bbox"][0] for x in p),2),
                    round(min(x["bbox"][1] for x in p),2),
                    round(max(x["bbox"][2] for x in p),2),
                    round(max(x["bbox"][3] for x in p),2)
                ]
            })
        blocks_out.append({
            "bbox": [round(v,2) for v in [
                min(l["bbox"][0] for l in lines), min(l["bbox"][1] for l in lines),
                max(l["bbox"][2] for l in lines), max(l["bbox"][3] for l in lines)
            ]],
            "line_count": len(lines),
            "paragraph_candidate_count": len(para_objects),
            "paragraphs": para_objects,
            "lines": lines
        })
    return blocks_out

def process(pdf_path: Path, out_dir: Path):
    doc = fitz.open(pdf_path)
    result = {
        "schema": "indd2idml.m1_2.recovery-structure.v1",
        "source_pdf": pdf_path.name,
        "page_count": len(doc),
        "coordinate_units": "PDF points, origin at top-left",
        "warning": "PDF blocks/paragraphs are heuristic candidates, not recovered InDesign frame/story structure.",
        "pages": []
    }
    for i, page in enumerate(doc):
        blocks = extract_page(page)
        result["pages"].append({
            "page_number": i+1,
            "width_pt": round(page.rect.width,2),
            "height_pt": round(page.rect.height,2),
            "frame_candidates": blocks,
            "summary": {
                "frame_candidate_count": len(blocks),
                "line_count": sum(b["line_count"] for b in blocks),
                "paragraph_candidate_count": sum(b["paragraph_candidate_count"] for b in blocks)
            }
        })
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir/"recovery-structure.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    return result

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    result = process(args.pdf, args.out)
    totals = [p["summary"] for p in result["pages"]]
    print(json.dumps({
        "pdf": args.pdf.name, "pages": len(result["pages"]),
        "frame_candidates": sum(x["frame_candidate_count"] for x in totals),
        "line_count": sum(x["line_count"] for x in totals),
        "paragraph_candidates": sum(x["paragraph_candidate_count"] for x in totals)
    }, indent=2))
if __name__ == "__main__":
    main()
