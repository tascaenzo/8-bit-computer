"""Schema circuitale funzionale, stile registri/bus del riferimento utente."""
from pathlib import Path
import html
R=Path(__file__).resolve().parents[2];OUT=R/'output/schemi';W,H=1500,2050;a=[]
def t(x,y,s,size=27,anchor='start',bold=False):a.append(f'<text x="{x}" y="{y}" font-family="Arial,sans-serif" font-size="{size}" text-anchor="{anchor}" font-weight="{700 if bold else 400}" fill="black">{html.escape(s)}</text>')
def r(x,y,w,h):a.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="white" stroke="black" stroke-width="3"/>')
def wire(p,arrow=False,width=2):a.append(f'<polyline points="{p}" fill="none" stroke="black" stroke-width="{width}"'+(' marker-end="url(#arr)"' if arrow else '')+'/>')
def dot(x,y):a.append(f'<circle cx="{x}" cy="{y}" r="5" fill="black"/>')
def bus(p):wire(p,False,5)
def slash(x,y,label):wire(f'{x-8},{y+9} {x+8},{y-9}');t(x+18,y+8,label,23)
a.append('<rect width="1500" height="2050" fill="white"/>')
t(750,65,'SCHEDA VIDEO NELLA FPGA',39,'middle',True)
t(750,108,'Schema funzionale dei bus e delle abilitazioni di scrittura',25,'middle')
# inputs CPU above FPGA boundary
t(230,182,'BUS INDIRIZZI CPU',29,'middle',True);t(230,220,'A15…A0',25,'middle')
t(1230,182,'BUS DATI CPU',29,'middle',True);t(1230,220,'D7…D0',25,'middle')
# FPGA boundary dashed
a.append('<rect x="35" y="290" width="1425" height="1600" fill="none" stroke="black" stroke-width="2" stroke-dasharray="12 8"/>');t(55,322,'FPGA',23)
# external Y0 explanation
wire('230,235 230,350',True,4);slash(230,275,'13')
t(270,270,'A15…A3',24)
r(80,350,350,650);t(255,397,'DECODER',34,'middle',True);t(255,440,'INDIRIZZI',30,'middle',True)
t(110,505,'Confronta A15…A3',25)
t(110,549,'con la mappa video.',25)
t(110,880,'Richiesta valida:',24);t(110,920,'/WR=0, /RD=1',25);t(110,960,'RUN e READY',25)
# selection external feed
wire('48,680 80,680',True);t(50,645,'Y0',23)
# decode signal to five destinations
ys=[590,770,1080,1255]
# grouped pointer box and two slices
r(690,400,395,460);t(887,445,'PUNTATORE INTERNO',27,'middle',True);t(887,482,'14 bit = riga × 128 + colonna',23,'middle')
for yy,label,bits in [(530,'COLONNA','pointer[6:0] - 7 bit'),(710,'RIGA','pointer[13:7] - 7 bit')]:
 r(740,yy,295,115);t(887,yy+43,label,29,'middle',True);t(887,yy+82,bits,23,'middle');t(718,yy+69,'EN',20,'end');t(1052,yy+69,'D',22)
for yy,title,bits in [(1020,'COLORE','color[7:0] - 8 bit'),(1195,'CONTROLLI','control[7:0] - 8 bit')]:
 r(740,yy,295,115);t(887,yy+43,title,29,'middle',True);t(887,yy+82,bits,23,'middle');t(718,yy+69,'EN',20,'end');t(1052,yy+69,'D',22)
# Control outputs go to EN input; labels have address and selection
for yy,label in [(590,'2030: EN_COLONNA'),(770,'2038: EN_RIGA'),(1080,'2028: EN_COLORE'),(1255,'2040: EN_CONTROLLI')]:
 if yy<=1000:wire(f'430,{yy} 740,{yy}',True)
 else:
  origin=800 if yy==1080 else 840;xx=500 if yy==1080 else 460
  wire(f'430,{origin} {xx},{origin} {xx},{yy} 740,{yy}',True)
 t(450 if yy<=1000 else 510, yy-18,label,21)
# common data bus from top, synchronized; arrow to each register
r(1115,350,270,110);t(1250,392,'INTERFACCIA',26,'middle',True);t(1250,430,'Dato sincronizzato',22,'middle')
wire('1230,235 1230,350',True,4);slash(1230,275,'8')
bus('1250,460 1250,1510');t(1330,650,'BUS',25);t(1330,690,'DATI',25);t(1330,730,'INTERNO',24);t(1330,775,'8 bit',24)
for yy in [590,770,1080,1255]:
 dot(1250,yy);wire(f'1250,{yy} 1035,{yy}',True,3)
# pointer output and color output down towards memory inputs, avoiding data bus
wire('887,860 1110,860 1110,1420',True,3);t(1128,920,'14 bit',23);t(1128,960,'indirizzo',22);t(1128,993,'cella',22)
# color to memory attribute via route left of registers
wire('887,1135 1070,1135 1070,1360 650,1360 650,1420',True,3);t(535,1357,'colore',23)
# VRAM box, three incoming ports on top
r(570,1420,740,220);t(940,1472,'MEMORIA VIDEO',32,'middle',True);t(940,1525,'ASCII per cella + attributo colore per cella',25,'middle')
t(940,1575,'16384 caratteri + 16384 attributi',25,'middle')
t(650,1400,'ATTR',21,'middle');t(1110,1400,'ADDR',21,'middle');t(1250,1400,'DATA',21,'middle')
# wire rail DATA enters VRAM top: stop at top (rail path corrected below)
# enable DATA decoder separate under decoder left
wire('330,1000 440,1000 440,1510 570,1510',True);t(275,1478,'2000: WE_MEMORIA',23)
# command engine distinct under decoder
r(80,1100,320,170);t(240,1145,'MOTORE COMANDI',25,'middle',True);t(240,1190,'CLEAR / NEWLINE',23,'middle');t(240,1230,'SCROLL / HOME',23,'middle')
wire('150,1000 150,1100',True);t(165,1060,'2020',23)
# command engine affects pointer etc described without fake literal connection
# display path
wire('940,1640 940,1695',True,4)
r(570,1695,740,125);t(940,1740,'FONT 8×8 + PALETTE + GENERATORE VIDEO',27,'middle',True);t(940,1787,'Lettura continua delle celle e generazione dei pixel',24,'middle')
wire('940,1820 940,1945',True,4);t(975,1928,'HDMI',25)
r(760,1945,360,70);t(940,1991,'MONITOR',29,'middle',True)
# reading and extra views note
t(80,1710,'Solo il registro selezionato',25);t(80,1750,'acquisisce il dato sul clock FPGA.',25)
t(80,1820,'Posizione CPU: solo CURSOR_X / CURSOR_Y.',20)
t(80,1853,'STATUS: valore calcolato READY/BUSY.',20)
# rail stops at DATA input instead of crossing inside memory
svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs><marker id="arr" markerWidth="9" markerHeight="9" refX="8" refY="3" orient="auto" markerUnits="strokeWidth"><path d="M0,0 L0,6 L8,3 z" fill="black"/></marker></defs>'+''.join(a)+'</svg>'
svg=svg.replace('points="1250,460 1250,1510"','points="1250,460 1250,1420"')
(OUT/'fpga-video-schema-circuitale.svg').write_text(svg)
