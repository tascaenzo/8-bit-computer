# CPU8 — PCB ALU rev. B

Pacchetto per fabbricare una **scheda nuda da saldare**, con sorgenti KiCad.
Versione del 7 ottobre 2026: ALU combinatoria a 8 bit, logica **74HCT a 5 V**,
registri RA/RB e registro dei flag **esterni**. La revisione B aggiunge indicatori e comandi locali alla revisione A.

## File da usare

- `CPU8_ALU_REV_B_GERBER.zip`: caricare questo ZIP nel preventivatore PCB.
- `CPU8_ALU_REV_B_PROJECT.zip`: progetto modificabile e documentazione.
- `source/alu_rev_b.kicad_pro`: aprire in KiCad per accedere a schema e PCB.
- `alu_rev_b_schematic.pdf`: schema completo, con tutti i pin e le reti.
- `BOM.csv`: componenti da acquistare per il montaggio manuale.
- `alu_rev_b_preview.png`: anteprima della scheda nuda.
- `alu_rev_b_layout.svg`: visualizzazione delle piste e della serigrafia.

Lo ZIP Gerber non include i componenti: non è un ordine di assemblaggio.
Non sono stati effettuati ordini o caricamenti sui siti dei produttori.

## Parametri per l'ordine

| Parametro | Impostazione |
| --- | --- |
| Dimensioni | 290 × 300 mm |
| Materiale | FR-4 |
| Strati rame | 2 |
| Spessore | 1,6 mm |
| Rame | 1 oz |
| Maschera | Verde, entrambi i lati |
| Serigrafia | Bianca, fronte |
| Finitura | HASL senza piombo oppure ENIG |
| Assemblaggio | Nessuno; componenti saldati a mano |
| Stencil | Nessuno |
| Via | Diametro rame 0,70 mm, foro 0,30 mm |
| Fori componenti | 0,80 e 0,90 mm, metallizzati |
| Fori montaggio | Quattro fori da 3,20 mm, non metallizzati |

