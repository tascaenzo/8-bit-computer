#!/usr/bin/env python3
"""KiCad pcbnew Python: prepare freshly generated board after XML netlist export.
Run before routing; preserves exact schematic net names and local footprints.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
import json,re
import pcbnew
SRC=Path(__file__).resolve().parents[1]/'source'
b=pcbnew.LoadBoard(str(SRC/'data_bus_rev_a.kicad_pcb'))
nets={n.GetNetname():n for n in b.GetNetInfo().NetsByNetcode().values()}
node={}
for n in ET.parse(SRC/'schematic.xml').findall('./nets/net'):
    name=n.attrib['name']
    if name not in nets:
        net=pcbnew.NETINFO_ITEM(b,name);b.Add(net);nets[name]=net
    for p in n.findall('node'):node[(p.attrib['ref'],p.attrib['pin'])]=name
lib=SRC/'CPU8.pretty';lib.mkdir(exist_ok=True)
plugin=pcbnew.PCB_IO_MGR.FindPlugin(pcbnew.PCB_IO_MGR.KICAD_SEXP)
for fp in b.GetFootprints():
    for pad in fp.Pads():
        key=(fp.GetReference(),pad.GetNumber())
        if key in node:pad.SetNet(nets[node[key]])
    plugin.FootprintSave(str(lib),fp)
b.BuildConnectivity();pcbnew.SaveBoard(str(SRC/'data_bus_rev_a.kicad_pcb'),b)
assert pcbnew.ExportSpecctraDSN(b,str(SRC/'data_bus_rev_a.dsn'))
print('Prepared library, exact schematic nets and routing DSN')

# Freerouting boundary inset is a routing constraint only; actual Edge.Cuts stay unchanged.
# Reserve 0.5mm at the outline so routed tracks meet KiCad's copper-edge clearance.
dim=json.loads((SRC/'netlist.json').read_text())
w,h=dim['width_mm']*1000,dim['height_mm']*1000
dsn=next(SRC.glob('*rev_a.dsn'));s=dsn.read_text()
m=re.search(r'(\(boundary\s+\(path pcb 0\s+)([^)]+)(\)\s*\))',s)
assert m, 'Expected rectangular routing boundary in micrometres'
coords=[float(x) for x in m.group(2).split()];assert len(coords)==10
for i,v in enumerate(coords):
 if i%2==0:coords[i]=500 if v==0 else w-500 if v==w else v
 else:coords[i]=-500 if v==0 else -h+500 if v==-h else v
s=s[:m.start(2)]+' '.join(f'{v:g}' for v in coords)+s[m.end(2):]
dsn.write_text(s)
print('Routing-only boundary inset by 0.5mm; PCB outline preserved')
