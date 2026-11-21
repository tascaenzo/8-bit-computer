"""Diagrammi SVG didattici del bus video e del font effettivo della FPGA."""
from pathlib import Path
import html,re,json
R=Path(__file__).resolve().parents[2];OUT=R/'output/immagini/video-spiegazione-v4';OUT.mkdir(parents=True,exist_ok=True)
BG='#F6F8F5';INK='#14333D';TEAL='#087F87';MUTED='#526C76';GOLD='#EAB24E';LIGHT='#DFECEB';BLUE='#18243B'
def txt(x,y,s,size=34,color=INK,bold=False,anchor='start',mono=False):
 return f'<text x="{x}" y="{y}" font-family="{("Menlo, monospace" if mono else "Arial, sans-serif")}" font-size="{size}" fill="{color}" font-weight="{700 if bold else 400}" text-anchor="{anchor}">{html.escape(str(s))}</text>'
def rect(x,y,w,h,fill,stroke='none',sw=1):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def line(x,y,x2,y2,color=MUTED,sw=2):return f'<line x1="{x}" y1="{y}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{sw}"/>'
def arrow(x,y,x2,y2):return line(x,y,x2,y2,TEAL,4)+f'<path d="M{x2-12},{y2-9} L{x2},{y2} L{x2-12},{y2+9}" fill="none" stroke="{TEAL}" stroke-width="4"/>'
def head(n,title,sub):return rect(0,0,1920,1080,BG)+txt(85,100,title,60,bold=True)+txt(85,162,sub,30,MUTED)+txt(1835,1028,f'{n:02d}',25,MUTED,anchor='end')
def save(n,name,s):
 (OUT/f'{n:02d}-{name}.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">'+s+'</svg>')
def bitrow(x,y,bits,labels=None,colors_=None,width=125,height=100):
 s=''
 for i,b in enumerate(bits):
  fill=colors_[i] if colors_ else LIGHT
  s+=rect(x+i*width,y,width-4,height,fill)+txt(x+i*width+width/2,y+height*.68,b,48,anchor='middle',bold=True,mono=True)
  if labels:s+=txt(x+i*width+width/2,y-17,labels[i],23,MUTED,anchor='middle')
 return s
# 1 enlarged grid excerpt with continuation markers
s=head(1,'La griglia del video, vista da vicino','80 colonne × 60 righe. Le celle qui sono ingrandite per leggerle bene.')
x,y,cw,ch=180,295,115,80
cols=['0','1','2','3','4','5','…','79'];rows=['0','1','2','3','4','…','59']
for col,label in enumerate(cols):s+=txt(x+col*cw+cw/2,y-28,label,32,MUTED,anchor='middle')
for row,label in enumerate(rows):
 s+=txt(x-32,y+row*ch+ch/2+10,label,32,MUTED,anchor='end')
 for col in range(len(cols)):
  xx,yy=x+col*cw,y+row*ch
  if col==6 or row==5:
   s+=f'<rect x="{xx+8}" y="{yy+8}" width="{cw-16}" height="{ch-16}" fill="none" stroke="#ABC0C2" stroke-width="2" stroke-dasharray="7 7"/>'
   if col==6 and row!=5:s+=txt(xx+cw/2,yy+52,'…',36,MUTED,anchor='middle')
   elif row==5:s+=txt(xx+cw/2,yy+52,'⋮',36,MUTED,anchor='middle')
  else:
   s+=rect(xx,yy,cw,ch,'#FFFFFF',TEAL,2)
   if row==0 and col<5:s+=txt(xx+cw/2,yy+56,'HELLO'[col],48,TEAL,bold=True,anchor='middle',mono=True)
   if row==3 and col==2:s+=rect(xx,yy,cw,ch,'#F4D89A',TEAL,3)+txt(xx+cw/2,yy+56,'E',48,bold=True,anchor='middle',mono=True)