Le piste sono generalmente da 0,30 mm, con restringimenti locali fino a
0,15 mm. Le regole di clearance del progetto sono 0,25 mm; clearance minima
assoluta verificata 0,20 mm. Gli anelli delle via sono da 0,20 mm.
Le capacità pubblicate da [JLCPCB](https://jlcpcb.com/capabilities/Capabilities)
e [PCBWay](https://www.pcbway.com/capabilities.html) consentono queste dimensioni
con rame da 1 oz. Verificare che l'anteprima del produttore riconosca tutti
i layer e i due file di foratura e mostri 290 × 300 mm.

## Cosa contiene la scheda

Dieci operazioni, due sommatori a quattro bit in cascata, selezione del
risultato mediante otto multiplexer, buffer tri-state del bus e flag
combinatori C/Z/N/O. Nessun clock è necessario sulla scheda: i registri che
catturano dati e flag si trovano all'esterno.

La selezione mediante multiplexer modifica l'implementazione fisica descritta
negli articoli con decoder e buffer separati, mantenendo la semantica della ISA.
Non si tratta di una copia delle connessioni della millefori esistente.

| OP3 OP2 OP1 OP0 | Operazione | Risultato |
| --- | --- | --- |
| 0000 | AND | A AND B |
| 0001 | OR | A OR B |
| 0010 | XOR | A XOR B |
| 0011 | NOR | NOT(A OR B) |
| 0100 | NAND | NOT(A AND B) |
| 0101 | XNOR | NOT(A XOR B) |
| 0110 | NOT | NOT A |
| 0111 | ADD | A + B, modulo 256 |
| 1000 | SUB | A - B, modulo 256 |
| 1001 | CMP | Sottrazione interna; bus disabilitato |
| 1010–1111 | Riservate | Bus disabilitato; flag non definiti per la ISA |

C indica carry in ADD e **borrow** in SUB/CMP. Z indica risultato zero;
N è il bit 7 del risultato; O indica overflow signed. C e O sono azzerati
per le operazioni logiche. I flag derivano dal risultato interno, anche quando
il buffer del bus è disabilitato.

## LED e modalità autonoma

- **16 LED verdi** mostrano A7…A0 e B7…B0 dopo la selezione della sorgente.
- **4 LED gialli** mostrano C, Z, N e O del risultato interno.
- **10 LED blu** mostrano AND, OR, XOR, NOR, NAND, XNOR, NOT, ADD, SUB e CMP.
  Gli opcode riservati non accendono alcun LED di operazione.
- **SW4 OFF = esterna**, **SW4 ON = locale**. Sei 74HCT157 commutano tutti
  i 21 segnali: A, B, opcode e ALU_EN_n. Le due sorgenti restano separate;
  gli interruttori non portano +5 V sulle uscite dei moduli esterni.
- **SW1** imposta A, **SW2** B: da sinistra bit 7, 6, 5, 4, 3, 2, 1, 0.
  **SW3** imposta l'opcode: da sinistra OP3, OP2, OP1, OP0.
  Per ciascun contatto, OFF = 0 e ON = 1.
- **SW5 OFF** disabilita il bus in modalità locale; **SW5 ON** lo abilita.
  CMP e gli opcode riservati mantengono comunque J4 in alta impedenza.
  In modalità esterna SW5 non interviene: decide J3 pin 5.

Per il primo test standalone collegare solo J6 a 5 V regolati e GND,
lasciare J4 scollegato, mettere SW4 ON e scegliere A/B/OP mediante SW1–SW3.
Il risultato interno è disponibile su J7; i LED indicano operandi, flag e
operazione. Questa revisione non include otto LED di risultato.
Esempio ADD: SW1 = 11111111, SW2 = 00000001, SW3 = 0111:
si accendono ADD, C e Z; N/O sono spenti; J7 vale 00.

I LED di A/B/flag sono pilotati da tre buffer 74HCT244 dedicati;
i due 74HCT138 decodificano l'operazione. Ogni LED ha una resistenza da
2,2 kΩ, con corrente nell'ordine di 1 mA: usare LED ad alta efficienza.
I flag sono combinatori e non memorizzati: possono cambiare durante lo
spostamento dei DIP switch. Cambiare sorgente con il bus disabilitato
su entrambe le sorgenti e attendere l'assestamento prima della cattura.

## Connettori

Tutti i connettori hanno due colonne, passo 2,54 mm. Guardando il lato componenti,
con il testo della scheda in alto, il pin 1 è la piazzola quadrata in alto a
sinistra. La prima riga contiene 1/2, la seconda 3/4, e così via.
La piedinatura è specifica di questa scheda: preparare i cavi di conseguenza.

| Connettore | Pin | Segnali |
| --- | --- | --- |
| J1 A_INPUT | 1–8; 9–10 | A0…A7; GND, GND |
| J2 B_INPUT | 1–8; 9–10 | B0…B7; GND, GND |
| J3 CONTROL | 1, 2, 3, 4 | OP0, OP1, OP2, OP3 |
| J3 CONTROL | 5; 6–8 | ALU_EN_n; GND, GND, GND |
| J4 DATA_BUS | 1–8; 9–10 | D0…D7; GND, GND |
| J5 FLAGS_CZNO | 1–6 | C, Z, N, O, GND, GND |
| J6 POWER_5V | 1–4 | +5V, GND, +5V, GND |
| J7 RESULT_TEST | 1–8; 9–10 | R0…R7 interni; GND, GND |

ALU_EN_n = 1 disabilita l'uscita sul bus. ALU_EN_n = 0 la abilita solo
per OP 0…8; CMP e gli opcode riservati lasciano comunque D in alta impedenza.
Un pull-up da 4,7 kΩ disabilita l'uscita quando il controllo è scollegato.
A/B/opcode hanno pull-down da 10 kΩ.

J5 e J7 sono uscite push-pull: usarle come ingressi di altri circuiti o punti
di misura, senza collegarle a un bus pilotato da altre sorgenti. J4 è l'unica
uscita dati tri-state. Collegare le masse dei moduli.

Gli ingressi HCT accettano livelli TTL, ma alimentare questa scheda con 5 V
regolati; non collegare le sue uscite da 5 V direttamente a una FPGA a 3,3 V.
La compatibilità e il carico dei moduli esterni vanno verificati con le sigle
complete degli integrati effettivamente utilizzati.

## Componenti e montaggio

La distinta contiene 172 componenti: 45 IC, 45 condensatori da 100 nF, un
condensatore da 10 µF, sei reti resistive, 33 resistori, sette connettori,
30 LED e cinque DIP switch. Aggiungere **23 zoccoli DIP-14, 18 DIP-16 e quattro DIP-20**, tutti larghi 7,62 mm.
Non sostituire i package DIP con SOIC. Per i multiplexer utilizzare CD74HCT151E:
la distinzione fra uscita diretta Y (pin 5) e complementare W (pin 6) segue
il datasheet TI attuale.

- Orientare la tacca degli IC verso l'alto; il pin 1 ha piazzola quadrata.
- RN1…RN6 devono essere **reti bussed SIP-9**, comune al pin 1:
  otto resistenze da 10 kΩ verso il comune. Le reti a resistenze isolate
  non sono compatibili.
- C46 è il condensatore elettrolitico da 10 µF: **pin 1 positivo**, pin 2 GND.
- C1…C45 sono ceramici non polarizzati, passo 2,50 mm e corpo entro 4 × 3 mm.
- SW1/SW2: C&K **SDA08H0BD**; SW3: **SDA04H0BD**;
  SW4/SW5: **SDA01H0BD**, versioni through-hole. Passo contatti 2,54 mm,
  distanza fra le file 7,62 mm, contatti SPST opposti. Orientare il corpo
  come indicato in serigrafia e verificare ON prima di saldare.
- LED da 3 mm, passo 2,54 mm: **pin 1 K/catodo**, **pin 2 A/anodo**.
  Il catodo è indicato dalla linea piatta in serigrafia. Nelle spie di
  operazione il catodo è collegato al decoder, non direttamente a GND.
- R1/R3 sono 4,7 kΩ, R2 è 10 kΩ, R4…R33 sono 2,2 kΩ;
  resistori assiali 1/4 W, passo 7,62 mm.
- U34…U39: **SN74HCT157N**; U44/U45: **SN74HCT138N**;
  U33/U40/U41/U42: **SN74HCT244N**, package PDIP.
- Le connessioni al piano di massa sono solide. Saldare i pin GND con
  una punta adeguata e sufficiente trasferimento di calore.

## Verifiche effettuate e collaudo

- Simulazione statica a livello di pin degli IC su **4.194.304 combinazioni**
  A/B/OP/enable in entrambe le modalità, con sorgente inattiva complementata, comprese le operazioni valide, flag e stato del buffer.
- ERC dello schema: **0 violazioni**.
- DRC del PCB: **0 violazioni**, **0 collegamenti mancanti**.
- Corrispondenza PCB/schema: **0 problemi**.
- Esportazione Gerber e foratura tramite KiCad 10.0.7.

I rapporti sono nella cartella `verification`. Questi controlli verificano
il progetto digitale e il layout; **nessun prototipo fisico è stato montato
né collaudato**. La frequenza massima, i carichi dei cavi e i tempi di
assestamento non sono stati misurati: iniziare con operandi e opcode statici,
poi con clock manuale e misurare prima di aumentare la frequenza.

Prima di inserire gli IC, controllare il montaggio e l'alimentazione degli
zoccoli. Eseguire i primi test con un alimentatore da banco a corrente limitata.
Disabilitare l'uscita durante il cambio di opcode e attendere l'assestamento
prima che i registri esterni catturino risultato e flag. Nessun altro modulo
può pilotare J4 mentre questa ALU è abilitata.

| Operazione | A | B | R interno | C | Z | N | O |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AND | A5 | 3C | 24 | 0 | 0 | 0 | 0 |
| ADD | FF | 01 | 00 | 1 | 1 | 0 | 0 |
| ADD | 7F | 01 | 80 | 0 | 0 | 1 | 1 |
| SUB | 05 | 0A | FB | 1 | 0 | 1 | 0 |
| SUB | 80 | 01 | 7F | 0 | 0 | 0 | 1 |
| CMP | 03 | 03 | 00 | 0 | 1 | 0 | 0 |

I numeri nella tabella sono esadecimali. Per CMP leggere R su J7 e verificare
che J4 resti ad alta impedenza. Per questo test usare un carico resistivo
appropriato o una sonda: il valore letto su un bus flottante non prova lo
stato tri-state.

## Riferimenti

Semantica: `docs/isa.md` e `docs/control-unit-microcode.md` del repository.
Piedinature controllate sui datasheet ufficiali:
[CD74HCT151](https://www.ti.com/lit/ds/symlink/cd74hct151.pdf),
[CD74HCT283](https://www.ti.com/lit/ds/symlink/cd74hct283.pdf),
[SN74HCT244](https://www.ti.com/lit/ds/symlink/sn74hct244.pdf),
[SN74HCT02](https://www.ti.com/lit/ds/symlink/sn74hct02.pdf),
[SN74HCT157](https://www.ti.com/lit/ds/symlink/sn74hct157.pdf),
[SN74HCT138](https://www.ti.com/lit/ds/symlink/sn74hct138.pdf),
[C&K SDA](https://www.ckswitches.com/media/1327/sda.pdf).

Gli script in `tools` documentano la generazione iniziale e le verifiche.
`build_alu.py --rebuild-unrouted` ricrea una scheda **senza piste**:
richiede nuovo instradamento, DRC, esportazione e confezionamento. Per normali
modifiche lavorare sui sorgenti KiCad finali, preservando le piste esistenti.

Per ricostruire completamente: generare il layout non instradato; esportare
`source/schematic.xml` con `kicad-cli sch export netlist --format kicadxml`;
eseguire `prepare_board.py` con il Python pcbnew di KiCad; instradare il DSN
esportato e salvare la sessione SES; eseguire `finish_board.py`; verificare
ERC, DRC con parità e simulazione; esportare nuovamente Gerber/forature prima
di usare `package_fabrication.py`. `prepare_board.py` ed `finish_board.py`
richiedono pcbnew; gli altri script usano Python standard.
