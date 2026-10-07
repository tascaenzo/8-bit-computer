#!/usr/bin/env python3
"""Check actual schematic connectivity, all data bytes and monitor isolation."""
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
for ref in [f'J{i}' for i in range(1,9)]:
 assert [actual[(ref,str(i))] for i in range(1,11)]==[f'D{i}' for i in range(8)]+['GND','GND']
# Verify compatibility against the ALU actually delivered, without changing its sources.
alu=ROOT.parent/'alu-pcb/rev-b/source/netlist.json'
if alu.exists():
 ac={c['ref']:c for c in json.loads(alu.read_text())['components']}
 assert cs['J1']['pins']==ac['J4']['pins'],'ALU bus pinout differs'
 assert cs['J9']['pins']==ac['J6']['pins'],'ALU power pinout differs'
assert [actual[('J9',str(i))] for i in range(1,5)]==['+5V','GND','+5V','GND']
assert actual[('U1','20')]=='+5V'
assert actual[('U1','10')]=='GND'
assert actual[('U1','1')]==actual[('U1','19')]=='LED_OE_n'
# SW1 closes OE_n to GND; R10/R18 provides a defined HIGH when open.
assert actual[('SW1','1')]=='LED_OE_n' and actual[('SW1','2')]=='GND'
assert actual[('R10','1')]=='+5V' and actual[('R10','2')]=='LED_OE_n'
assert cs['R10']['value']=='10k'
assert cs['SW1']['value']=='SDA01H0BD_LED_ENABLE'
expected_oe={('SW1','1'),('R10','2')} | {(f'U{i}',p) for i in range(1,2) for p in ('1','19')}
assert set(members['LED_OE_n'])==expected_oe, 'OE control must not touch any bus line'
ordered=sorted((c['x'],c['monitor']) for c in cs.values() if isinstance(c.get('monitor'),int))
assert [bit for x,bit in ordered]==list(range(7,-1,-1)), 'Display must be MSB on left'
assert all(abs((ordered[i+1][0]-ordered[i][0])-(6 if (i+1)%4==0 else 4))<1e-6 for i in range(7)), 'Compact 4mm LED spacing / nibble gaps'
# Independent physical SN74HCT244 channel pairing from the manufacturer's pin diagram.
channels=[(2,18),(4,16),(6,14),(8,12),(17,3),(15,5),(13,7),(11,9)]
input_pins={a for a,y in channels};output_pins={y for a,y in channels}
for bit in range(8):
 m=members[f'D{bit}']
 assert len(m)==10 # Eight headers, one receiver input, one bias resistor.
 assert all(r.startswith('J') or r=='RN1' or (r=='U1' and int(p) in input_pins) for r,p in m)
 assert not any(r=='U1' and int(p) in output_pins for r,p in m),'Receiver is driving shared bus'
 assert actual[('RN1',str(bit+2))]==f'D{bit}'
 assert cs[f'R{bit+1}']['value']=='2.2k'
 assert actual[(f'D{bit+1}','1')]=='GND'
 assert actual[(f'D{bit+1}','2')]==actual[(f'R{bit+1}','2')]
assert actual[('RN1','1')]=='GND' and cs['RN1']['value']=='10k_Bussed_SIP9'
assert actual[('R9','1')]=='+5V' and actual[('R9','2')]==actual[('D9','2')]
assert actual[('D9','1')]=='GND'
assert cs['R9']['value']=='2.2k'
assert actual[('C1','1')]==actual[('C2','1')]=='+5V'
assert actual[('C1','2')]==actual[('C2','2')]=='GND'
# OE is active LOW. Model high impedance independently from the bus values.
models=[(actual[('U1',str(a))],actual[('U1',str(y))],actual[('U1','1' if a in (2,4,6,8) else '19')]) for a,y in channels]
for switch_on in (False,True):
 for value in range(256):
  nets={'+5V':1,'GND':0,'LED_OE_n':0 if switch_on else 1,**{f'D{i}':(value>>i)&1 for i in range(8)}}
  for a,y,oe in models:nets[y]=nets[a] if nets[oe]==0 else None
  observed=0
  for i in range(8):
   drive=nets[actual[(f'R{i+1}','1')]]
   on=0 if drive is None else drive
   assert on==(((value>>i)&1) if switch_on else 0),(switch_on,value,i)
   assert (drive is None)==(not switch_on)
   observed|=on<<i
  assert observed==(value if switch_on else 0)
  for ref in [f'J{i}' for i in range(1,9)]:
   assert sum(nets[actual[(ref,str(i+1))]]<<i for i in range(8))==value,'Switch must not change bus data'
  assert nets[actual[('R9','1')]]==1,'Power indicator remains on'
report={'status':'PASS','input_cases':512,'bus_values_per_switch_state':256,'switch_states':['OFF','ON'],'checks':['Actual exported schematic nets match board generation','All 256 bus bytes displayed without inversion','Eight identical bidirectional port pinouts','ALU J4/J6 compatibility when ALU project is present','Only receiver inputs connected to shared bus; no on-board active bus driver','Both OE pins follow SW1 with a 10k default-disable pull-up','Eight 10k pull-downs share ground','Nine LEDs have correct polarity and 2.2k series resistance','Power and decoupling polarity','All bit LEDs display data when SW1 ON; outputs high impedance / LEDs inactive when OFF','All eight bus ports unchanged with LEDs disabled; power LED always on','4mm LED pitch, 2mm extra gaps between nibbles, MSB at left'], 'limitations':['Static digital checks only; external writer arbitration is not implemented on this board','No sample-and-hold: LED visibility at speed depends on data duty cycle','No physical prototype tested; signal integrity, cable loads and timing require measurements']}
(ROOT/'verification/logic-report.json').write_text(json.dumps(report,indent=2))
print('PASS: 512 byte/switch cases, compact display, LED disable, bus isolation and ALU connector compatibility')
