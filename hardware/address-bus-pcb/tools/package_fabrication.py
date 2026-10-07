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
manifest={'revision':'A','layout_id':'2026-10-07-slim-led-switch','designer':'Enzo Tasca','kicad_version':drc['kicad_version'],
          'board_size_mm':[300, 46],'layers':2,'thickness_mm':1.6,
          'erc_violations':0,'drc_violations':0,'unconnected_items':0,'schematic_parity_issues':0,
          'logic_cases':logic['input_cases'],'hardware_tested':False,
          'assumptions':['5V 74HCT through-hole logic','Eight parallel 16-bit address ports: A0..A15, four GND pins','External address source selection: PC/MAR/IDX, one driver at a time','Sixteen buffered address LEDs plus power LED','SW1 grounds all LED buffer OE_n pins when ON; 10k pull-up disables them when OFF; PWR remains on','Compact 4mm LED pitch with 2mm extra nibble gaps','10k pull-down per bus bit','Address ports carry GND but no +5V'],
          'sha256':{str(p.relative_to(ROOT)):digest(p) for p in files+[ROOT/'source/address_bus_rev_a.kicad_pcb',ROOT/'source/address_bus_rev_a.kicad_sch',ROOT/'verification/drc.json']}}
(ROOT/'verification/fabrication-manifest.json').write_text(json.dumps(manifest,indent=2))
with zipfile.ZipFile(ROOT/'CPU8_ADDRESS_BUS_REV_A_GERBER.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,p.name)
with zipfile.ZipFile(ROOT/'CPU8_ADDRESS_BUS_REV_A_PROJECT.zip','w',zipfile.ZIP_DEFLATED) as z:
    keep=[ROOT/'README.md',ROOT/'BOM.csv',ROOT/'address_bus_rev_a_schematic.pdf',ROOT/'address_bus_rev_a_preview.png',ROOT/'address_bus_rev_a_layout.svg']
    keep += [p for p in (ROOT/'source').rglob('*') if p.is_file() and p.suffix not in ('.dsn','.ses','.lck','.bak','.kicad_prl')]
    keep += [p for p in (ROOT/'verification').iterdir() if p.is_file() and p.name in ('drc.json','erc.rpt','logic-report.json','fabrication-manifest.json','drill-report.txt')]
    keep += list((ROOT/'tools').glob('*.py'))
    for p in keep:z.write(p,str(p.relative_to(ROOT)))
for name in ['CPU8_ADDRESS_BUS_REV_A_GERBER.zip','CPU8_ADDRESS_BUS_REV_A_PROJECT.zip']:
    p=ROOT/name
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None
        print(f'{name}: {len(z.namelist())} files, {p.stat().st_size:,} bytes; ZIP integrity OK')
