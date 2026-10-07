"""Self-contained, paginated KiCad schematic with global inter-sheet nets."""
import json
import uuid

def uid(): return str(uuid.uuid4())
def q(s): return json.dumps(str(s))
QUAD=[(1,2,3),(4,5,6),(9,10,8),(12,13,11)]
NOR=[(2,3,1),(5,6,4),(8,9,10),(11,12,13)]
INV=[(1,2),(3,4),(5,6),(9,8),(11,10),(13,12)]

def roles(c):
    k=c.get('kind'); names={}; outs=set()
    if k:
        names[c['n']]='VCC'; names[c['n']//2]='GND'
    if k in ('08','32','86','00','02'):
        for i,(a,b,y) in enumerate(NOR if k=='02' else QUAD,1):
            names.update({a:f'{i}A',b:f'{i}B',y:f'{i}Y'});outs.add(y)
    elif k=='04':
        for i,(a,y) in enumerate(INV,1):names.update({a:f'{i}A',y:f'{i}Y'});outs.add(y)
    elif k=='151':
        names.update(dict(zip([4,3,2,1,15,14,13,12],[f'D{i}' for i in range(8)])))
        names.update({5:'Y',6:'W',7:'G_n',11:'S0',10:'S1',9:'S2'});outs={5,6}
    elif k=='283':
        for i,(a,b,y) in enumerate([(5,6,4),(3,2,1),(14,15,13),(12,11,10)]):
            names.update({a:f'A{i}',b:f'B{i}',y:f'S{i}'});outs.add(y)
        names.update({7:'Cin',9:'Cout'});outs.add(9)
    elif k=='157':
        names.update({1:'S',15:'G_n'})
        for i,(a,b,y) in enumerate([(2,3,4),(5,6,7),(11,10,9),(14,13,12)],1):
            names.update({a:f'{i}A',b:f'{i}B',y:f'{i}Y'});outs.add(y)
    elif k=='244':
        names.update({1:'OE1_n',19:'OE2_n'})
        for i,(a,y) in enumerate([(2,18),(4,16),(6,14),(8,12),(11,9),(13,7),(15,5),(17,3)]):
            names.update({a:f'{i//4+1}A{i%4+1}',y:f'{i//4+1}Y{i%4+1}'});outs.add(y)
    elif k=='138':
        names.update({1:'A',2:'B',3:'C',4:'G2A_n',5:'G2B_n',6:'G1'})
        for i,p in enumerate([15,14,13,12,11,10,9,7]):names[p]=f'Y{i}_n';outs.add(p)
    elif c['ref'].startswith('D'):names={1:'K',2:'A'}
    return names,outs

def library_symbol(c):
    half=(c['n']+1)//2;h=(half-1)*2.54+5.08;names,outs=roles(c)
    lines=[f'(symbol {q(c["ref"])} (pin_names (offset 0.5)) (in_bom yes) (on_board yes)',
           f'(property "Reference" {q(c["ref"].rstrip("0123456789"))} (at 0 {h/2+3} 0) (effects (font (size 1.27 1.27))))',
           f'(property "Value" {q(c["value"])} (at 0 {-h/2-3} 0) (effects (font (size 1.27 1.27))))',
           f'(property "Footprint" {q("CPU8:"+c["footprint"])} (at 0 0 0) (effects (font (size 1.27 1.27)) hide))',
           f'(symbol {q(c["ref"]+"_0_1")} (rectangle (start -10.16 {h/2}) (end 10.16 {-h/2}) (stroke (width 0.254) (type default)) (fill (type background))))',
           f'(symbol {q(c["ref"]+"_1_1")}']
    for p in range(1,c['n']+1):
        left=p<=half;rank=p-1 if left else c['n']-p;x=-15.24 if left else 15.24;y=(half-1)*1.27-rank*2.54
        typ='output' if p in outs else 'power_in' if c.get('kind') and p in (c['n'],c['n']//2) else 'input' if c.get('kind') else 'passive'
        lines.append(f'(pin {typ} line (at {x:.5f} {y:.5f} {0 if left else 180}) (length 5.08) (name {q(names.get(p,"P"+str(p)))} (effects (font (size 1 1)))) (number {q(p)} (effects (font (size 1 1)))))')
    return '\n'.join(lines+['))'])

FLAG='(symbol "PWR_FLAG" (power) (pin_names (offset 0)) (in_bom no) (on_board no) (property "Reference" "#FLG" (at 0 0 0) (effects (font (size 1.27 1.27)) hide)) (property "Value" "PWR_FLAG" (at 0 2.54 0) (effects (font (size 1.27 1.27)))) (symbol "PWR_FLAG_0_1" (polyline (pts (xy 0 0) (xy 0 1.27) (xy -1.27 1.905) (xy 0 2.54) (xy 1.27 1.905) (xy 0 1.27)) (stroke (width 0) (type default)) (fill (type none)))) (symbol "PWR_FLAG_1_1" (pin power_out line (at 0 0 90) (length 0) (name "pwr" (effects (font (size 1.27 1.27)) hide)) (number "1" (effects (font (size 1.27 1.27)) hide)))))'

def embed(definition,name):return definition.replace(f'(symbol {q(name)} ',f'(symbol {q("CPU8:"+name)} ',1)
def global_label(net,x,y,left=True):
    return f'(global_label {q(net)} (shape bidirectional) (at {x:.5f} {y:.5f} 0) (effects (font (size 1 1)) (justify {"right" if left else "left"})) (uuid {uid()}))'

def write_schematic(out,components,root_uuid):
    defs={c['ref']:library_symbol(c) for c in components};defs['PWR_FLAG']=FLAG
    (out/'CPU8.kicad_sym').write_text('(kicad_symbol_lib (version 20231120) (generator "cpu8_alu_generator")\n'+'\n'.join(defs.values())+'\n)')
    (out/'sym-lib-table').write_text('(sym_lib_table (version 7) (lib (name "CPU8") (type "KiCad") (uri "${KIPRJMOD}/CPU8.kicad_sym") (options "") (descr "Self-contained ALU symbols")))')
    (out/'fp-lib-table').write_text('(fp_lib_table (version 7) (lib (name "CPU8") (type "KiCad") (uri "${KIPRJMOD}/CPU8.pretty") (options "") (descr "Self-contained through-hole footprints")))')
    root=[f'(kicad_sch (version 20231120) (generator "cpu8_alu_generator") (uuid {root_uuid}) (paper "A4")',
          '(title_block (title "CPU8 ALU rev B - LED indicators and standalone controls") (date "2026-10-07") (rev "B"))',
          '(lib_symbols '+embed(FLAG,'PWR_FLAG')+')']
    paths={}
    for page,start in enumerate(range(0,len(components),20),1):
        group=components[start:start+20];sheet_uuid=uid();filename=f'alu_rev_b_sheet_{page:02d}.kicad_sch'
        x=20+((page-1)%3)*90;y=40+((page-1)//3)*32
        root += [f'(sheet (at {x} {y}) (size 70 12.7) (stroke (width 0.1524) (type default)) (fill (color 0 0 0 0)) (uuid {sheet_uuid}) (property "Sheetname" {q("Components "+group[0]["ref"]+" to "+group[-1]["ref"])} (at {x} {y-2.54} 0) (effects (font (size 1.27 1.27)) (justify left))) (property "Sheetfile" {q(filename)} (at {x} {y+15.24} 0) (effects (font (size 1.27 1.27)) (justify left))) (instances (project "alu_rev_b" (path {q("/"+root_uuid)} (page {q(page+1)})))))']
        lines=[f'(kicad_sch (version 20231120) (generator "cpu8_alu_generator") (uuid {uid()}) (paper "A2")',
               f'(title_block (title {q("CPU8 ALU rev B - "+group[0]["ref"]+" ... "+group[-1]["ref"])} ) (date "2026-10-07") (rev "B"))',
               '(lib_symbols '+'\n'.join(embed(defs[c['ref']],c['ref']) for c in group)+')']
        for index,c in enumerate(group):
            paths[c['ref']]=sheet_uuid
            x=50.8+(index%5)*111.76;y=50.8+(index//5)*86.36;half=(c['n']+1)//2;h=(half-1)*2.54+5.08
            lines += [f'(symbol (lib_id {q("CPU8:"+c["ref"])}) (at {x:.5f} {y:.5f} 0) (unit 1) (in_bom yes) (on_board yes) (dnp no) (uuid {c["uuid"]})',
                      f'(property "Reference" {q(c["ref"])} (at {x:.5f} {y-h/2-4:.5f} 0) (effects (font (size 1.27 1.27))))',
                      f'(property "Value" {q(c["value"])} (at {x:.5f} {y+h/2+4:.5f} 0) (effects (font (size 1.27 1.27))))',
                      f'(property "Footprint" {q("CPU8:"+c["footprint"])} (at {x:.5f} {y:.5f} 0) (effects (font (size 1.27 1.27)) hide))']
            lines += [f'(pin {q(p)} (uuid {uid()}))' for p in range(1,c['n']+1)]
            lines += [f'(instances (project "alu_rev_b" (path {q("/"+root_uuid+"/"+sheet_uuid)} (reference {q(c["ref"])}) (unit 1))))',')']
            for p in range(1,c['n']+1):
                left=p<=half;rank=p-1 if left else c['n']-p
                px=x+(-15.24 if left else 15.24);py=y-((half-1)*1.27-rank*2.54);net=c['pins'].get(p)
                if net is None:lines.append(f'(no_connect (at {px:.5f} {py:.5f}) (uuid {uid()}))');continue
                ex=px+(-5.08 if left else 5.08)
                lines += [f'(wire (pts (xy {px:.5f} {py:.5f}) (xy {ex:.5f} {py:.5f})) (stroke (width 0) (type default)) (uuid {uid()}))',global_label(net,ex,py,left)]
        lines+=[')'];(out/filename).write_text('\n'.join(lines))
    for i,net in enumerate(['+5V','GND'],1):
        x=20.32+i*30.48;y=180.34;u=uid()
        root += [f'(symbol (lib_id "CPU8:PWR_FLAG") (at {x} {y} 0) (unit 1) (in_bom no) (on_board no) (dnp no) (uuid {u}) (property "Reference" "#FLG0{i}" (at {x} {y} 0) (effects (font (size 1.27 1.27)) hide)) (property "Value" "PWR_FLAG" (at {x} {y-2.54} 0) (effects (font (size 1.27 1.27)))) (pin "1" (uuid {uid()})) (instances (project "alu_rev_b" (path {q("/"+root_uuid)} (reference "#FLG0{i}") (unit 1)))))',global_label(net,x,y)]
    note='SW4 OFF: external A/B/OP/enable; ON: local DIP switches\nSW5 OFF: local bus disabled; ON: local bus enabled\nLEDs monitor selected operands and flags; OP LEDs are one-hot\n5V HCT, RA/RB and flag storage remain external'
    root += [f'(text {q(note)} (at 140 178 0) (effects (font (size 1.27 1.27)) (justify left)) (uuid {uid()}))','(sheet_instances (path "/" (page "1")))',')']
    (out/'alu_rev_b.kicad_sch').write_text('\n'.join(root))
    return paths
