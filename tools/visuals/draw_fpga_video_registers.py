"""Schema verticale: decoder video e registri fisici del progetto RTL."""
from pathlib import Path
import html
R=Path(__file__).resolve().parents[2];OUT=R/'output/schemi';W,H=1800,3260
BG='#F6F8F5';INK='#14333D';TEAL='#087F87';MUTED='#526C76';LIGHT='#DFECEB';GOLD='#F4D89A';GRAY='#E5EBEC';a=[]
def text(x,y,s,size=28,color=INK,bold=False,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, sans-serif" font-size="{size}" fill="{color}" font-weight="{700 if bold else 400}" text-anchor="{anchor}">{html.escape(s)}</text>')
def rect(x,y,w,h,fill=LIGHT,stroke=TEAL):a.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
def arrow(points,color=TEAL):a.append(f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="4" marker-end="url(#arr)"/>')
def box(x,y,w,h,title,lines,fill=LIGHT):
 rect(x,y,w,h,fill);text(x+24,y+44,title,32,TEAL,True)
 for i,s in enumerate(lines):text(x+24,y+85+37*i,s,27)
a.append(f'<rect width="{W}" height="{H}" fill="{BG}"/>')
text(65,85,'FPGA VIDEO: SELETTORE E REGISTRI INTERNI',45,bold=True)
text(65,142,'Indirizzo e dato arrivano insieme. Il decoder abilita una sola destinazione del byte dati.',27,MUTED)
text(65,225,'1. RICHIESTA DELLA CPU',32,TEAL,True)
box(65,260,710,185,'BUS INDIRIZZI A15…A0',['Esempio: 2030 hex = selezione COLONNA','Il numero 10 della colonna non è qui.'])
box(825,260,710,185,'BUS DATI D7…D0',['Esempio: 0A hex = 00001010 = valore 10','Questo è il valore da memorizzare.'],GOLD)
# Richiesta valida in scrittura: /WR=0 e /RD=1.
arrow('420,445 420,555')
# data rail, explicitly captioned and separated from decoder
arrow('1180,445 1180,560')
box(825,560,710,190,'DATO SINCRONIZZATO: write_data[7:0]',['Il circuito acquisisce il byte dopo l’assestamento.','Non cambia significato da solo: lo decide','il registro selezionato.'],GOLD)
box(65,560,710,190,'SELEZIONE ESTERNA E INDIRIZZO FPGA',['A2…A0 = 000: il 74238 seleziona Y0 video.','A15…A3 arrivano alla FPGA: 2030 / 8 = 0406.','La FPGA controlla l’intero indirizzo ricevuto.'])
arrow('420,750 420,810')
box(65,810,1470,190,'2. DECODER: CONFRONTO DELL’INDIRIZZO',['Video selezionato, /WR=0 e /RD=1: decode identifica un reg_id.','Esempio: A15…A3 = 0406 hex  →  reg_id = CURSOR_X.','Dopo la fase di attesa, write_enable autorizza una sola scrittura per richiesta.'])
arrow('800,1000 800,1055')
text(65,1100,'3. IL SELETTORE ATTIVA UNA SOLA FUNZIONE',32,TEAL,True)
text(65,1146,'Mappa attuale: A15…A13=001 e A12…A7=000000. I quattro bit sotto sono A6…A3.',25,MUTED)
# decode mapping table; full addresses required, bits only meaningful within fixed zone
x=[65,270,475,820];widths=[205,205,345,715];top=1180;rh=81
heads=['Indirizzo CPU','A6…A3','Selezione interna','Cosa succede al dato']
for j in range(4):rect(x[j],top,widths[j],60,TEAL,TEAL);text(x[j]+15,top+38,heads[j],25,'#FFFFFF',True)
rows=[('2000','0000','VIDEO_DATA','Scrive il carattere nella cella puntata.'),('2008','0001','RISERVATO','Nessun accesso.'),('2010','0010','RISERVATO','Nessun accesso.'),('2018','0011','VIDEO_STATUS','Solo lettura: restituisce READY/BUSY.'),('2020','0100','VIDEO_CMD','Esegue CLEAR, NEWLINE, SCROLL…'),('2028','0101','VIDEO_COLOR','Salva il byte in color[7:0].'),('2030','0110','CURSOR_X','Salva la colonna in pointer[6:0].'),('2038','0111','CURSOR_Y','Salva la riga in pointer[13:7].'),('2040','1000','VIDEO_CONTROL','Salva i controlli in control[4:0].')]
for i,row in enumerate(rows):
 yy=top+60+i*rh
 for j,v in enumerate(row):rect(x[j],yy,widths[j],rh,'#F4D89A' if row[0]=='2030' else ('#FFFFFF' if i%2==0 else LIGHT),'#C2D1D3');text(x[j]+15,yy+47,v,25,INK,j in (0,1))
text(65,2022,'Riga, colonna e colore si aggiornano con scritture separate. Gli altri valori restano memorizzati.',26,bold=True)
# actual registers
text(65,2100,'4. REGISTRI FISICI: DOVE VIENE SALVATO IL BYTE',32,TEAL,True)
# Bus dati comune, separato dal percorso di selezione.
arrow('1535,640 1690,640 1690,2480')
arrow('1690,2250 1535,2250')
arrow('1690,2480 1535,2480')
a.append('<text x="1740" y="1400" transform="rotate(90 1740 1400)" font-family="Arial, sans-serif" font-size="27" fill="#087F87">BUS DATI COMUNE: write_data[7:0]</text>')
box(65,2140,1470,220,'PUNTATORE pointer[13:0]: UN REGISTRO DA 14 BIT',['CURSOR_Y (2038) cambia i 7 bit alti: pointer[13:7] = riga.','CURSOR_X (2030) cambia i 7 bit bassi: pointer[6:0] = colonna.','Riga valida 0…59, colonna valida 0…79. Gli accessi fuori intervallo sono ignorati.','La CPU imposta la posizione soltanto con CURSOR_X e CURSOR_Y.'])
box(65,2400,710,180,'COLORE color[7:0]',['write_data viene salvato se scelto dal decoder.','Bit 7…4 sfondo, bit 3…0 testo. Esempio: 1E.'],GOLD)
box(825,2400,710,180,'CONTROLLI control[7:0]',['Bit 0…4: cursore e avanzamento.','I bit 7…5 vengono mantenuti a zero.'])
text(65,2645,'Sul clock FPGA, solo il destinatario selezionato acquisisce write_data.',29,TEAL,True)
text(65,2691,'Condizioni: write_enable attivo, CPU in RUN e motore comandi libero.',27,MUTED)
# practical example
box(65,2730,1470,155,'ESEMPIO: SCRITTURA DI 0A A 2030',['Selettore CURSOR_X attivo + write_data=0A  →  pointer[6:0]=10.','pointer[13:7] conserva la riga precedente. Il registro colore resta invariato.'], '#FFFFFF')
# next writing to cells
arrow('800,2885 800,2930')
box(65,2930,1470,155,'5. SCRITTURA DEL CARATTERE NELLA MEMORIA VIDEO',['Una successiva scrittura di 45 a 2000 salva ASCII 45 e il colore corrente nella cella.','Indirizzo interno della cella = pointer = riga × 128 + colonna. Poi può avanzare.'])
text(65,3150,'Il circuito video legge memoria, font e palette e genera HDMI anche con la CPU ferma.',28,TEAL,True)
text(65,3210,'Schema funzionale da cpu8_video_bus.v e cpu8_video_core.v. Tutti gli indirizzi sono esadecimali.',24,MUTED)
svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs><marker id="arr" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto" markerUnits="strokeWidth"><path d="M0,0 L0,6 L8,3 z" fill="{TEAL}"/></marker></defs>'+''.join(a)+'</svg>'
(OUT/'fpga-video-decoder-registri-verticale.svg').write_text(svg)
