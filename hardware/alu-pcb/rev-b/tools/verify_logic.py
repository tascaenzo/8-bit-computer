#!/usr/bin/env python3
"""Exhaustive pin-level evaluation of the generated package netlist.

Each integer holds 65,536 cases in parallel, one for each A/B combination.
Package models are independent of the generator's gate allocation order.
"""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/'source/netlist.json').read_text())
# Ensure the independent models evaluate the exported schematic connectivity.
import xml.etree.ElementTree as ET
actual={}
for net in ET.parse(ROOT/'source/schematic.xml').findall('./nets/net'):
    for node in net.findall('node'):
        actual[(node.attrib['ref'],node.attrib['pin'])]=net.attrib['name']
for c in d['components']:
    for pin,net in c['pins'].items():
        assert actual.get((c['ref'],pin))==net,f'Schematic differs at {c["ref"]}.{pin}'
chips=[c for c in d['components'] if c['ref'].startswith('U')]
MASK=(1<<65536)-1
QUAD=[(1,2,3),(4,5,6),(9,10,8),(12,13,11)]
NOR=[(2,3,1),(5,6,4),(8,9,10),(11,12,13)]
INV=[(1,2),(3,4),(5,6),(9,8),(11,10),(13,12)]
def pattern(fn):
    return int(''.join('1' if fn(a,b) else '0' for a in range(255,-1,-1) for b in range(255,-1,-1)),2)

base={'GND':0,'+5V':MASK}
for i in range(8):
    base[f'PAT_A{i}']=pattern(lambda a,b,i=i: (a>>i)&1)
    base[f'PAT_B{i}']=pattern(lambda a,b,i=i: (b>>i)&1)

