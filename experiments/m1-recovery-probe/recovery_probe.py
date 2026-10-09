#!/usr/bin/env python3
"""PDF-assisted INDD recovery probe (M1). Read-only for INDD/PDF inputs.

Extracts positioned text spans from matching PDF references, renders page previews,
scans printable INDD strings, and emits a reviewable HTML/JSON recovery map.
It does NOT generate IDML or claim that PDF-derived text is an editable InDesign object.
Requires PyMuPDF: python3 -m pip install pymupdf
"""
from __future__ import annotations
import argparse, hashlib, html, json, re
from pathlib import Path
import fitz

TOKEN_RE = re.compile(r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)*")

def sha256(p: Path):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()

def ascii_strings(p: Path):
    data=p.read_bytes()
    return [m.group().decode('latin1','replace') for m in re.finditer(rb'[\x20-\x7e]{4,}',data)]

def norm_tokens(text): return {x.lower() for x in TOKEN_RE.findall(text)}

def probe(indd: Path, pdf: Path, out: Path):
    out.mkdir(parents=True,exist_ok=True); (out/'renders').mkdir(exist_ok=True)
    strings=ascii_strings(indd); indd_text='\n'.join(strings); indd_tokens=norm_tokens(indd_text)
    doc=fitz.open(pdf); pages=[]; pdf_tokens=set(); matched=set()
    for i,page in enumerate(doc):
        page_dict=page.get_text('dict', sort=True); spans=[]; page_text=[]
        for block in page_dict.get('blocks',[]):
            if block.get('type') != 0: continue
            for line in block.get('lines',[]):
                line_spans=[]
                for span in line.get('spans',[]):
                    txt=span.get('text','').strip()
                    if not txt: continue
                    bbox=[round(float(v),2) for v in span['bbox']]
                    item={'text':txt,'bbox_pt':bbox,'font':span.get('font'), 'size_pt':round(float(span.get('size',0)),2), 'flags':span.get('flags',0), 'color_int':span.get('color')}
                    spans.append(item); line_spans.append(txt)
                    toks=norm_tokens(txt); pdf_tokens |= toks; matched |= (toks & indd_tokens)
                if line_spans: page_text.append(' '.join(line_spans))
        pix=page.get_pixmap(matrix=fitz.Matrix(1.15,1.15),alpha=False)
        image_name=f'page-{i+1:02d}.png'; pix.save(out/'renders'/image_name)
        pages.append({'page_number':i+1,'width_pt':round(page.rect.width,2),'height_pt':round(page.rect.height,2),'image':f'renders/{image_name}','text': '\n'.join(page_text),'span_count':len(spans),'spans':spans})
    report={'title':pdf.stem,'input_indd':{'filename':indd.name,'size_bytes':indd.stat().st_size,'sha256':sha256(indd)},'reference_pdf':{'filename':pdf.name,'size_bytes':pdf.stat().st_size,'sha256':sha256(pdf),'page_count':len(doc),'sha256':sha256(pdf)},'indd_ascii_run_count':len(strings),'unique_indd_tokens':len(indd_tokens),'unique_pdf_tokens':len(pdf_tokens),'unique_pdf_tokens_found_in_indd':len(matched),'token_overlap_ratio':round(len(matched)/len(pdf_tokens),4) if pdf_tokens else None,'warning':'Token overlap is not a measure of visual fidelity or editability. This probe maps PDF text positions; it does not parse INDD objects or generate IDML.','pages':pages}
    (out/'recovery-map.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    # self-contained HTML except linked PNG previews; boxes show extracted PDF text spans at their approximate PDF coordinates.
    cards=[]
    for p in pages:
        w,h=p['width_pt'],p['height_pt']; boxes=[]
        for s in p['spans']:
            x0,y0,x1,y1=s['bbox_pt']; title=html.escape(f"{s['text']} | {s['font']} {s['size_pt']}pt")
            boxes.append(f'<div class="span" title="{title}" style="left:{x0/w*100:.4f}%;top:{y0/h*100:.4f}%;width:{max(0.15,(x1-x0)/w*100):.4f}%;height:{max(0.15,(y1-y0)/h*100):.4f}%"></div>')
        cards.append(f'''<section class="page-card"><h2>Page {p['page_number']} <small>{p['span_count']} text spans</small></h2><div class="preview" style="aspect-ratio:{w}/{h}"><img src="{p['image']}" alt="PDF page {p['page_number']}"><div class="overlay">{''.join(boxes)}</div></div><details><summary>Extracted text</summary><pre>{html.escape(p['text'])}</pre></details></section>''')
    ratio=report['token_overlap_ratio']; pct=f'{ratio*100:.2f}%' if ratio is not None else 'n/a'
    page_nav=''.join(f'<a href="#p{i+1}">{i+1}</a>' for i in range(len(pages)))
    # assign ids
    cards=[c.replace('class="page-card"','class="page-card" id="p'+str(i+1)+'"') for i,c in enumerate(cards)]
    doc_html=f'''<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>M1 Recovery Probe — {html.escape(pdf.stem)}</title><style>
:root{{color-scheme:dark}}body{{margin:0;background:#111318;color:#e9eaf0;font:15px/1.5 -apple-system,BlinkMacSystemFont,sans-serif}}header{{padding:28px max(20px,calc((100vw - 1100px)/2));background:#1a1d24;border-bottom:1px solid #30343d}}main{{max-width:1100px;margin:24px auto;padding:0 20px}}h1{{font-size:24px;margin:0 0 8px}}h2{{font-size:18px}}small,.muted{{color:#a8afbd}}.metrics{{display:flex;gap:12px;flex-wrap:wrap;margin:18px 0}}.metric{{padding:12px 16px;background:#20242d;border:1px solid #353a46;border-radius:10px;min-width:150px}}.metric b{{display:block;font-size:23px}}.warning{{border-left:3px solid #d6a54d;padding:12px 16px;background:#29251d;margin:18px 0}}.page-card{{margin:28px 0;padding:16px;background:#1a1d24;border:1px solid #343945;border-radius:14px}}.preview{{position:relative;width:min(100%,680px);margin:auto;background:#fff}}.preview img{{display:block;width:100%;height:100%}}.overlay{{position:absolute;inset:0;pointer-events:none}}.span{{position:absolute;border:1px solid rgba(40,150,255,.0);pointer-events:auto}}.span:hover{{background:rgba(0,150,255,.16);border:1px solid #168bff;z-index:2}}details{{margin-top:12px}}pre{{white-space:pre-wrap;background:#101217;padding:12px;border-radius:8px;overflow:auto}}a{{color:#8fc3ff;margin-right:10px}}</style></head><body><header><h1>M1 PDF-assisted Recovery Probe</h1><div class="muted">{html.escape(indd.name)} ↔ {html.escape(pdf.name)}</div><div class="metrics"><div class="metric"><small>PDF pages</small><b>{len(pages)}</b></div><div class="metric"><small>Positioned text spans</small><b>{sum(p['span_count'] for p in pages)}</b></div><div class="metric"><small>PDF token overlap</small><b>{pct}</b></div><div class="metric"><small>INDD strings scanned</small><b>{len(strings)}</b></div></div><div class="warning"><b>Important:</b> this is a recovery map, not a converter. Blue outlines appear on hover to inspect extracted text span bounds. PDF text positions are known; INDD object geometry is not recovered by this probe. No source file was modified.</div><div>Pages: {page_nav}</div></header><main>{''.join(cards)}<p class="muted">Audit data: <a href="recovery-map.json">recovery-map.json</a>. Inputs are read-only; page previews are rendered from the supplied PDF.</p></main></body></html>'''
    (out/'index.html').write_text(doc_html,encoding='utf-8')
    return report

def main():
    ap=argparse.ArgumentParser(description=__doc__); ap.add_argument('--indd',required=True,type=Path); ap.add_argument('--pdf',required=True,type=Path); ap.add_argument('--out',required=True,type=Path); ns=ap.parse_args()
    if not ns.indd.is_file() or not ns.pdf.is_file(): ap.error('Both INDD and PDF must exist.')
    r=probe(ns.indd,ns.pdf,ns.out); print(json.dumps({k:r[k] for k in ['title','input_indd','reference_pdf','indd_ascii_run_count','unique_indd_tokens','unique_pdf_tokens','unique_pdf_tokens_found_in_indd','token_overlap_ratio','warning']},indent=2))
if __name__=='__main__': main()
