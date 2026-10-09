#!/usr/bin/env python3
"""M1.3 experimental PDF-to-IDML candidate generator.

This is a reconstruction experiment, not an INDD parser or production converter.
It groups PDF text lines into editable page-level stories using geometry heuristics.
No input files are modified. Output IDML is written to a separate destination.
Requires Python 3.10+ and PyMuPDF.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET
import fitz

PKG_NS = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
ET.register_namespace("idPkg", PKG_NS)
MIMETYPE = b"application/vnd.adobe.indesign-idml-package"
NORMAL_PARA = "ParagraphStyle/$ID/NormalParagraphStyle"
NORMAL_CHAR = "CharacterStyle/$ID/[No character style]"

def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def clean(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()

def line_record(line):
    spans = [s for s in line.get("spans", []) if clean(s.get("text", ""))]
    if not spans:
        return None
    text = clean("".join(s["text"] for s in spans))
    bbox = [min(s["bbox"][0] for s in spans), min(s["bbox"][1] for s in spans),
            max(s["bbox"][2] for s in spans), max(s["bbox"][3] for s in spans)]
    sizes = [float(s.get("size", 10)) for s in spans]
    return {"text": text, "bbox": bbox,
            "font_names": sorted(set(s.get("font", "") for s in spans)),
            "font_sizes": sorted(set(round(x, 2) for x in sizes)),
            "height": max(1.0, bbox[3]-bbox[1]), "size": sum(sizes)/len(sizes)}

def extract_lines(page):
    raw = page.get_text("dict", sort=True)
    lines = []
    for block in raw.get("blocks", []):
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            r = line_record(line)
            if r:
                lines.append(r)
    lines.sort(key=lambda x: (round(x["bbox"][1], 1), x["bbox"][0]))
    return lines

def infer_paragraphs(lines):
    """Infer paragraphs from visual line geometry; intentionally conservative."""
    if not lines:
        return []
    lines = sorted(lines, key=lambda x: (round(x["bbox"][1],1), x["bbox"][0]))
    paras, current = [], [lines[0]]
    for line in lines[1:]:
        prev = current[-1]
        gap = line["bbox"][1] - prev["bbox"][3]
        baseline = line["bbox"][1] - prev["bbox"][1]
        h = max(1.0, (line["height"] + prev["height"]) / 2)
        same_column = abs(line["bbox"][0] - prev["bbox"][0]) <= max(24.0, h*3.5)
        if gap > max(3.0, h*0.72) or baseline > h*1.95 or not same_column:
            paras.append(current)
            current = [line]
        else:
            current.append(line)
    paras.append(current)
    return [{"text": clean(" ".join(x["text"] for x in para)),
             "line_count": len(para),
             "bbox": [min(x["bbox"][0] for x in para), min(x["bbox"][1] for x in para),
                      max(x["bbox"][2] for x in para), max(x["bbox"][3] for x in para)]}
            for para in paras if clean(" ".join(x["text"] for x in para))]

def xml_bytes(s: str) -> bytes:
    return s.encode("utf-8")

def build_package(pdf_path: Path, output_idml: Path, report_path: Path):
    doc = fitz.open(pdf_path)
    files = {
      "META-INF/container.xml": xml_bytes('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
        '<rootfiles><rootfile full-path="designmap.xml" media-type="text/xml"/></rootfiles></container>'),
      "Resources/Graphic.xml": xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Graphic xmlns:idPkg="{PKG_NS}" DOMVersion="20.4">'
        '<Color Self="Color/Black" Model="Process" Space="CMYK" ColorValue="0 0 0 100" Name="Black" ColorEditable="false" ColorRemovable="false"/>'
        '<Color Self="Color/Paper" Model="Process" Space="CMYK" ColorValue="0 0 0 0" Name="Paper" ColorEditable="false" ColorRemovable="false"/></idPkg:Graphic>'),
      "Resources/Fonts.xml": xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Fonts xmlns:idPkg="{PKG_NS}" DOMVersion="20.4"/>'),
      "Resources/Styles.xml": xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Styles xmlns:idPkg="{PKG_NS}" DOMVersion="20.4">'
        f'<RootParagraphStyleGroup Self="u23"><ParagraphStyle Self="{NORMAL_PARA}" Name="$ID/NormalParagraphStyle"/></RootParagraphStyleGroup>'
        f'<RootCharacterStyleGroup Self="u30"><CharacterStyle Self="{NORMAL_CHAR}" Name="$ID/[No character style]"/></RootCharacterStyleGroup></idPkg:Styles>'),
      "Resources/Preferences.xml": xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Preferences xmlns:idPkg="{PKG_NS}" DOMVersion="20.4">'
        '<ButtonPreference Name=""/><PrintPreference PrintFile="" Copies="1" Collating="false" ReverseOrder="false" Sequence="All" PrintSpreads="false" PrintMasterPages="false" PrintNonprinting="false" PrintBlankPages="false" PrintGuidesGrids="false" PaperOffset="0" PaperGap="0" PaperTransverse="false" PrintPageOrientation="Portrait" PagePosition="UpperLeft" ScaleMode="ScaleWidthHeight" ScaleWidth="100" ScaleHeight="100" ScaleProportional="true" Thumbnails="false" ThumbnailsPerPage="K1x2" Tile="false" TilingType="Auto" TilingOverlap="108" AllPrinterMarks="false" CropMarks="false" BleedMarks="false" RegistrationMarks="false" ColorBars="false" PageInformationMarks="false" MarkLineWeight="P25pt" MarkOffset="6" UseDocumentBleedToPrint="true" BleedTop="0" BleedBottom="0" BleedInside="0" BleedOutside="0" IncludeSlugToPrint="false"/></idPkg:Preferences>'),
      "XML/Tags.xml": xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Tags xmlns:idPkg="{PKG_NS}" DOMVersion="20.4"><XMLTag Self="XMLTag/Root" Name="Root"/></idPkg:Tags>'),
      "XML/BackingStory.xml": xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:BackingStory xmlns:idPkg="{PKG_NS}" DOMVersion="20.4">'
        f'<XmlStory Self="ubs" UserText="true" IsEndnoteStory="false" AppliedTOCStyle="n" TrackChanges="false" StoryTitle="$ID/" AppliedNamedGrid="n">'
        f'<ParagraphStyleRange AppliedParagraphStyle="{NORMAL_PARA}"><CharacterStyleRange AppliedCharacterStyle="{NORMAL_CHAR}"><XMLElement Self="dib" MarkupTag="XMLTag/Root"/></CharacterStyleRange></ParagraphStyleRange>'
        '</XmlStory></idPkg:BackingStory>'),
      "META-INF/metadata.xml": xml_bytes('<?xml version="1.0" encoding="UTF-8"?><Metadata xmlns="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"/>')
    }
    page_records, spread_refs, story_refs = [], [], []
    all_text_count = 0
    for pi, page in enumerate(doc, 1):
        page_w, page_h = float(page.rect.width), float(page.rect.height)
        lines = extract_lines(page)
        paras = infer_paragraphs(lines)
        all_text_count += len(lines)
        sid, spread_id, page_id, frame_id = f"story{pi}", f"spread{pi}", f"page{pi}", f"frame{pi}"
        story_refs.append((sid, f"Stories/Story_{sid}.xml"))
        top, left, bottom, right = 36.0, 36.0, max(100.0, page_h-36.0), max(100.0, page_w-36.0)
        pxml = []
        for para in paras:
            pxml.append(f'<ParagraphStyleRange AppliedParagraphStyle="{NORMAL_PARA}"><CharacterStyleRange AppliedCharacterStyle="{NORMAL_CHAR}"><Content>{esc(para["text"])}</Content><Br/></CharacterStyleRange></ParagraphStyleRange>')
        files[f"Stories/Story_{sid}.xml"] = xml_bytes('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          f'<idPkg:Story xmlns:idPkg="{PKG_NS}" DOMVersion="20.4"><Story Self="{sid}" UserText="true" IsEndnoteStory="false" AppliedTOCStyle="n" TrackChanges="false" StoryTitle="PDF recovery page {pi}" AppliedNamedGrid="n">'
          + "".join(pxml) + '</Story></idPkg:Story>')
        frame = (f'<TextFrame Self="{frame_id}" ParentStory="{sid}" ContentType="TextType" ItemTransform="1 0 0 1 0 0" GeometricBounds="{top:.3f} {left:.3f} {bottom:.3f} {right:.3f}" ItemLayer="layer1">'
          '<Properties><PathGeometry><GeometryPathType PathOpen="false"><PathPointArray>'
          f'<PathPointType Anchor="{left:.3f} {top:.3f}" LeftDirection="{left:.3f} {top:.3f}" RightDirection="{left:.3f} {top:.3f}"/>'
          f'<PathPointType Anchor="{right:.3f} {top:.3f}" LeftDirection="{right:.3f} {top:.3f}" RightDirection="{right:.3f} {top:.3f}"/>'
          f'<PathPointType Anchor="{right:.3f} {bottom:.3f}" LeftDirection="{right:.3f} {bottom:.3f}" RightDirection="{right:.3f} {bottom:.3f}"/>'
          f'<PathPointType Anchor="{left:.3f} {bottom:.3f}" LeftDirection="{left:.3f} {bottom:.3f}" RightDirection="{left:.3f} {bottom:.3f}"/>'
          '</PathPointArray></GeometryPathType></PathGeometry></Properties></TextFrame>')
        files[f"Spreads/Spread_{spread_id}.xml"] = xml_bytes('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          f'<idPkg:Spread xmlns:idPkg="{PKG_NS}" DOMVersion="20.4"><Spread Self="{spread_id}" PageCount="1" ItemTransform="1 0 0 1 0 0">'
          f'<Page Self="{page_id}" Name="{pi}" GeometricBounds="0 0 {page_h:.3f} {page_w:.3f}" ItemTransform="1 0 0 1 0 0"><Properties><PageColor type="enumeration">UseMasterColor</PageColor></Properties></Page>'
          + frame + '</Spread></idPkg:Spread>')
        spread_refs.append((spread_id, f"Spreads/Spread_{spread_id}.xml"))
        page_records.append({"page": pi, "width_pt": round(page_w,2), "height_pt": round(page_h,2),
          "extracted_line_count": len(lines), "paragraph_candidate_count": len(paras), "text_frame_count": 1,
          "story_id": sid, "notes": "One page-level frame; intended for editability/reflow experiment, not visual layout reproduction."})
    files["MasterSpreads/MasterSpread_ub4.xml"] = xml_bytes(f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:MasterSpread xmlns:idPkg="{PKG_NS}" DOMVersion="20.4">'
      '<MasterSpread Self="ub4" Name="A-Master" NamePrefix="A" BaseName="Master" ShowMasterItems="true" PageCount="1" OverriddenPageItemProps="" PrimaryTextFrame="n" ItemTransform="1 0 0 1 0 0"><Page Self="ub5" Name="A" GeometricBounds="0 0 841.89 595.276" ItemTransform="1 0 0 1 0 0"/></MasterSpread></idPkg:MasterSpread>')
    refs = ''.join(f'<idPkg:Spread src="{path}"/>' for _, path in spread_refs)
    refs += ''.join(f'<idPkg:Story src="{path}"/>' for _, path in story_refs)
    files["designmap.xml"] = xml_bytes('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<?aid style="50" type="document" readerVersion="6.0" featureSet="257" product="20.4(51)" ?>'
      f'<Document xmlns:idPkg="{PKG_NS}" DOMVersion="20.4" Self="d" StoryList="{" ".join(s for s,_ in story_refs)}" ActiveLayer="layer1">'
      '<Properties><Label type="list"/></Properties><Language Name="$ID/English: USA"/>'
      '<idPkg:Graphic src="Resources/Graphic.xml"/><idPkg:Fonts src="Resources/Fonts.xml"/>'
      '<idPkg:Styles src="Resources/Styles.xml"/><idPkg:Preferences src="Resources/Preferences.xml"/>'
      '<idPkg:Tags src="XML/Tags.xml"/><idPkg:BackingStory src="XML/BackingStory.xml"/>'
      '<idPkg:MasterSpread src="MasterSpreads/MasterSpread_ub4.xml"/>' + refs + '</Document>')
    output_idml.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_idml, "w") as z:
        z.writestr("mimetype", MIMETYPE, compress_type=zipfile.ZIP_STORED)
        for name, data in files.items():
            z.writestr(name, data, compress_type=zipfile.ZIP_DEFLATED)
    with zipfile.ZipFile(output_idml) as z:
        names = z.namelist()
        assert names[0] == "mimetype"
        assert z.getinfo("mimetype").compress_type == zipfile.ZIP_STORED
        assert z.read("mimetype") == MIMETYPE
        roots = {n: ET.fromstring(z.read(n)) for n in names if n.endswith(".xml")}
        missing = [el.attrib["src"] for el in roots["designmap.xml"].iter()
                   if el.attrib.get("src") and el.attrib["src"] not in names]
        assert not missing, f"Missing package members: {missing}"
        frame_count = sum(len(root.findall(".//TextFrame")) for n, root in roots.items() if n.startswith("Spreads/"))
        paragraph_count = sum(len(root.findall(".//ParagraphStyleRange")) for n, root in roots.items() if n.startswith("Stories/"))
        assert frame_count == len(doc), f"Expected {len(doc)} page frames; found {frame_count}"
        report = {"schema": "indd2idml.m1_3.report.v1", "source_pdf_name": pdf_path.name,
          "output_idml_name": output_idml.name, "source_pdf_sha256": hashlib.sha256(pdf_path.read_bytes()).hexdigest(),
          "output_idml_sha256": hashlib.sha256(output_idml.read_bytes()).hexdigest(), "page_count": len(doc),
          "text_frame_count": frame_count, "story_count": len(story_refs), "extracted_line_count": all_text_count,
          "paragraph_candidate_count": paragraph_count, "zip_integrity": "PASS", "mimetype_first_uncompressed": True,
          "xml_well_formed": "PASS", "designmap_references": "PASS", "application_open_test": "NOT TESTED",
          "visual_fidelity": "NOT MEASURED", "warning": "Each page is reconstructed as one text frame and one story using PDF-extracted text. This intentionally prioritizes multi-paragraph editability over original layout; it is not a faithful layout conversion and does not parse INDD."}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps({"report": report, "pages": page_records}, ensure_ascii=False, indent=2), encoding="utf-8")
    return report, page_records

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("pdf", type=Path, help="Reference PDF input (read-only)")
    ap.add_argument("--out", type=Path, required=True, help="Output .idml path")
    ap.add_argument("--report", type=Path, default=None, help="JSON validation report path")
    args = ap.parse_args()
    report_path = args.report or args.out.with_suffix(".validation.json")
    report, _ = build_package(args.pdf, args.out, report_path)
    print(json.dumps(report, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