tasks=[]
drivers={}
input_pins=[]
for c in chips:
    p={int(k):v for k,v in c['pins'].items()}; k=c['kind']; ref=c['ref']
    assert p[c['n']]=='+5V' and p[c['n']//2]=='GND'
    def task(ins,outs,model):
        for pin in ins: assert pin in p, f'{ref}.{pin}: floating input'
        for pin in outs:
            if pin in p:
                assert p[pin] not in drivers, f'Multiple drivers on {p[pin]}'
                drivers[p[pin]]=f'{ref}.{pin}'
        input_pins.extend((ref,pin,p[pin]) for pin in ins)
        tasks.append((ref,p,ins,outs,model))
    if k in ['08','32','86','00','02']:
        for a,b,y in NOR if k=='02' else QUAD:
            task([a,b],[y],k)
    elif k=='04':
        for a,y in INV: task([a],[y],k)
    elif k=='151': task([4,3,2,1,15,14,13,12,11,10,9,7],[5,6],k)
    elif k=='283': task([5,6,3,2,14,15,12,11,7],[4,1,13,10,9],k)
    elif k=='157': task([2,3,5,6,11,10,14,13,1,15],[4,7,9,12],k)
    elif k=='138': task([1,2,3,4,5,6],[15,14,13,12,11,10,9,7],k)
    elif k=='244': task([2,4,6,8,11,13,15,17,1,19],[18,16,14,12,9,7,5,3],k)
    else: raise AssertionError(k)

def evaluate(op,en,mode):
    nets={'GND':0,'+5V':MASK,'MODE_LOCAL':MASK if mode else 0}
    for source in ('EXT','LOCAL'):
        selected=(source=='LOCAL')==bool(mode)
        for i in range(8):
            for operand in ('A','B'):
                value=base[f'PAT_{operand}{i}']
                nets[f'{source}_{operand}{i}']=value if selected else MASK^value
        for i in range(4):
            value=MASK if op&(1<<i) else 0
            nets[f'{source}_OP{i}']=value if selected else MASK^value
        value=MASK if en else 0
        nets[f'{source}_ALU_EN_n']=value if selected else MASK^value
    pending=list(tasks); tristate={}
    while pending:
        remaining=[]; progressed=False
        for ref,p,ins,outs,k in pending:
            if not all(p[pin] in nets for pin in ins):
                remaining.append((ref,p,ins,outs,k)); continue
            progressed=True; x=[nets[p[pin]] for pin in ins]
            if k=='08': ys=[x[0]&x[1]]
            elif k=='32': ys=[x[0]|x[1]]
            elif k=='86': ys=[x[0]^x[1]]
            elif k=='00': ys=[MASK^(x[0]&x[1])]
            elif k=='02': ys=[MASK^(x[0]|x[1])]
            elif k=='04': ys=[MASK^x[0]]
            elif k=='283':
                carry=x[8]; ys=[]
                for bit in range(4):
                    a,b=x[2*bit:2*bit+2]
                    ys.append(a^b^carry); carry=(a&b)|(a&carry)|(b&carry)
                ys.append(carry)
            elif k=='151':
                selectors=x[8:11]; value=0
                for index in range(8):
                    take=MASK
                    for bit in range(3): take &= selectors[bit] if index&(1<<bit) else MASK^selectors[bit]
                    value |= take & x[index]
                value &= MASK^x[11]
                ys=[value,MASK^value]
            elif k=='157':
                sel=x[8]; gate=MASK^x[9]
                ys=[((x[2*i]&(MASK^sel))|(x[2*i+1]&sel))&gate for i in range(4)]
            elif k=='138':
                enable=x[5]&(MASK^x[3])&(MASK^x[4]);ys=[]
                for index in range(8):
                    take=enable
                    for bit in range(3):take &= x[bit] if index&(1<<bit) else MASK^x[bit]
                    ys.append(MASK^take)
            elif k=='244':
                for i,pin in enumerate(outs):
                    enable=MASK^x[8 if i<4 else 9]
                    if pin in p: tristate[p[pin]]=enable
                ys=x[:8]
            for pin,y in zip(outs,ys):
                if pin in p: nets[p[pin]]=y
        assert progressed, f'Unresolved network: {[t[0] for t in remaining]}'
        pending=remaining
    return nets,tristate

def reference(a,b,op):
    if op==0: r=a&b
    elif op==1: r=a|b
    elif op==2: r=a^b
    elif op==3: r=~(a|b)&255
    elif op==4: r=~(a&b)&255
    elif op==5: r=~(a^b)&255
    elif op==6: r=~a&255
    elif op==7: r=(a+b)&255
    else: r=(a-b)&255
    c=0; o=0
    if op==7:
        c=int(a+b>255); o=int(bool((~(a^b)&(a^r))&128))
    elif op in (8,9):
        c=int(a<b); o=int(bool(((a^b)&(a^r))&128))
    return r, c, int(r==0), (r>>7)&1, o

for op in range(16):
    expected={}
    if op<10:
        results=[reference(a,b,op) for a in range(256) for b in range(256)]
        def packed(fn): return int(''.join('1' if fn(v) else '0' for v in reversed(results)),2)
        expected.update({f'R{i}':packed(lambda v,i=i:(v[0]>>i)&1) for i in range(8)})
        for i,name in enumerate(['C','Z','R7','O'],1): expected[name]=packed(lambda v,i=i:v[i])
    for mode in range(2):
        for en in range(2):
            nets,tri=evaluate(op,en,mode)
            for net,want in expected.items(): assert nets[net]==want, f'OP {op}, EN {en}, MODE {mode}: {net} mismatch'
            enabled=MASK if not en and op<9 else 0
            for i in range(8):
                assert tri[f'D{i}']==enabled, f'OP {op}, EN {en}: bus enable mismatch'
                if enabled: assert nets[f'D{i}']==expected[f'R{i}']
                for operand in ('A','B'):assert nets[f'{operand}{i}']==base[f'PAT_{operand}{i}']
            for c in d['components']:
                if 'monitor' not in c:continue
                m=c['monitor'];r=next(r for r in d['components'] if r['ref']==m['resistor'])
                assert r['value']=='2.2k'
                cathode=c['pins']['1'];anode=c['pins']['2']
                assert r['pins']['2']==anode
                if m['active_low']:
                    assert r['pins']['1']=='+5V'
                    assert nets[cathode]==(0 if op==m['opcode'] else MASK),f'Operation LED {c["ref"]}'
                else:
                    assert cathode=='GND'
                    assert nets[r['pins']['1']]==nets[m['signal']],f'Operand/flag LED {c["ref"]}'
# Check real mechanical contacts and pull networks; no local contact drives an external input.
for c in d['components']:
    if c['ref'] in ('SW1','SW2','SW3'):
        for a,b,signal in c['contacts']:
            assert signal.startswith('LOCAL_')
            assert c['pins'][str(a)]==signal and c['pins'][str(b)]=='+5V'
    if c['ref'].startswith('RN'):
        assert c['pins']['1']=='GND'
        assert '10k' in c['value']
print('PASS: 4,194,304 A/B/OP/enable combinations; all ten operations and flags; tri-state for CMP/reserved/disabled.')
report={'status':'PASS','input_cases':65536*16*2*2,'tested_operations':list(range(10)),
        'checks':['Actual IC pin netlist simulation','Carry/borrow convention','Signed overflow','Zero/negative independent of bus enable','CMP bus isolation','Reserved opcode isolation','Unused inputs tied','No duplicate push-pull drivers','External/local source isolation including opcode and enable','Selected A/B LED buffers','Four flag LED buffers','Ten one-hot operation LEDs','Local switch contacts and pull-down networks'],
        'limitations':['Static digital logic verification; propagation delays, loading and hardware operation require prototype measurements.']}
(ROOT/'verification/logic-report.json').write_text(json.dumps(report,indent=2))
