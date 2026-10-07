#!/usr/bin/env python3
"""Self-contained KiCad source generator for CPU8 ALU rev B.

Rebuilding creates an UNROUTED board and requires rerouting and new checks.
"""
import argparse
import csv
import json
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'source'
OUT.mkdir(exist_ok=True)
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--rebuild-unrouted',action='store_true')
args=parser.parse_args()
if (OUT/'alu_rev_b.kicad_pcb').exists() and not args.rebuild_unrouted:
    raise SystemExit('Existing PCB preserved. Use --rebuild-unrouted only to restart layout and routing.')
components = []
chips = []
counts = {}
def uid(): return str(uuid.uuid4())
def q(s): return json.dumps(str(s))

QUAD = [(1,2,3),(4,5,6),(9,10,8),(12,13,11)]
NOR = [(2,3,1),(5,6,4),(8,9,10),(11,12,13)]
INV = [(1,2),(3,4),(5,6),(9,8),(11,10),(13,12)]
KINDS = {'08':'AND','32':'OR','86':'XOR','00':'NAND','02':'NOR','04':'NOT'}
def component(prefix, value, n, footprint, pins=None, purpose=''):
    counts[prefix] = counts.get(prefix,0)+1
    c = dict(ref=f'{prefix}{counts[prefix]}', value=value, n=n,
             footprint=footprint,pins=pins or {},purpose=purpose,uuid=uid())
    components.append(c)
    return c

