#!/usr/bin/env python3
"""Synthetic smoke test for the M1.3 PDF-to-IDML candidate generator."""
import importlib.util
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
import fitz

SCRIPT = Path(__file__).resolve().parents[2] / "experiments" / "m1-3-pdf-to-idml" / "pdf_to_idml_candidate.py"
spec = importlib.util.spec_from_file_location("pdf_to_idml_candidate", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    pdf, out = tmp / "synthetic.pdf", tmp / "synthetic.idml"
    report = tmp / "synthetic.validation.json"
    doc = fitz.open()
    page = doc.new_page(width=595, height=842)
    page.insert_text((50, 60), "Synthetic paragraph one. It has enough text to act as an editable line.")
    page.insert_text((50, 100), "Synthetic paragraph two. A larger vertical gap should separate it.")
    doc.save(pdf)
    doc.close()

    result, pages = mod.build_package(pdf, out, report)
    assert result["zip_integrity"] == "PASS"
    assert result["xml_well_formed"] == "PASS"
    assert result["designmap_references"] == "PASS"
    assert result["text_frame_count"] == 1
    assert result["story_count"] == 1
    with zipfile.ZipFile(out) as z:
        assert z.namelist()[0] == "mimetype"
        assert z.getinfo("mimetype").compress_type == zipfile.ZIP_STORED
        story = ET.fromstring(z.read("Stories/Story_story1.xml"))
        assert len(story.findall(".//ParagraphStyleRange")) >= 1
        spread = ET.fromstring(z.read("Spreads/Spread_spread1.xml"))
        frame = spread.find(".//TextFrame")
        assert frame is not None and frame.get("ParentStory") == "story1"
    assert result["application_open_test"] == "NOT TESTED"
    print("PASS: synthetic PDF generated IDML candidate; ZIP/XML/references/frame-story checks passed.")
    print("NOTE: app-open/edit/reflow is not covered by this smoke test.")