s+=txt(180,235,'COLONNE',29,TEAL,bold=True)+txt(85,275,'RIGHE',25,TEAL,bold=True)
s+=txt(1220,335,'Una cella = un carattere',35,bold=True)+txt(1220,400,'8 × 8 pixel',44,TEAL,bold=True)
s+=txt(1220,515,'La E evidenziata:',34,bold=True)+txt(1220,575,'colonna 2, riga 3',37)+txt(1220,700,'I tratti indicano che',31)+txt(1220,745,'la griglia continua fino',31)+txt(1220,790,'alla colonna 79 e riga 59.',31)
s+=txt(180,945,'Area di testo completa: 640 × 480 pixel. Le coordinate partono da zero.',32,MUTED)
save(1,'griglia-80x60',s)
#2 exact glyph
source=(R/'hardware/tang-nano-9k-video/rtl/cpu8_font.v').read_text();font={int(a):int(b,16) for a,b in re.findall(r"font_rows\[(\d+)\] = 8'h([0-9a-f]+);",source)};glyph=[font[0x45*8+i] for i in range(8)]
s=head(2,'Dentro una cella: il carattere E','Matrice 8 × 8 ricavata dal font reale del progetto FPGA')
x,y,z=180,270,65
for r,value in enumerate(glyph):
 for col in range(8):s+=rect(x+col*z,y+r*z,z,z,TEAL if value&(1<<col) else '#FFFFFF','#B5C9CA',1)
 s+=txt(x+8*z+30,y+r*z+43,f'{value:02X}',28,MUTED,mono=True)
for col in range(8):s+=txt(x+col*z+32,y-20,str(col),24,MUTED,anchor='middle')
s+=txt(440,850,'8 pixel',34,anchor='middle',bold=True)+txt(930,320,'Codice ASCII: 45 hex',43,TEAL,bold=True)+txt(930,390,'Il codice sceglie il simbolo.',34)+txt(930,500,'Il font contiene le 8 righe di pixel.',34)+txt(930,550,'Ogni riga occupa un byte.',34)+txt(930,665,'Pixel acceso: colore del testo',33)+txt(930,720,'Pixel spento: colore dello sfondo',33)+txt(930,865,'Nel renderer attuale x=0 legge il bit 0.',26,MUTED)+txt(85,970,'64 posizioni di pixel per cella. Il byte ASCII e la matrice del font sono dati diversi.',29)
save(2,'carattere-font-8x8',s)
#3 ascii
s=head(3,'Il byte ASCII della lettera E','8 bit identificano il carattere: 45 hex = 69 decimale')
s+=bitrow(250,330,'01000101',[f'D{i}' for i in range(7,-1,-1)],colors_=[LIGHT,LIGHT,LIGHT,LIGHT,LIGHT,'#F4D89A',LIGHT,LIGHT],width=175,height=140)
s+=txt(250,560,'Pesi:',30,MUTED)
for i,v in enumerate([128,64,32,16,8,4,2,1]):s+=txt(250+i*175+87,625,str(v),33,anchor='middle')
s+=txt(250,745,'64 + 4 + 1 = 69 decimale = 45 hex = E',43,TEAL,bold=True)+txt(250,855,'D2 vale 4. Se passa da 1 a 0: 45 diventa 41, cioè A.',34)+txt(250,930,'Il codice ASCII viene trasferito sul bus dati D7…D0.',32,MUTED)
save(3,'ascii-lettera-e',s)
#4 instruction bytes
s=head(4,'Istruzione CPU e carattere ASCII','La CPU legge opcode e operandi. La FPGA riceve il carattere.')
s+=txt(90,265,'LDI R0, 0x45',44,TEAL,bold=True,mono=True)+txt(90,330,'Carica il codice della E in R0',30)
s+=bitrow(90,430,'00100000',width=95)+txt(470,590,'20 hex: opcode LDI R0',29,anchor='middle')
s+=bitrow(1010,430,'01000101',width=95)+txt(1390,590,'45 hex: operando immediato, lettera E',29,anchor='middle')
s+=txt(90,730,'STA R0, 0x2000',44,TEAL,bold=True,mono=True)
s+=txt(90,810,'48 hex',35,bold=True)+txt(90,862,'01001000',34,mono=True)+txt(90,910,'opcode STA R0',27)
s+=txt(670,810,'00 hex',35,bold=True)+txt(670,862,'00000000',34,mono=True)+txt(670,910,'indirizzo basso',27)
s+=txt(1250,810,'20 hex',35,bold=True)+txt(1250,862,'00100000',34,mono=True)+txt(1250,910,'indirizzo alto',27)
s+=txt(90,990,'Byte in memoria: 20 45 48 00 20. Indirizzo little-endian: basso prima dell’alto.',28,MUTED)
save(4,'istruzioni-opcode-operandi',s)
#5 address roles, exact bit boundaries
s=head(5,'Quali bit scelgono colonna, riga e colore?','Esempio: selezione del registro COLONNA, indirizzo 2030 hex')
labels=[f'A{i}' for i in range(15,-1,-1)]
cs=['#BDD5E8']*3+['#E1E5E6']*6+['#B9DCDD']*4+['#F4D89A']*3
s+=bitrow(100,315,f'{0x2030:016b}',labels,cs,width=105,height=110)
for start,count,label,color,caption in [(0,3,'001','#BDD5E8','Zona I/O'),(3,6,'000000','#E1E5E6','Oggi sempre zero'),(9,4,'0110','#B9DCDD','COLONNA'),(13,3,'000','#F4D89A','Periferica VIDEO')]:
 center=100+(start+count/2)*105;s+=line(100+start*105,450,100+(start+count)*105-4,450,TEAL,4)+txt(center,510,label,39,bold=True,anchor='middle',mono=True)+txt(center,563,caption,27,anchor='middle')
