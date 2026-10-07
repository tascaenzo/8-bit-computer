#!/usr/bin/env python3
"""Verify exported pin connectivity and every 16-bit address display value."""
import json,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/'source/netlist.json').read_text());cs={c['ref']:c for c in d['components']}
actual={};members={}
for net in ET.parse(ROOT/'source/schematic.xml').findall('./nets/net'):
 name=net.attrib['name'];members[name]=[]
 for node in net.findall('node'):
  pair=(node.attrib['ref'],node.attrib['pin']);actual[pair]=name;members[name].append(pair)
for c in cs.values():
 for p,n in c['pins'].items():assert actual[(c['ref'],p)]==n,(c['ref'],p,n)
port_pins=[f'A{i}' for i in range(16)]+['GND']*4
for ref in [f'J{i}' for i in range(1,9)]:
 assert [actual[(ref,str(i))] for i in range(1,21)]==port_pins
assert [actual[('J9',str(i))] for i in range(1,5)]==['+5V','GND','+5V','GND']
# SW1 closes OE_n to GND; R10/R18 provides a defined HIGH when open.
assert actual[('SW1','1')]=='LED_OE_n' and actual[('SW1','2')]=='GND'
assert actual[('R18','1')]=='+5V' and actual[('R18','2')]=='LED_OE_n'
assert cs['R18']['value']=='10k'
assert cs['SW1']['value']=='SDA01H0BD_LED_ENABLE'
expected_oe={('SW1','1'),('R18','2')} | {(f'U{i}',p) for i in range(1,3) for p in ('1','19')}
assert set(members['LED_OE_n'])==expected_oe, 'OE control must not touch any bus line'
ordered=sorted((c['x'],c['monitor']) for c in cs.values() if isinstance(c.get('monitor'),int))
assert [bit for x,bit in ordered]==list(range(15,-1,-1)), 'Display must be MSB on left'
assert all(abs((ordered[i+1][0]-ordered[i][0])-(6 if (i+1)%4==0 else 4))<1e-6 for i in range(15)), 'Compact 4mm LED spacing / nibble gaps'
# Physical SN74HCT244 non-inverting input/output pairs, independent of generator order.
channels=[(2,18),(4,16),(6,14),(8,12),(17,3),(15,5),(13,7),(11,9)]
input_pins={a for a,y in channels};output_pins={y for a,y in channels}
for ref in ('U1','U2'):
 assert actual[(ref,'20')]=='+5V'
 assert actual[(ref,'10')]=='GND'
 assert actual[(ref,'1')]==actual[(ref,'19')]=='LED_OE_n'
for bit in range(16):
 ref=f'U{bit//8+1}';rn=f'RN{bit//8+1}';m=members[f'A{bit}']
 assert len(m)==10
 assert all(r.startswith('J') or r==rn or (r==ref and int(p) in input_pins) for r,p in m)
 assert not any(r in ('U1','U2') and int(p) in output_pins for r,p in m)
 assert actual[(rn,str(bit%8+2))]==f'A{bit}'
 assert cs[f'R{bit+1}']['value']=='2.2k'
 assert actual[(f'D{bit+1}','1')]=='GND'
 assert actual[(f'D{bit+1}','2')]==actual[(f'R{bit+1}','2')]
for ref in ('RN1','RN2'):
 assert actual[(ref,'1')]=='GND' and cs[ref]['value']=='10k_Bussed_SIP9'
assert actual[('R17','1')]=='+5V' and actual[('R17','2')]==actual[('D17','2')]
assert actual[('D17','1')]=='GND' and cs['R17']['value']=='2.2k'
for ref in ('C1','C2','C3'):
 assert actual[(ref,'1')]=='+5V' and actual[(ref,'2')]=='GND'
# Precompute pin nets to keep exhaustive testing of 65,536 words inexpensive.
models=[(actual[(r,str(a))],actual[(r,str(y))]) for r in ('U1','U2') for a,y in channels]
led_drives=[actual[(f'R{i+1}','1')] for i in range(16)]
ports=[[actual[(f'J{j}',str(i+1))] for i in range(16)] for j in range(1,9)]
# OE is active LOW. Verify both banks and unchanged address ports in both states.
models=[(actual[(r,str(a))],actual[(r,str(y))],actual[(r,'1' if a in (2,4,6,8) else '19')]) for r in ('U1','U2') for a,y in channels]
for switch_on in (False,True):
 for value in range(65536):
  nets={'+5V':1,'GND':0,'LED_OE_n':0 if switch_on else 1,**{f'A{i}':(value>>i)&1 for i in range(16)}}
  for a,y,oe in models:nets[y]=nets[a] if nets[oe]==0 else None
  assert all((nets[n] is None)==(not switch_on) for n in led_drives)
  assert sum((0 if nets[n] is None else nets[n])<<i for i,n in enumerate(led_drives))==(value if switch_on else 0),(switch_on,value)
  for port in ports:assert sum(nets[n]<<i for i,n in enumerate(port))==value,'Switch must not change address ports'
  assert nets[actual[('R17','1')]]==1,'Power indicator remains on'
report={'status':'PASS','input_cases':131072,'bus_values_per_switch_state':65536,'switch_states':['OFF','ON'],'checks':['Actual exported schematic nets match board generation','All 65,536 16-bit addresses displayed without inversion','Eight identical 20-pin address ports with four ground pins','Only receiver inputs connected to shared address bus; no on-board address source','Both OE pins on both buffers follow SW1 with a 10k default-disable pull-up','Sixteen 10k pull-downs share ground','Seventeen LEDs have correct polarity and 2.2k series resistance','Power and decoupling polarity','All bit LEDs display data when SW1 ON; outputs high impedance / LEDs inactive when OFF','All eight bus ports unchanged with LEDs disabled; power LED always on','4mm LED pitch, 2mm extra gaps between nibbles, MSB at left'], 'limitations':['Static digital checks only; PC/MAR/IDX arbitration and control are external','LEDs do not latch address values; visible brightness at speed depends on duty cycle','No physical prototype tested; cable loads and signal integrity require measurements']}
(ROOT/'verification/logic-report.json').write_text(json.dumps(report,indent=2))
print('PASS: 131,072 address/switch cases, compact display, LED disable, bus isolation and power indicator')
