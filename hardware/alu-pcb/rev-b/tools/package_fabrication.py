#!/usr/bin/env python3
"""Package only after fresh, successful KiCad ERC/DRC and Gerber exports."""
import hashlib
import json
import re
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
drc=json.loads((ROOT/'verification/drc.json').read_text())
assert not any(drc[key] for key in ('violations','unconnected_items','schematic_parity'))
assert re.search(r'ERC messages:\s*0\s+Errors\s+0\s+Warnings\s+0', (ROOT/'verification/erc.rpt').read_text()), 'ERC must be clean'
logic=json.loads((ROOT/'verification/logic-report.json').read_text())
assert logic['status']=='PASS'
files=sorted((ROOT/'fabrication').iterdir())
required={'.gtl','.gbl','.gts','.gbs','.gto','.gbo','.gm1'}
assert required.issubset({f.suffix for f in files})
assert len([f for f in files if f.suffix=='.drl'])==2
for f in files:
    if f.suffix in required: assert f.read_text().rstrip().endswith('M02*'), f
    if f.suffix=='.drl': assert 'M48' in f.read_text() and 'M30' in f.read_text(), f
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
manifest={'revision':'B','kicad_version':drc['kicad_version'],
          'board_size_mm':[290,300],'layers':2,'thickness_mm':1.6,
          'erc_violations':0,'drc_violations':0,'unconnected_items':0,'schematic_parity_issues':0,
          'logic_cases':logic['input_cases'],'hardware_tested':False,
          'assumptions':['5V 74HCT through-hole logic','External RA/RB and flag register','Board-specific connector pinouts','SW4 selects external/local A/B/opcode/enable','SW5 enables local bus; CMP remains isolated','30 buffered or decoded LEDs'],
          'sha256':{str(p.relative_to(ROOT)):digest(p) for p in files+[ROOT/'source/alu_rev_b.kicad_pcb',ROOT/'source/alu_rev_b.kicad_sch',ROOT/'verification/drc.json']}}
(ROOT/'verification/fabrication-manifest.json').write_text(json.dumps(manifest,indent=2))
with zipfile.ZipFile(ROOT/'CPU8_ALU_REV_B_GERBER.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,p.name)
with zipfile.ZipFile(ROOT/'CPU8_ALU_REV_B_PROJECT.zip','w',zipfile.ZIP_DEFLATED) as z:
    keep=[ROOT/'README.md',ROOT/'BOM.csv',ROOT/'alu_rev_b_schematic.pdf',ROOT/'alu_rev_b_preview.png',ROOT/'alu_rev_b_layout.svg']
    keep += [p for p in (ROOT/'source').rglob('*') if p.is_file() and p.suffix not in ('.dsn','.ses','.lck','.bak')]
    keep += [p for p in (ROOT/'verification').iterdir() if p.is_file() and p.name in ('drc.json','erc.rpt','logic-report.json','fabrication-manifest.json','drill-report.txt')]
    keep += list((ROOT/'tools').glob('*.py'))
    for p in keep:z.write(p,str(p.relative_to(ROOT)))
for name in ['CPU8_ALU_REV_B_GERBER.zip','CPU8_ALU_REV_B_PROJECT.zip']:
    p=ROOT/name
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None
        print(f'{name}: {len(z.namelist())} files, {p.stat().st_size:,} bytes; ZIP integrity OK')