def chip(kind, purpose):
    n = 20 if kind=='244' else 16 if kind in ('151','283','157','138') else 14
    c = component('U', '74HCT'+kind, n, f'DIP-{n}_W7.62mm', purpose=purpose)
    c['kind']=kind; c['pins'][n]='+5V'; c['pins'][n//2]='GND'
    c['used']=0; chips.append(c)
    return c

pools = {}
def gate(kind, inputs, output, purpose):
    if kind not in pools or pools[kind]['used']==(6 if kind=='04' else 4):
        pools[kind] = chip(kind,purpose)
    c=pools[kind]; slot=c['used']; c['used']+=1
    pins=INV[slot] if kind=='04' else (NOR if kind=='02' else QUAD)[slot]
    for pin,net in zip(pins, inputs+[output]): c['pins'][pin]=net
    return output

# Data paths. Parallel logic outputs remain private to the multiplexers.
for kind,name in [('08','AND'),('32','OR'),('86','XOR'),('02','NOR'),('00','NAND')]:
    for b in range(8): gate(kind,[f'A{b}',f'B{b}'],f'{name}{b}',name)
for b in range(8): gate('04',[f'XOR{b}'],f'XNOR{b}','XNOR / NOT')
for b in range(8): gate('04',[f'A{b}'],f'NOT{b}','XNOR / NOT')
for b in range(8): gate('86',[f'B{b}','OP3'],f'BX{b}','B complement')

for h in range(2):
    c=chip('283',f'Adder bits {4*h}..{4*h+3}')
    c['pins'][7]='OP3' if h==0 else 'C4'
    c['pins'][9]='C4' if h==0 else 'C8'
    for i,(ap,bp,sp) in enumerate([(5,6,4),(3,2,1),(14,15,13),(12,11,10)]):
        b=h*4+i
        c['pins'][ap]=f'A{b}'; c['pins'][bp]=f'BX{b}'; c['pins'][sp]=f'SUM{b}'

for b in range(8):
    c=chip('151',f'Result select bit {b}')
    for p,net in zip([4,3,2,1,15,14,13,12],
                     [f'{name}{b}' for name in ['AND','OR','XOR','NOR','NAND','XNOR','NOT','SUM']]):
        c['pins'][p]=net
    c['pins'].update({5:f'R{b}',7:'GND',11:'SEL0',10:'SEL1',9:'SEL2'})
    # Complementary W output, pin 6, intentionally unconnected.

for b in range(3): gate('32',[f'OP{b}','OP3'],f'SEL{b}','Opcode / output control')
gate('32',['OP0','OP1'],'LOW01','Opcode / output control')
gate('32',['LOW01','OP2'],'LOW_ANY','Opcode / output control')
gate('08',['OP3','LOW_ANY'],'NO_BUS_HIGH','Opcode / output control')
gate('32',['ALU_EN_n','NO_BUS_HIGH'],'BUS_OE_n','Opcode / output control')
gate('08',['OP0','OP1'],'LOW_AND01','Arithmetic flag qualification')
gate('08',['LOW_AND01','OP2'],'LOW_AND012','Arithmetic flag qualification')
gate('32',['LOW_AND012','OP3'],'ARITH','Arithmetic flag qualification')
gate('86',['C8','OP3'],'C_RAW','Carry / overflow')
gate('08',['C_RAW','ARITH'],'C','Carry / overflow')
gate('86',['A7','BX7'],'SIGN_XOR','Carry / overflow')
gate('04',['SIGN_XOR'],'SIGN_EQ','Carry / overflow')
gate('86',['A7','SUM7'],'SIGN_CHANGED','Carry / overflow')
gate('08',['SIGN_EQ','SIGN_CHANGED'],'O_RAW','Carry / overflow')
gate('08',['O_RAW','ARITH'],'O','Carry / overflow')
# Balanced zero-detect tree from internal result (works with disabled bus).
for b in range(4): gate('32',[f'R{2*b}',f'R{2*b+1}'],f'Z_PAIR{b}','Zero flag')
gate('32',['Z_PAIR0','Z_PAIR1'],'Z_HALF0','Zero flag')
gate('32',['Z_PAIR2','Z_PAIR3'],'Z_HALF1','Zero flag')
gate('32',['Z_HALF0','Z_HALF1'],'NONZERO','Zero flag')
gate('04',['NONZERO'],'Z','Zero flag')

c=chip('244','Shared bus output')
c['pins'].update({1:'BUS_OE_n',19:'BUS_OE_n'})
for b,(ip,op) in enumerate([(2,18),(4,16),(6,14),(8,12),(11,9),(13,7),(15,5),(17,3)]):
    c['pins'][ip]=f'R{b}'; c['pins'][op]=f'D{b}'

# Select external connector pins or local DIP switches for all inputs,
# including the output-enable control. Local sources never drive the headers.
selection=[(f'EXT_A{i}',f'LOCAL_A{i}',f'A{i}') for i in range(8)]
selection += [(f'EXT_B{i}',f'LOCAL_B{i}',f'B{i}') for i in range(8)]
selection += [(f'EXT_OP{i}',f'LOCAL_OP{i}',f'OP{i}') for i in range(4)]
selection += [('EXT_ALU_EN_n','LOCAL_ALU_EN_n','ALU_EN_n')]
MUX157=[(2,3,4),(5,6,7),(11,10,9),(14,13,12)]
for start in range(0,len(selection),4):
    c=chip('157','External / standalone input selection')
    c['pins'].update({1:'MODE_LOCAL',15:'GND'})
    for channel,(ap,bp,yp) in enumerate(MUX157):
        if start+channel<len(selection):
            external,local,result=selection[start+channel]
            c['pins'].update({ap:external,bp:local,yp:result})
        else: c['pins'].update({ap:'GND',bp:'GND'})

# Buffer the indicators so LEDs do not load the operand/flag logic.
monitors=[(f'A{i}',f'A{i}','GREEN') for i in range(7,-1,-1)]
monitors += [(f'B{i}',f'B{i}','GREEN') for i in range(7,-1,-1)]
monitors += [('C','C','YELLOW'),('Z','Z','YELLOW'),('R7','N','YELLOW'),('O','O','YELLOW')]
for start in range(0,len(monitors),8):
    c=chip('244','Operand / flag LED driver')
    c['pins'].update({1:'GND',19:'GND'})
    for ch,(ip,op) in enumerate([(2,18),(4,16),(6,14),(8,12),(11,9),(13,7),(15,5),(17,3)]):
        if start+ch<len(monitors):
            signal,label,color=monitors[start+ch]
            c['pins'].update({ip:signal,op:f'LED_{label}_DRIVE'})
        else: c['pins'][ip]='GND'

# Active-low, one-hot opcode decoder: exactly one valid operation LED.
gate('04',['OP3'],'OP3_n','Opcode LED decoder enable')
OP_NAMES=['AND','OR','XOR','NOR','NAND','XNOR','NOT','ADD','SUB','CMP']
for bank in range(2):
    c=chip('138','Operation LED decoder')
    c['pins'].update({1:'OP0',2:'OP1',3:'OP2',4:'GND',5:'GND',6:'OP3_n' if bank==0 else 'OP3'})
    for index,pin in enumerate([15,14,13,12,11,10,9,7]):
        if bank*8+index<10:c['pins'][pin]=f'OP_{OP_NAMES[bank*8+index]}_n'

# Tie every unused gate input to ground; unused outputs have no copper net.
for c in chips:
    kind=c['kind']
    if kind in KINDS:
        groups=INV if kind=='04' else NOR if kind=='02' else QUAD
        for ps in groups[c['used']:]:
            for p in ps[:-1]: c['pins'][p]='GND'

# Placement leaves channels between all DIP packages and room for sockets.
for i,c in enumerate(chips):
    if i<33:
        c['x']=24+(i%7)*25; c['y']=106+(i//7)*36
    else:
        c['x']=213+((i-33)%3)*25; c['y']=106+((i-33)//3)*36
    half=c['n']//2
    # Capacitor 2.54mm from VCC on top right, with short direct VCC stub.
    cap=component('C','100nF',2,'C_Disc_P2.50mm', {1:'+5V',2:'GND'},'Local bypass')
    cap['x']=c['x']+10.16; cap['y']=c['y']
    c['bypass']=cap['ref']

headers=[
    ('A_INPUT', [f'EXT_A{i}' for i in range(8)]+['GND','GND'],10,10),
    ('B_INPUT', [f'EXT_B{i}' for i in range(8)]+['GND','GND'],42,10),
    ('CONTROL', ['EXT_OP0','EXT_OP1','EXT_OP2','EXT_OP3','EXT_ALU_EN_n','GND','GND','GND'],76,10),
    ('DATA_BUS', [f'D{i}' for i in range(8)]+['GND','GND'],148,259),
    ('FLAGS_CZNO', ['C','Z','R7','O','GND','GND'],146,10),
    ('POWER_5V', ['+5V','GND','+5V','GND'],178,10),
    ('RESULT_TEST', [f'R{i}' for i in range(8)]+['GND','GND'],185,259),
]
for name,nets,x,y in headers:
    c=component('J',name,len(nets),f'Header_2x{len(nets)//2}_P2.54mm',
                {i+1:net for i,net in enumerate(nets)},name)
    c['x']=x; c['y']=y

for i,nets in enumerate([[f'EXT_A{b}' for b in range(8)],[f'EXT_B{b}' for b in range(8)],
                         [f'EXT_OP{b}' for b in range(4)]+['GND']*4,
                         [f'LOCAL_A{b}' for b in range(8)],[f'LOCAL_B{b}' for b in range(8)],
                         [f'LOCAL_OP{b}' for b in range(4)]+['GND']*4]):
    c=component('RN','10k_Bussed_SIP9',9,'SIP-9_P2.54mm',
                {1:'GND',**{b+2:net for b,net in enumerate(nets)}},'Input pull-downs')
    c['x']=16+i*43; c['y']=286
c=component('R','4.7k',2,'R_Axial_P7.62mm',{1:'+5V',2:'EXT_ALU_EN_n'},'External default bus disable')
c['x']=205; c['y']=260
c=component('C','10uF_16V',2,'C_Radial_P2.50mm',{1:'+5V',2:'GND'},'Supply bulk')
c['x']=187; c['y']=24

for prefix,positions,x in [('A',8,18),('B',8,62),('OP',4,108)]:
    c=component('SW',f'LOCAL_{prefix}',positions*2,f'SW_DIP_SPST_{positions}_P2.54_W7.62',purpose='Local input DIP switches')
    c['positions']=positions; c['contacts']=[]
    for i in range(positions):
        signal=f'LOCAL_{prefix}{positions-1-i}'
        c['pins'][i+1]=signal; c['pins'][positions*2-i]='+5V'
        c['contacts'].append([i+1,positions*2-i,signal])
    c['x']=x;c['y']=84
c=component('SW','MODE_LOCAL',2,'SW_DIP_SPST_1_P2.54_W7.62',{1:'MODE_LOCAL',2:'+5V'},'OFF=external, ON=standalone')
c['positions']=1;c['contacts']=[[1,2,'MODE_LOCAL']];c['x']=230;c['y']=28
c=component('SW','LOCAL_BUS_ENABLE',2,'SW_DIP_SPST_1_P2.54_W7.62',{1:'LOCAL_ALU_EN_n',2:'GND'},'OFF=bus disabled, ON=bus enabled in standalone')
c['positions']=1;c['contacts']=[[1,2,'LOCAL_ALU_EN_n']];c['x']=259;c['y']=28
c=component('R','10k',2,'R_Axial_P7.62mm',{1:'MODE_LOCAL',2:'GND'},'Default external mode')
c['x']=237;c['y']=248
c=component('R','4.7k',2,'R_Axial_P7.62mm',{1:'+5V',2:'LOCAL_ALU_EN_n'},'Local default bus disable')
c['x']=263;c['y']=248

for signal,label,color in monitors:
    if label.startswith('A') or label.startswith('B'):
        bit=int(label[1]);x=16+(7-bit)*14;y=38 if label[0]=='A' else 65
    else:x=150+['C','Z','N','O'].index(label)*17;y=35
    r=component('R','2.2k',2,'R_Axial_P7.62mm',{1:f'LED_{label}_DRIVE',2:f'LED_{label}_A'},f'{label} LED series resistor')
    r['x']=x-7.62;r['y']=y-10
    led=component('D',color,2,'LED_D3.0mm_P2.54mm',{1:'GND',2:f'LED_{label}_A'},f'Selected {label} indicator')
    led['x']=x;led['y']=y;led['monitor']={'signal':signal,'label':label,'active_low':False,'resistor':r['ref']}

for i,name in enumerate(OP_NAMES):
    x=150+(i%5)*23;y=65+(i//5)*21
    r=component('R','2.2k',2,'R_Axial_P7.62mm',{1:'+5V',2:f'LED_{name}_A'},f'{name} LED series resistor')
    r['x']=x-7.62;r['y']=y-10
    led=component('D','BLUE',2,'LED_D3.0mm_P2.54mm',{1:f'OP_{name}_n',2:f'LED_{name}_A'},f'{name} selected indicator')
    led['x']=x;led['y']=y;led['monitor']={'opcode':i,'label':name,'active_low':True,'resistor':r['ref']}

netnames=sorted({n for c in components for n in c['pins'].values()})
netids={n:i+1 for i,n in enumerate(netnames)}
rootuuid=uid()
W,H=290,300

def padcoords(c):
    if c['ref'].startswith('SW'):
        n=c['positions']
        return {**{p:((p-1)*2.54,0) for p in range(1,n+1)},
                **{p:((2*n-p)*2.54,7.62) for p in range(n+1,2*n+1)}}
    if c['ref'].startswith('D'):return {1:(0,0),2:(2.54,0)}
    if c['ref'].startswith('U'):
        half=c['n']//2
        return {**{p:(0,(p-1)*2.54) for p in range(1,half+1)},
                **{p:(7.62,(c['n']-p)*2.54) for p in range(half+1,c['n']+1)}}
    if c['ref'].startswith('J'):
        return {p:((p-1)%2*2.54,(p-1)//2*2.54) for p in range(1,c['n']+1)}
    pitch=7.62 if c['ref'].startswith('R') and not c['ref'].startswith('RN') else 2.54 if c['ref'].startswith('RN') else 2.5
    return {p:((p-1)*pitch,0) for p in range(1,c['n']+1)}

def textpcb(s,x,y,size=1.1):
    return f'(gr_text {q(s)} (at {x} {y}) (layer "F.SilkS") (effects (font (size {size} {size}) (thickness 0.16))))'

pcb=['(kicad_pcb (version 20221018) (generator "cpu8_alu_generator")',
     '(general (thickness 1.6)) (paper "A4")',
     '(layers (0 "F.Cu" signal) (31 "B.Cu" signal) (36 "B.SilkS" user "b.silkscreen") (37 "F.SilkS" user "f.silkscreen") (38 "B.Mask" user) (39 "F.Mask" user) (44 "Edge.Cuts" user) (46 "B.CrtYd" user) (47 "F.CrtYd" user) (48 "B.Fab" user) (49 "F.Fab" user))',
     '(setup (pad_to_mask_clearance 0.05))', '(net 0 "")']
pcb += [f'(net {netids[n]} {q(n)})' for n in netnames]
for c in components:
    pcs=padcoords(c); xs=[p[0] for p in pcs.values()]; ys=[p[1] for p in pcs.values()]
    maxx,maxy=max(xs),max(ys)
    pcb += [f'(footprint {q("CPU8:"+c["footprint"])} (layer "F.Cu") (at {c["x"]} {c["y"]}) (tstamp {c["uuid"]})',
            f'(path {q("/"+rootuuid+"/"+c["uuid"])}) (attr through_hole)',
            f'(fp_text reference {q(c["ref"])} (at {maxx/2} {-3 if c["ref"].startswith(("J","D","SW")) else -2}) (layer "F.SilkS") (effects (font (size 1 1) (thickness 0.15))))',
            f'(fp_text value {q(c["value"])} (at {maxx/2} {maxy+2.3}) (layer {q("F.Fab" if c["ref"].startswith(("D","SW")) else "F.SilkS")}) (effects (font (size 0.85 0.85) (thickness 0.15))))']
    # Body outline is inset from pads; pin-one square identifies orientation.
    if c['ref'].startswith('U'):
        pcb += [f'(fp_rect (start 1.2 -1.1) (end 6.42 {maxy+1.1}) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))',
                '(fp_circle (center 2.54 1.27) (end 2.94 1.27) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
    if c['ref'].startswith('J'):
        pcb += [f'(fp_rect (start -1.45 -1.45) (end {maxx+1.45} {maxy+1.45}) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
    if c['ref'].startswith('SW'):
        pcb += [f'(fp_rect (start -2.2 -1.8) (end {maxx+2.2} 9.42) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
        for i in range(c['positions']):
            pcb += [f'(fp_rect (start {i*2.54-0.6} 2.1) (end {i*2.54+0.6} 5.52) (stroke (width 0.15) (type default)) (fill none) (layer "F.SilkS"))']
    if c['ref'].startswith('D'):
        pcb += ['(fp_line (start -1.6 -1.2) (end -1.6 1.2) (stroke (width 0.15) (type default)) (layer "F.SilkS"))',
                '(fp_circle (center 1.27 0) (end 2.77 0) (stroke (width 0.1) (type default)) (fill none) (layer "F.Fab"))']
    for p,(x,y) in pcs.items():
        net=c['pins'].get(p)
        size=1.8 if c['ref'].startswith(('U','J')) else 1.6
        drill=0.9 if c['ref'].startswith(('U','J')) else 0.8
        shape='rect' if p==1 else 'circle'
        ns=f'(net {netids[net]} {q(net)})' if net else ''
        pcb += [f'(pad {q(p)} thru_hole {shape} (at {x} {y}) (size {size} {size}) (drill {drill}) (layers "*.Cu" "*.Mask") {ns})']
    pcb += [')']
    c['coords']={str(p):[round(c['x']+x,5),round(c['y']+y,5)] for p,(x,y) in pcs.items()}
for x,y in [(4,4),(W-4,4),(4,H-4),(W-4,H-4)]:
    pcb += [f'(footprint "CPU8:MountingHole_3.2mm" (layer "F.Cu") (at {x} {y}) (attr board_only exclude_from_pos_files exclude_from_bom) (pad "" np_thru_hole circle (at 0 0) (size 3.2 3.2) (drill 3.2) (layers "*.Cu" "*.Mask")))']
pcb += [f'(gr_rect (start 0 0) (end {W} {H}) (stroke (width 0.05) (type default)) (fill none) (layer "Edge.Cuts"))',
        textpcb('CPU8 ALU REV B - 5V HCT - EXTERNAL / STANDALONE',145,4,1.3),
        textpcb('PIN 1 = SQUARE PAD / DIP NOTCH AT TOP',145,298,1),
        textpcb('A0..A7',16,24),textpcb('B0..B7',48,24),textpcb('OP / EN_n',82,22),
        textpcb('D0..D7',154,274),textpcb('C Z N O',150,20),textpcb('+5V GND',182,17),
        textpcb('R0..R7 TEST',188,274),
        textpcb('A 7 6 5 4 3 2 1 0',32,79),textpcb('B 7 6 5 4 3 2 1 0',76,79),
        textpcb('OP 3 2 1 0',112,79),textpcb('SW4 ON = LOCAL',230,43),
        textpcb('SW5 ON = BUS',263,43)]
for c in components:
    if 'monitor' in c:pcb += [textpcb(c['monitor']['label'],c['x']+1.27,c['y']+4.2,1.1)]
# Pre-route each bypass VCC with a short, wide segment.
for c in chips:
    pcb += [f'(segment (start {c["x"]+7.62} {c["y"]}) (end {c["x"]+10.16} {c["y"]}) (width 0.6) (layer "F.Cu") (net {netids["+5V"]}))']
pcb += [')']
(OUT/'alu_rev_b.kicad_pcb').write_text('\n'.join(pcb))

# Paginate the schematic and update each footprint's hierarchy path.
from schematic_writer import write_schematic
sheet_paths=write_schematic(OUT,components,rootuuid)
boardpath=OUT/'alu_rev_b.kicad_pcb'
boardtext=boardpath.read_text()
for c in components:
    boardtext=boardtext.replace(q('/'+rootuuid+'/'+c['uuid']),q('/'+rootuuid+'/'+sheet_paths[c['ref']]+'/'+c['uuid']))
boardpath.write_text(boardtext)

project={'board':{'design_settings':{'rules':{'min_clearance':0.2,'min_track_width':0.15,'min_via_diameter':0.6,'min_through_hole_diameter':0.3}}},'net_settings':{'classes':[{'name':'Default','clearance':0.25,'track_width':0.3,'via_diameter':0.7,'via_drill':0.3,'microvia_diameter':0.3,'microvia_drill':0.1,'bus_width':12,'wire_width':6,'diff_pair_width':0.3,'diff_pair_gap':0.25,'diff_pair_via_gap':0.25}], 'meta':{'version':4}},'meta':{'filename':'alu_rev_b.kicad_pro','version':1}}
(OUT/'alu_rev_b.kicad_pro').write_text(json.dumps(project,indent=2))
(OUT/'netlist.json').write_text(json.dumps({'width_mm':W,'height_mm':H,'root_uuid':rootuuid,'components':components,'nets':netids},indent=2))
from bom_writer import write_bom
write_bom(ROOT/'BOM.csv',components)
print(f'Generated {len(chips)} ICs, {len(components)} components, {len(netnames)} nets; {W} x {H} mm')
