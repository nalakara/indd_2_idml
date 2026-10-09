#!/usr/bin/env python3
"""Build a minimal IDML package proving multi-paragraph story representation.

This is a structure prototype, not an INDD converter. It intentionally uses a
single editable text frame with several paragraphs to test the data model.
"""
from pathlib import Path
from zipfile import ZipFile, ZIP_STORED, ZIP_DEFLATED
from xml.etree import ElementTree as ET
import json, hashlib

OUT = Path(__file__).parent
IDML = OUT / "M1_1_multi_paragraph_story.idml"
REPORT = OUT / "M1_1_VALIDATION_REPORT.md"
NS = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
ET.register_namespace('idPkg', NS)

files = {}
files['mimetype'] = b'application/vnd.adobe.indesign-idml-package'
files['META-INF/container.xml'] = b'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="designmap.xml" media-type="text/xml"/></rootfiles></container>'''
files['Resources/Graphic.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<idPkg:Graphic xmlns:idPkg="{NS}" DOMVersion="20.4"><Color Self="Color/Black" Model="Process" Space="CMYK" ColorValue="0 0 0 100" Name="Black" ColorEditable="false" ColorRemovable="false"/><Color Self="Color/Paper" Model="Process" Space="CMYK" ColorValue="0 0 0 0" Name="Paper" ColorEditable="false" ColorRemovable="false"/></idPkg:Graphic>'''.encode()
files['Resources/Fonts.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Fonts xmlns:idPkg="{NS}" DOMVersion="20.4"/>'''.encode()
files['Resources/Styles.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Styles xmlns:idPkg="{NS}" DOMVersion="20.4"><RootParagraphStyleGroup Self="u23"><ParagraphStyle Self="ParagraphStyle/$ID/NormalParagraphStyle" Name="$ID/NormalParagraphStyle"/></RootParagraphStyleGroup><RootCharacterStyleGroup Self="u30"><CharacterStyle Self="CharacterStyle/$ID/[No character style]" Name="$ID/[No character style]"/></RootCharacterStyleGroup></idPkg:Styles>'''.encode()
files['Resources/Preferences.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Preferences xmlns:idPkg="{NS}" DOMVersion="20.4"><DocumentPreference PageWidth="595.276" PageHeight="841.89" FacingPages="false"/></idPkg:Preferences>'''.encode()
files['XML/Tags.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Tags xmlns:idPkg="{NS}" DOMVersion="20.4"><XMLTag Self="XMLTag/Root" Name="Root"/></idPkg:Tags>'''.encode()
files['XML/BackingStory.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:BackingStory xmlns:idPkg="{NS}" DOMVersion="20.4"><XmlStory Self="ubs" UserText="true" IsEndnoteStory="false" AppliedTOCStyle="n" TrackChanges="false" StoryTitle="$ID/" AppliedNamedGrid="n"><ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/$ID/NormalParagraphStyle"><CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]"><XMLElement Self="dib" MarkupTag="XMLTag/Root"/></CharacterStyleRange></ParagraphStyleRange></XmlStory></idPkg:BackingStory>'''.encode()
files['META-INF/metadata.xml'] = b'''<?xml version="1.0" encoding="UTF-8"?><Metadata xmlns="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"/>'''

# Three paragraphs in ONE Story, represented with standard IDML paragraph ranges.
paragraphs = [
    "This is paragraph one. It is deliberately longer than a single line so that the frame can reflow the text.",
    "This is paragraph two. It lives in the same story and the same text frame as paragraph one.",
    "This is paragraph three. Editing the frame width should cause text to reflow rather than split each line into a separate object."
]
xml_escape = lambda s: (s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;'))
para_xml = ''.join(f'<ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/$ID/NormalParagraphStyle"><CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]"><Content>{xml_escape(p)}</Content><Br/></CharacterStyleRange></ParagraphStyleRange>' for p in paragraphs)
files['Stories/Story_u1.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Story xmlns:idPkg="{NS}" DOMVersion="20.4"><Story Self="u1" UserText="true" IsEndnoteStory="false" AppliedTOCStyle="n" TrackChanges="false" StoryTitle="Multi-paragraph test" AppliedNamedGrid="n">{para_xml}</Story></idPkg:Story>'''.encode()

# Text frame path on a single A4 page. Geometry is only a controlled test fixture.
spread = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:Spread xmlns:idPkg="{NS}" DOMVersion="20.4"><Spread Self="s1" PageCount="1" ItemTransform="1 0 0 1 0 0"><Page Self="p1" Name="1" GeometricBounds="0 0 841.89 595.276" ItemTransform="1 0 0 1 0 0"><Properties><PageColor type="enumeration">UseMasterColor</PageColor></Properties></Page><TextFrame Self="tf1" ParentStory="u1" ContentType="TextType" ItemTransform="1 0 0 1 0 0" GeometricBounds="72 72 360 523.276" ItemLayer="layer1"><Properties><PathGeometry><GeometryPathType PathOpen="false"><PathPointArray><PathPointType Anchor="72 72" LeftDirection="72 72" RightDirection="72 72"/><PathPointType Anchor="523.276 72" LeftDirection="523.276 72" RightDirection="523.276 72"/><PathPointType Anchor="523.276 360" LeftDirection="523.276 360" RightDirection="523.276 360"/><PathPointType Anchor="72 360" LeftDirection="72 360" RightDirection="72 360"/></PathPointArray></GeometryPathType></PathGeometry></Properties></TextFrame></Spread></idPkg:Spread>'''
files['Spreads/Spread_s1.xml'] = spread.encode()
files['MasterSpreads/MasterSpread_ub4.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><idPkg:MasterSpread xmlns:idPkg="{NS}" DOMVersion="20.4"><MasterSpread Self="ub4" Name="A-Master" NamePrefix="A" BaseName="Master" ShowMasterItems="true" PageCount="1" OverriddenPageItemProps="" PrimaryTextFrame="n" ItemTransform="1 0 0 1 0 0"><Page Self="ub5" Name="A" GeometricBounds="0 0 841.89 595.276" ItemTransform="1 0 0 1 0 0"/></MasterSpread></idPkg:MasterSpread>'''.encode()
files['designmap.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><?aid style="50" type="document" readerVersion="6.0" featureSet="257" product="20.4(51)" ?><Document xmlns:idPkg="{NS}" DOMVersion="20.4" Self="d" StoryList="u1" ActiveLayer="layer1"><Properties><Label type="list"/></Properties><Language Name="$ID/English: USA"/><idPkg:Graphic src="Resources/Graphic.xml"/><idPkg:Fonts src="Resources/Fonts.xml"/><idPkg:Styles src="Resources/Styles.xml"/><idPkg:Preferences src="Resources/Preferences.xml"/><idPkg:Tags src="XML/Tags.xml"/><idPkg:BackingStory src="XML/BackingStory.xml"/><idPkg:MasterSpread src="MasterSpreads/MasterSpread_ub4.xml"/><idPkg:Spread src="Spreads/Spread_s1.xml"/><idPkg:Story src="Stories/Story_u1.xml"/></Document>'''.encode()

# Required IDML convention: mimetype first and uncompressed.
with ZipFile(IDML, 'w') as z:
    z.writestr('mimetype', files.pop('mimetype'), compress_type=ZIP_STORED)
    for name, data in files.items():
        z.writestr(name, data, compress_type=ZIP_DEFLATED)

# Structural checks only; not a substitute for opening the file in InDesign.
with ZipFile(IDML) as z:
    names = z.namelist()
    assert names[0] == 'mimetype'
    assert z.getinfo('mimetype').compress_type == ZIP_STORED
    assert z.read('mimetype') == b'application/vnd.adobe.indesign-idml-package'
    xml_names = [n for n in names if n.endswith('.xml')]
    roots = {}
    for name in xml_names:
        roots[name] = ET.fromstring(z.read(name)).tag
    story = ET.fromstring(z.read('Stories/Story_u1.xml'))
    got_paras = story.findall('.//ParagraphStyleRange')
    got_text = [''.join(p.itertext()) for p in got_paras]
    assert len(got_paras) == 3, f'Expected 3 paragraphs, got {len(got_paras)}'
    assert len(story.findall('.//CharacterStyleRange')) == 3
    spread_root = ET.fromstring(z.read('Spreads/Spread_s1.xml'))
    frame = spread_root.find('.//TextFrame')
    assert frame is not None and frame.get('ParentStory') == 'u1'
    report = {
        'idml_path': str(IDML), 'bytes': IDML.stat().st_size,
        'sha256': hashlib.sha256(IDML.read_bytes()).hexdigest(),
        'zip_entry_count': len(names), 'xml_files_parsed': len(xml_names),
        'mimetype_first_and_uncompressed': True,
        'story_paragraph_count': len(got_paras),
        'text_frame_count': len(spread_root.findall('.//TextFrame')),
        'frame_parent_story': frame.get('ParentStory'),
        'paragraph_texts': got_text,
        'validation_scope': 'ZIP structure and XML well-formedness plus multi-paragraph story relationship only; not validated by Adobe InDesign or another IDML renderer.'
    }

REPORT.write_text('# M1.1 — Multi-paragraph IDML structure prototype\n\n'
    '## Result\n\n'
    '**PASS for structural checks; not yet validated by an InDesign-compatible application.**\n\n'
    f'- IDML package size: {report["bytes"]:,} bytes\n'
    f'- ZIP entries: {report["zip_entry_count"]}\n'
    f'- XML files parsed successfully: {report["xml_files_parsed"]}\n'
    f'- One TextFrame points to Story `{report["frame_parent_story"]}`\n'
    f'- Paragraph ranges in that Story: {report["story_paragraph_count"]}\n'
    '- `mimetype` is first in the ZIP and stored without compression.\n\n'
    '## What this proves\n\n'
    'The prototype data model can represent multiple paragraph ranges in one Story associated with one TextFrame. It does not model one object per visible line.\n\n'
    '## What this does not prove\n\n'
    '- It is not a converter for the supplied INDD documents.\n'
    '- It does not recover original frame geometry, styles, linked-frame chains, images, layers, or master-page relationships.\n'
    '- XML parsing and ZIP validity do not guarantee that Adobe InDesign will open the package. The next required test is opening this file in InDesign or another IDML-compatible application and checking actual text reflow.\n\n'
    '## Paragraph fixture\n\n' + '\n'.join(f'{i+1}. {p}' for i,p in enumerate(paragraphs)) + '\n\n'
    '## Validation JSON\n\n```json\n' + json.dumps(report, ensure_ascii=False, indent=2) + '\n```\n', encoding='utf-8')
(OUT/'validation.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
