#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,argparse
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description='Audit indipendente delle parole fisiche CU e dei rischi strutturali di fine scrittura. Non simula i ritardi elettrici.')
parser.add_argument('--prefix',type=Path,default=root/'tools/cu-bytecode/build/microcode')
parser.add_argument('--report',type=Path)
parser.add_argument('--compare-prefix',type=Path,default=root/'tools/cu-bytecode/build/microcode')
args=parser.parse_args()
rom=[Path(str(args.prefix)+f'-rom{i}.bin').read_bytes() for i in range(3)]
assert all(len(b)==8192 for b in rom)
def index(mode,flags,group,t):
 s=t-1;phys=((s&1)<<2)|(s&2)|((s&4)>>2)
 return (mode<<12)|(flags<<8)|(group<<3)|phys

def decode(mode,flags,group,t):
 address=index(mode,flags,group,t);a,b,c=(r[address] for r in rom)
 return {'rom_addr':f'{address:04X}','bytes':[f'{v:02X}' for v in (a,b,c)],
         'addr':['IDX','PC','MAR','NONE'][a&3],
         'wr':(a>>5)&1,'rd':(c>>3)&1,'eprom_oe':(a>>6)&1,
         'mdr_oe':(a>>4)&1,'pc_inc':(a>>2)&1,'next_fetch':(a>>7)&1,'sys_step':(c>>6)&1,
         'rf_enable':(b>>3)&1,'rf_write':(b>>4)&1,
         'ra_enable':(b>>5)&1,'ra_write':(b>>6)&1,'alu_oe':c&1}
boot_writes=run_writes=0
for mode in range(2):
 for flags in range(16):
  for group in range(32):
   for t in range(1,9):
    x=decode(mode,flags,group,t)
    if not x['wr']:
     if mode==0:
      boot_writes+=1;assert t==1 and x['addr']=='PC' and x['eprom_oe']==0 and not x['pc_inc']
     else:
      run_writes+=1;assert (group,t) in [(9,6),(11,4)]
      assert x['addr'] in ('MAR','IDX') and x['mdr_oe']==0 and x['eprom_oe']==1
     assert x['rd']==1
    if mode==1 and group==0:
     assert x['wr']==1
     if t==2:assert x['addr']=='NONE' and x['rd']==1 and x['sys_step']==0
assert boot_writes==512 and run_writes==32
# BOOT T2/T3 retain the PC address and EPROM data with /WR inactive.
for flags in range(16):
 for group in range(32):
  for t in (2,3):
   x=decode(0,flags,group,t)
   assert (x['wr'],x['addr'],x['eprom_oe'])==(1,'PC',0)
# All RUN T1 rows share a read-only fetch, including after reset with stale IR.
fetches=[decode(1,f,g,1)['bytes'] for f in range(16) for g in range(32)]
assert all(x==fetches[0] for x in fetches)
transitions={}
for group,prepare,source in [(9,5,'MAR'),(11,3,'IDX')]:
 for flags in range(16):
  phases=[decode(1,flags,group,prepare+i) for i in range(4)]
  for i,x in enumerate(phases):
   assert x['wr']==(0 if i==1 else 1)
   assert x['rd']==1 and x['eprom_oe']==1 and x['pc_inc']==0
   assert x['addr']==('NONE' if i==3 else source)
   assert x['mdr_oe']==(1 if i==3 else 0)
   assert x['next_fetch']==(0 if i==3 else 1)
  # Preparation and closure have exactly the same complete ROM words;
  # the write phase changes only /WR. No other control changes with /WR.
  assert phases[0]['bytes']==phases[2]['bytes']
  assert int(phases[0]['bytes'][0],16)^int(phases[1]['bytes'][0],16)==0x20
  assert phases[0]['bytes'][1:]==phases[1]['bytes'][1:]
 transitions['STA' if group==9 else 'STAI']={
  name:decode(1,0,group,prepare+i)
  for i,name in enumerate(['prepare','write','hold','release'])}
report={'all_physical_words_checked':8192,'boot_write_words':boot_writes,'run_write_words':run_writes,
 'boot':[decode(0,0,0,t) for t in (1,2,3)],'hlt_run_t2':decode(1,0,0,2),
 'fetch_run_t1':decode(1,0,0,1),'write_phases':transitions,'setup_hold_all_flag_pages':True,
 'images':[]}
for i,b in enumerate(rom):
 old=Path(str(args.compare_prefix)+f'-rom{i}.bin').read_bytes()
 assert len(old)==8192
 report['images'].append({'rom':i,'sha256':hashlib.sha256(b).hexdigest(),'matches_existing_build':old==b,'different_bytes':sum(a!=z for a,z in zip(old,b))})
if args.report:
 args.report.parent.mkdir(parents=True,exist_ok=True)
 args.report.write_text(json.dumps(report,indent=2)+'\n')
print('PASS: 8192 parole fisiche; BOOT scrive solo in T1; RUN scrive solo STA/T6 e STAI/T4.')
print('PASS: HLT non scrive per tutte le 16 pagine flag e tutti gli 8 step.')
print('BOOT:',[(t+1,x['bytes'],x['wr']) for t,x in enumerate(report['boot'])])
print('HLT/T2:',report['hlt_run_t2'])
print('Fetch:',report['fetch_run_t1'])
print('PASS: prepara/scrivi/mantieni/rilascia in tutte le pagine flag; bus validi prima e dopo /WR.')
print('Byte diversi rispetto al confronto:',[x['different_bytes'] for x in report['images']])
print('Limite: reset e transitori elettrici delle ROM richiedono ancora protezione hardware.')