s+=txt(100,675,'A6 A5 A4 A3: questi 4 bit scelgono il registro',39,TEAL,bold=True)
for i,(bits,label) in enumerate([('0000','CARATTERE'),('0101','COLORE'),('0110','COLONNA'),('0111','RIGA')]):
 xx=100+i*440;s+=rect(xx,725,405,140,LIGHT)+txt(xx+202,785,bits,42,bold=True,anchor='middle',mono=True)+txt(xx+202,838,label,29,bold=True,anchor='middle')
s+=txt(100,935,'È la combinazione dei bit a scegliere UN registro alla volta.',33,bold=True)+txt(100,988,'Non ci sono gruppi separati per i valori di riga, colonna e colore.',31,TEAL)
save(5,'indirizzi-16bit',s)
#6 address selects a register; data carries its value
s=head(6,'Indirizzo: quale registro. Dato: quale valore.','Sono scritture separate: prima posizione e colore, poi il carattere.')
s+=txt(100,255,'COSA IMPOSTO',26,MUTED,bold=True)+txt(430,255,'BUS INDIRIZZI A15…A0',26,MUTED,bold=True)+txt(1330,255,'BUS DATI D7…D0',26,MUTED,bold=True)
items=[('COLONNA','2030','0110','00001010','10 decimale'),('RIGA','2038','0111','00000011','3 decimale'),('COLORE','2028','0101','00011110','1E hex: oro su blu'),('CARATTERE','2000','0000','01000101','45 hex: lettera E')]
for i,(label,addr,reg,bits,value) in enumerate(items):
 yy=295+i*155;s+=rect(85,yy,1750,135,'#FFFFFF')+txt(110,yy+49,label,32,TEAL,bold=True)+txt(110,yy+97,addr+' hex',29)
 s+=txt(430,yy+75,'001 000000',35,MUTED,mono=True)+rect(680,yy+27,122,67,'#B9DCDD')+txt(695,yy+75,reg,35,TEAL,bold=True,mono=True)+txt(830,yy+75,'000',35,MUTED,mono=True)
 s+=arrow(1020,yy+65,1245,yy+65)+txt(1300,yy+55,bits,36,bold=True,mono=True)+txt(1300,yy+105,value,29)
