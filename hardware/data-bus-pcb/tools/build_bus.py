#!/usr/bin/env python3
"""Generate an UNROUTED KiCad 8-bit bus board; route and verify before export."""
import argparse,csv,json,uuid
from pathlib import Path
from schematic_writer import write_schematic
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'source'
OUT.mkdir(exist_ok=True)
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--rebuild-unrouted',action='store_true');args=p.parse_args()
if (OUT/'data_bus_rev_a.kicad_pcb').exists() and not args.rebuild_unrouted:
 raise SystemExit('Existing PCB preserved; --rebuild-unrouted requires a new routing and fabrication check.')
W,H=235,40
components=[]
def uid():return str(uuid.uuid4())
def q(s):return json.dumps(str(s))
def add(ref,value,n,footprint,pins,x,y,purpose,**extra):
 c=dict(ref=ref,value=value,n=n,footprint=footprint,pins=pins,x=x,y=y,purpose=purpose,uuid=uid(),**extra);components.append(c);return c
pins={1:'LED_OE_n',19:'LED_OE_n',10:'GND',20:'+5V'}
for bit,(a,y) in enumerate([(2,18),(4,16),(6,14),(8,12),(11,9),(13,7),(15,5),(17,3)]):
 pins[a]=f'D{bit}';pins[y]=f'LED_D{bit}_DRIVE'
add('U1','SN74HCT244N',20,'DIP-20_W7.62mm',pins,195,10,'High-impedance bus sensing; isolated LED outputs',kind='244')
for i in range(1,9):
 add(f'J{i}',f'BUS{i}',10,'Header_2x5_P2.54mm',{**{b+1:f'D{b}' for b in range(8)},9:'GND',10:'GND'},10+(i-1)*23,10,'Bidirectional data port; ALU J4 compatible')
