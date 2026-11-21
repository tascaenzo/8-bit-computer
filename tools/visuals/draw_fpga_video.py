"""Schema a blocchi del video FPGA, coerente con il progetto RTL."""
from pathlib import Path
import html
R=Path(__file__).resolve().parents[2];OUT=R/'output/schemi'
INK='#14333D';TEAL='#087F87';BG='#F6F8F5';MUTED='#526C76';GOLD='#F4D89A';LIGHT='#DFECEB'
a=[]
def text(x,y,t,size=30,color=INK,bold=False,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, sans-serif" font-size="{size}" fill="{color}" font-weight="{700 if bold else 400}" text-anchor="{anchor}">{html.escape(t)}</text>')
def box(x,y,w,h,title,lines,fill=LIGHT):
 a.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{fill}" stroke="{TEAL}" stroke-width="2"/>');text(x+24,y+44,title,32,TEAL,True)
 for i,t in enumerate(lines):text(x+24,y+86+i*34,t,27)
def arrow(points,color=TEAL):
 a.append(f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="4" marker-end="url(#arrow)"/>')
a.append(f'<rect width="1920" height="1480" fill="{BG}"/>')
text(70,85,'La scheda video dentro la FPGA',58,bold=True)
text(70,143,'La CPU scrive valori. I circuiti interni conservano il testo e generano continuamente il video.',29,MUTED)
box(65,220,430,200,'CPU A 8 BIT',['Bus indirizzi: quale registro','Bus dati: quale valore','/RD e /WR: tipo di accesso'],'#FFFFFF')
box(570,220,405,200,'ADATTAMENTO LIVELLI',['SN74LVC8T245','CPU: 5 V / FPGA: 3,3 V','Dati anche in lettura'],'#FFFFFF')
arrow('495,320 570,320')
# FPGA boundary
a.append('<rect x="1040" y="190" width="810" height="1160" rx="12" fill="none" stroke="#087F87" stroke-width="3" stroke-dasharray="12 7"/>')
text(1080,235,'FPGA - TANG NANO 9K',27,TEAL,True)
box(1080,265,730,160,'INTERFACCIA E DECODER',['Sincronizza la richiesta e riconosce l’indirizzo.','Esempio: 2030 = colonna, 2028 = colore.'])
arrow('975,320 1080,320')
# decode values to control
arrow('1445,425 1445,480')
box(1080,480,730,240,'REGISTRI E LOGICA DI CONTROLLO',['Puntatore: riga + colonna della prossima cella','Colore corrente: testo + sfondo','Controlli: cursore, avanzamento, ritorno a capo','Comandi: CLEAR, NEWLINE, SCROLL…','Carattere ricevuto: dato da scrivere in memoria'])
# character flow to memory distinct side route
# Il blocco di controllo inoltra il carattere ricevuto alla memoria.
text(1180,770,'Posizione, colore e consenso di scrittura',25,MUTED)
arrow('1770,720 1770,790')
box(1080,790,730,165,'MEMORIA VIDEO',['Una memoria per i caratteri, una per i colori.','Ogni cella: ASCII 45 + colore 1E = E oro su blu.'])
arrow('1445,955 1445,1010')
box(1080,1010,730,150,'FONT E PALETTE',['Font 8 × 8: quali pixel accendere.','Palette: colore del testo e dello sfondo.'])
arrow('1445,1160 1445,1210')
box(1080,1210,730,115,'GENERATORE VIDEO / TMDS',['Temporizzazioni e segnale per l’uscita HDMI.'])
# monitor on left low
box(80,1065,820,260,'MONITOR HDMI',['Mostra la griglia 80 × 60.','Il testo resta visibile anche con la CPU ferma.'], '#FFFFFF')
arrow('1080,1265 900,1265')
text(925,1235,'HDMI',25,TEAL,True)
# left explanatory transaction examples
text(80,520,'Esempio: quattro scritture della CPU',37,bold=True)
for i,(addr,data,what) in enumerate([('2028','1E','imposta il colore'),('2038','03','imposta la riga 3'),('2030','0A','imposta la colonna 10'),('2000','45','scrive la lettera E')]):
 y=595+i*85
 text(90,y,addr,35,TEAL,True);text(245,y,'+',32,MUTED);text(290,y,data,35,INK,True);text(420,y,what,31)
text(90,935,'Indirizzo',25,MUTED);text(290,935,'Dato',25,MUTED)
text(80,995,'Indirizzo e dato viaggiano insieme a ogni scrittura.',28,TEAL,True)
text(1080,1395,'Il clock FPGA continua a funzionare',25,MUTED)
text(1080,1433,'anche quando il clock CPU è fermo.',25,MUTED)
text(80,1435,'Schema funzionale del progetto - la memoria e i registri sono interni alla FPGA.',25,MUTED)
svg='<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1480" viewBox="0 0 1920 1480"><defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto" markerUnits="strokeWidth"><path d="M0,0 L0,6 L8,3 z" fill="#087F87"/></marker></defs>'+''.join(a)+'</svg>'
(OUT/'fpga-video-schema-blocchi.svg').write_text(svg)
