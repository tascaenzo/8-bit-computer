#!/usr/bin/env python3
"""Run with KiCad's Python (pcbnew) after routing the exported DSN.

Usage: python finish_board.py
Imports alu_rev_b.ses, normalizes schematic net names, adds ground pours,
and saves the final PCB. Final DRC must be run separately with kicad-cli.
"""
from pathlib import Path
import json
import pcbnew

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'source'
board=pcbnew.LoadBoard(str(SRC/'alu_rev_b.kicad_pcb'))
assert (SRC/'alu_rev_b.ses').exists(), 'Routing session file is required'
assert pcbnew.ImportSpecctraSES(board,str(SRC/'alu_rev_b.ses')), 'Failed to import routing'

# The hierarchical schematic uses global names; preserve those exact names.
gnd=next(net for net in board.GetNetInfo().NetsByNetcode().values() if net.GetNetname()=='GND')
assert gnd
for old in list(board.Zones()):board.Remove(old)
width,height=json.loads((SRC/"netlist.json").read_text())["width_mm"],json.loads((SRC/"netlist.json").read_text())["height_mm"]
for layer in [pcbnew.F_Cu,pcbnew.B_Cu]:
    zone=pcbnew.ZONE(board)
    zone.SetLayer(layer); zone.SetNetCode(gnd.GetNetCode())
    zone.SetLocalClearance(pcbnew.FromMM(0.25))
    zone.SetThermalReliefGap(pcbnew.FromMM(0.3))
    zone.SetThermalReliefSpokeWidth(pcbnew.FromMM(0.4))
    zone.SetMinThickness(pcbnew.FromMM(0.25))
    zone.SetPadConnection(pcbnew.ZONE_CONNECTION_FULL)
    outline=zone.Outline(); outline.NewOutline()
    for x,y in [(1,1),(width-1,1),(width-1,height-1),(1,height-1)]:
        outline.Append(pcbnew.FromMM(x),pcbnew.FromMM(y))
    board.Add(zone)

# Ground through-hole pads already stitch the pours at every IC and capacitor.

board.BuildConnectivity()
pcbnew.ZONE_FILLER(board).Fill(board.Zones())
pcbnew.SaveBoard(str(SRC/'alu_rev_b.kicad_pcb'),board)
print('Saved final routed PCB with ground pours; run DRC before fabrication export.')