s+=txt(100,985,'Il gruppo verde cambia il registro. Gli 8 bit a destra portano coordinata, colore o ASCII.',31,bold=True)
save(6,'posizione-riga-colonna',s)
#7color
s=head(7,'Un byte per testo e sfondo','VIDEO_COLOR: indirizzo CPU 2028 hex')
s+=bitrow(250,320,'00011110',[f'D{i}' for i in range(7,-1,-1)],['#B9CADF']*4+['#F4D89A']*4,width=175,height=125)
s+=txt(600,535,'0001 = 1 hex',43,anchor='middle',bold=True)+txt(600,605,'Sfondo blu scuro',36,anchor='middle')+txt(1300,535,'1110 = E hex',43,anchor='middle',bold=True)+txt(1300,605,'Testo oro',36,anchor='middle')
s+=rect(250,680,330,250,BLUE)
for r,v in enumerate(glyph):
 for col in range(8):
  if v&(1<<col):s+=rect(310+col*24,705+r*24,24,24,'#FFD166')
s+=txt(680,745,'Colore: 1E hex',46,TEAL,bold=True)+txt(680,810,'Carattere: 45 hex, lettera E',35)+txt(680,890,'Due byte separati nella memoria della cella:',31)+txt(680,943,'45 per il carattere, 1E per il colore.',31)
save(7,'colore-testo-sfondo',s)
#8 data-bit roles by selected register
s=head(8,'Gli 8 bit DATI: cosa significano?','Esempi di scritture diverse: questi sono bit DATI, non bit dell’indirizzo.')
sets=[('COLONNA','2030 hex','0CCCCCCC',['#E1E5E6']+[LIGHT]*7,'D7 = 0. D6…D0: colonna da 0 a 79.'),('RIGA','2038 hex','00RRRRRR',['#E1E5E6']*2+[LIGHT]*6,'D7 e D6 = 0. D5…D0: riga da 0 a 59.'),('COLORE','2028 hex','SSSSTTTT',['#BDD5E8']*4+['#F4D89A']*4,'D7…D4: sfondo. D3…D0: testo.')]
for i,(label,addr,bits,palette,caption) in enumerate(sets):
 yy=290+i*215;s+=txt(95,yy+48,label,36,TEAL,bold=True)+txt(95,yy+99,addr,29)
 s+=bitrow(480,yy,bits,[f'D{b}' for b in range(7,-1,-1)],palette,width=150,height=95)
 s+=txt(480,yy+152,caption,30)
s+=txt(95,1000,'C e R rappresentano numeri binari. Le coordinate fuori intervallo vengono ignorate.',29,MUTED)
save(8,'significato-bit-dati',s)
#9 simultaneous address and data on every write
s=head(9,'A ogni scrittura: indirizzo E dato insieme','Tre scritture impostano colore, riga e colonna. La quarta stampa il carattere.')
s+=txt(95,250,'SCRITTURA',25,MUTED,bold=True)+txt(370,250,'BUS INDIRIZZI: DOVE',27,MUTED,bold=True)+txt(1020,250,'BUS DATI: QUALE VALORE',27,MUTED,bold=True)
transactions=[('1. COLORE','2028','1E','00011110','Oro su blu scuro'),('2. RIGA','2038','03','00000011','Riga 3'),('3. COLONNA','2030','0A','00001010','Colonna 10'),('4. CARATTERE','2000','45','01000101','Stampa E in quella posizione')]
for i,(label,addr,data,bits,result) in enumerate(transactions):
 yy=290+i*150;s+=rect(85,yy,1750,135,'#F4D89A' if i==3 else '#FFFFFF')+txt(110,yy+63,label,28,TEAL,bold=True)
 s+=txt(385,yy+60,addr+' hex',40,bold=True,mono=True)+txt(385,yy+105,'sceglie il registro',25,MUTED)
 s+=txt(810,yy+65,'+',50,TEAL,bold=True)+txt(1015,yy+52,bits+' = '+data+' hex',32,bold=True,mono=True)+txt(1015,yy+105,result,30)