add('J9','POWER_5V',4,'Header_2x2_P2.54mm',{1:'+5V',2:'GND',3:'+5V',4:'GND'},220,10,'5V power; ALU J6 pinout compatible')
add('C1','100nF',2,'C_Disc_P2.50mm',{1:'+5V',2:'GND'},205.16,10,'Local ceramic bypass')
add('C2','10uF_16V',2,'C_Radial_P2.50mm',{1:'+5V',2:'GND'},220,23,'Bulk decoupling; pin 1 positive')
add('RN1','10k_Bussed_SIP9',9,'SIP-9_P2.54mm',{1:'GND',**{b+2:f'D{b}' for b in range(8)}},180,6,'Eight 10k bus pull-downs; common pin 1')
for bit in range(7,-1,-1):
 rank=7-bit; x=72+rank*4+2*(rank//4)
 add(f'R{bit+1}','2.2k',2,'R_Axial_P7.62mm',{1:f'LED_D{bit}_DRIVE',2:f'LED_D{bit}_A'},16+(7-bit)*20-7.62,24,f'D{bit} LED current limit')
 add(f'D{bit+1}','GREEN',2,'LED_D3.0mm_P2.54mm_Vertical',{1:'GND',2:f'LED_D{bit}_A'},x,30,f'Bus bit {bit} indicator',monitor=bit)
add('R9','2.2k',2,'R_Axial_P7.62mm',{1:'+5V',2:'LED_PWR_A'},211,30,'Power LED current limit')
add('D9','GREEN',2,'LED_D3.0mm_P2.54mm',{1:'GND',2:'LED_PWR_A'},222,30,'5V supply indicator',monitor='PWR')
add('SW1','SDA01H0BD_LED_ENABLE',2,'SW_DIP_SPST_1_P2.54_W7.62',{1:'LED_OE_n',2:'GND'},175,25,'ON=bit LEDs enabled; OFF=bit LEDs disabled; power LED remains on',positions=1,contacts=[[1,2,'LED_OE_n']])
add('R10','10k',2,'R_Axial_P7.62mm',{1:'+5V',2:'LED_OE_n'},182,22,'Pull-up disables LED buffers when SW1 is OFF')
rootuuid=uid();sheet_paths=write_schematic(OUT,components,rootuuid)
netnames=sorted({n for c in components for n in c['pins'].values()});netids={n:i+1 for i,n in enumerate(netnames)}
def padcoords(c):
 if c['ref'].startswith('SW'):return {1:(0,0),2:(0,7.62)}
 if isinstance(c.get('monitor'),int):return {1:(0,0),2:(0,2.54)}
 if c.get('kind'):
  half=c['n']//2
  return {**{p:(0,(p-1)*2.54) for p in range(1,half+1)},**{p:(7.62,(c['n']-p)*2.54) for p in range(half+1,c['n']+1)}}
 if c['ref'].startswith('J'):return {p:((p-1)%2*2.54,(p-1)//2*2.54) for p in range(1,c['n']+1)}
 pitch=2.54 if c['ref'].startswith(('D','RN')) else 7.62 if c['ref'].startswith('R') else 2.5
 return {p:((p-1)*pitch,0) for p in range(1,c['n']+1)}
def text(s,x,y,size=1):return f'(gr_text {q(s)} (at {x} {y}) (layer "F.SilkS") (effects (font (size {size} {size}) (thickness 0.15))))'
pcb=['(kicad_pcb (version 20221018) (generator "cpu8_data_bus_generator")','(general (thickness 1.6)) (paper "A4")',
 '(layers (0 "F.Cu" signal) (31 "B.Cu" signal) (36 "B.SilkS" user "b.silkscreen") (37 "F.SilkS" user "f.silkscreen") (38 "B.Mask" user) (39 "F.Mask" user) (44 "Edge.Cuts" user) (46 "B.CrtYd" user) (47 "F.CrtYd" user) (48 "B.Fab" user) (49 "F.Fab" user))',
 '(setup (pad_to_mask_clearance 0.05))','(net 0 "")']
pcb += [f'(net {netids[n]} {q(n)})' for n in netnames]
for c in components:
 pcs=padcoords(c);maxx=max(v[0] for v in pcs.values());maxy=max(v[1] for v in pcs.values());r=c['ref']
 pcb += [f'(footprint {q("CPU8:"+c["footprint"])} (layer "F.Cu") (at {c["x"]} {c["y"]}) (tstamp {c["uuid"]}) (path {q("/"+rootuuid+"/"+sheet_paths[r]+"/"+c["uuid"])}) (attr through_hole)',
 f'(fp_text reference {q(r)} (at {5 if r.startswith("SW") else -3 if r.startswith("R") and not r.startswith("RN") else maxx/2} {3.81 if r.startswith("SW") else 0 if r.startswith("R") and not r.startswith("RN") else -3 if r.startswith(("J","D")) else -2}) (layer {q("F.Fab" if r.startswith("D") and r!="D9" else "F.SilkS")}) (effects (font (size 1 1) (thickness 0.15))))',
 f'(fp_text value {q(c["value"])} (at {maxx/2} {maxy+2.3}) (layer {q("F.Fab" if r.startswith(("D","RN","J","SW")) else "F.SilkS")}) (effects (font (size 0.85 0.85) (thickness 0.15))))']
 if c.get('kind'):pcb += [f'(fp_rect (start 1.2 -1.1) (end 6.42 {maxy+1.1}) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))','(fp_circle (center 2.54 1.27) (end 2.94 1.27) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
 if r.startswith('SW'):pcb += ['(fp_rect (start -2.2 -1.8) (end 2.2 9.42) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))','(fp_rect (start -0.6 2.1) (end 0.6 5.52) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
 if r.startswith('J'):pcb += [f'(fp_rect (start -1.45 -1.45) (end {maxx+1.45} {maxy+1.45}) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
 if r.startswith('D'):
  if isinstance(c.get('monitor'),int):pcb += ['(fp_line (start -1.2 -1.6) (end 1.2 -1.6) (stroke (width 0.15) (type default)) (layer "F.SilkS"))','(fp_circle (center 0 1.27) (end 1.5 1.27) (stroke (width 0.1) (type default)) (fill none) (layer "F.Fab"))']
  else:pcb += ['(fp_line (start -1.6 -1.2) (end -1.6 1.2) (stroke (width 0.15) (type default)) (layer "F.SilkS"))','(fp_circle (center 1.27 0) (end 2.77 0) (stroke (width 0.1) (type default)) (fill none) (layer "F.Fab"))']
 if r=='C2':pcb += ['(fp_text user "+" (at -1.3 -1.5) (layer "F.SilkS") (effects (font (size 1 1) (thickness 0.15))))']
 for pin,(x,y) in pcs.items():
  n=c['pins'][pin];size=1.8 if r.startswith(('U','J')) else 1.6;drill=.9 if r.startswith(('U','J')) else .8
  pcb += [f'(pad {q(pin)} thru_hole {"rect" if pin==1 else "circle"} (at {x} {y}) (size {size} {size}) (drill {drill}) (layers "*.Cu" "*.Mask") (net {netids[n]} {q(n)}))']
 pcb+=[')'];c['coords']={str(p):[round(c['x']+x,5),round(c['y']+y,5)] for p,(x,y) in pcs.items()}
for x,y in [(4,4),(W-4,4),(4,H-4),(W-4,H-4)]:pcb += [f'(footprint "CPU8:MountingHole_3.2mm" (layer "F.Cu") (at {x} {y}) (attr board_only exclude_from_pos_files exclude_from_bom) (pad "" np_thru_hole circle (at 0 0) (size 3.2 3.2) (drill 3.2) (layers "*.Cu" "*.Mask")))']
pcb += [f'(gr_rect (start 0 0) (end {W} {H}) (stroke (width 0.05) (type default)) (fill none) (layer "Edge.Cuts"))',text('CPU8 DATA BUS REV A - 5V - 8 PORTS',85,4,1.2),text('Progettato da Enzo Tasca',149,4,1),text('D0..D7: 1..8 / GND: 9,10 / PIN 1 = SQUARE',78,37,.85),text('ONE WRITER AT A TIME',151,37,.85),text('+5V / GND',222,18,.85),text('LED ON',175,37,.85)]
for c in components:
 if 'monitor' in c:pcb += [text('PWR' if c['monitor']=='PWR' else f'D{c["monitor"]}',c['x']+(0 if isinstance(c['monitor'],int) else 1.27),c['y']+(5.3 if isinstance(c['monitor'],int) else 4.2),1.1)]
pcb += [f'(segment (start 202.62 10) (end 205.16 10) (width 0.6) (layer "F.Cu") (net {netids["+5V"]}))',')']
(OUT/'data_bus_rev_a.kicad_pcb').write_text('\n'.join(pcb))
project={'board':{'design_settings':{'rules':{'min_clearance':.2,'min_track_width':.15,'min_via_diameter':.6,'min_through_hole_diameter':.3}}},'net_settings':{'classes':[{'name':'Default','clearance':.25,'track_width':.3,'via_diameter':.7,'via_drill':.3,'microvia_diameter':.3,'microvia_drill':.1,'bus_width':12,'wire_width':6,'diff_pair_width':.3,'diff_pair_gap':.25,'diff_pair_via_gap':.25}],'meta':{'version':4}},'meta':{'filename':'data_bus_rev_a.kicad_pro','version':1}}
(OUT/'data_bus_rev_a.kicad_pro').write_text(json.dumps(project,indent=2))
(OUT/'netlist.json').write_text(json.dumps(dict(width_mm=W,height_mm=H,root_uuid=rootuuid,components=components,nets=netids),indent=2))
with (ROOT/'BOM.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['Reference','Value','Footprint','Purpose','Mounting_requirement'])
 for c in components:
  r=c['ref']
  spec='C&K SDA01H0BD SPST through-hole; rows 7.62mm; pin 1 OE_n, pin 2 GND; ON closes' if r=='SW1' else 'PDIP-20; rows 7.62mm; add one DIP-20 socket' if r=='U1' else 'Unshrouded 2-row male header; pitch 2.54mm' if r.startswith('J') else 'Bussed SIP-9 8x10k; common pin 1; pitch 2.54mm' if r=='RN1' else '3mm high efficiency LED; pitch 2.54mm; pin 1 cathode' if r.startswith('D') else 'Axial 1/4W 5%; pitch 7.62mm; body <=6.3x2.5mm' if r.startswith('R') else 'Ceramic 100nF 25V; pitch 2.50mm; body <=4x3mm' if r=='C1' else 'Electrolytic 10uF 16V; pitch 2.50mm; diameter <=5mm; pin 1 positive'
  w.writerow([r,c['value'],c['footprint'],c['purpose'],spec])
print(f'Generated {len(components)} components; {W}x{H} mm')
