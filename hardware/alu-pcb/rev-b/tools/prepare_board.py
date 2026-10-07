#!/usr/bin/env python3
"""KiCad pcbnew Python: prepare freshly generated board after XML netlist export.
Run before routing; preserves exact schematic net names and local footprints.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
import pcbnew
SRC=Path(__file__).resolve().parents[1]/'source'
b=pcbnew.LoadBoard(str(SRC/'alu_rev_b.kicad_pcb'))
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
b.BuildConnectivity();pcbnew.SaveBoard(str(SRC/'alu_rev_b.kicad_pcb'),b)
assert pcbnew.ExportSpecctraDSN(b,str(SRC/'alu_rev_b.dsn'))
print('Prepared library, exact schematic nets and routing DSN')