s+=txt(95,955,'Indirizzo e dato vengono accettati nella STESSA richiesta di scrittura (/WR=0).',31,TEAL,bold=True)
s+=txt(95,1005,'La FPGA conserva i valori: cambiare registro non cancella quelli già impostati.',29)
save(9,'scritture-separate-memoria-fpga',s)
#10 coordinate capacity, explanation only, no proposed hardware modification
s=head(10,'Perché riga e colonna viaggiano separate?','I 10 bit attuali selezionano i registri. I valori arrivano sul bus dati.')
s+=txt(95,295,'Per contenere insieme entrambe le coordinate:',38,bold=True)
s+=rect(95,355,680,175,LIGHT)+txt(435,430,'RRRRRR',60,anchor='middle',mono=True,bold=True)+txt(435,495,'6 bit per la riga 0…59',34,anchor='middle')
s+=txt(835,465,'+',64,TEAL,anchor='middle')+rect(895,355,890,175,'#B9DCDD')+txt(1340,430,'CCCCCCC',60,anchor='middle',mono=True,bold=True)+txt(1340,495,'7 bit per la colonna 0…79',34,anchor='middle')
s+=txt(95,645,'Servirebbero 13 bit per affiancare riga e colonna.',45,TEAL,bold=True)
s+=txt(95,755,'10 bit: 1024 combinazioni',37)+txt(95,815,'Griglia attuale: 80 × 60 = 4800 posizioni',37)
s+=txt(95,940,'Nel progetto manteniamo le scritture separate e i registri che ricordano i valori.',32,bold=True)
save(10,'coordinate-separate-perche',s)
#11 roles of CPU instructions and one physical transaction
s=head(11,'Quando viene usato il bus dati?','Esempio: impostare il colore oro su blu, valore 1E hex')
s+=txt(95,285,'1. LDI R0, 0x1E',46,TEAL,bold=True,mono=True)
s+=txt(95,350,'La CPU legge 1E dalla RAM e lo mette in R0.',34)+txt(95,405,'È la preparazione del valore. La FPGA non riceve ancora una scrittura.',31)
s+=txt(95,540,'2. STA R0, 0x2028',46,TEAL,bold=True,mono=True)
s+=rect(95,605,800,170,LIGHT)+txt(130,660,'BUS INDIRIZZI A15…A0',28,MUTED,bold=True)+txt(130,730,'2028 hex = registro COLORE',36,bold=True)
s+=rect(945,605,880,170,'#F4D89A')+txt(980,660,'BUS DATI D7…D0',28,MUTED,bold=True)+txt(980,730,'00011110 = valore 1E hex',36,bold=True,mono=True)
s+=txt(95,865,'STA presenta entrambi insieme e attiva la richiesta di scrittura.',34,TEAL,bold=True)
s+=txt(95,930,'La FPGA salva 1E nel registro colore. Riga e colonna restano invariate.',31)
save(11,'quando-si-usa-il-bus-dati',s)
(OUT/'dati-verificati.json').write_text(json.dumps({'grid':[80,60],'glyph_pixels':[8,8],'ascii_E':{'hex':'45','decimal':69,'binary':'01000101'},'font_E_rows_hex':[f'{v:02X}' for v in glyph],'instruction_bytes':'20 45 48 00 20','video_color_address_binary':f'{0x2028:016b}','cell_example':{'x':10,'y':3,'pointer':394,'hex':'018A'}},indent=2)+'\n')
print('11 SVG generati; indirizzo e dato simultanei in ogni scrittura.')
