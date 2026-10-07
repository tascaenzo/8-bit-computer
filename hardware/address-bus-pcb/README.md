# CPU8 — bus indirizzi a 16 bit, revisione A

Layout slim con LED compatti e switch del 7 ottobre 2026: **300 × 46 mm**, rispetto ai precedenti
240 × 60 mm. I due 74HCT244 seguono la fila degli otto connettori sul lato
destro. Serigrafia sul fronte: **Progettato da Enzo Tasca**. Revisione **A**.
Le piedinature elettriche restano uguali.

Scheda di distribuzione con **otto porte parallele**, **16 LED A15…A0**,
due buffer SN74HCT244N e una spia PWR. PCB **300 × 46 mm**, due strati,
componenti through-hole, altezza ridotta per una disposizione a vista nel case.

Le porte sono equivalenti. PC, MAR o IDX possono trasmettere un indirizzo;
RAM, ROM, decoder e altri moduli possono leggerlo contemporaneamente.
La scelta della sorgente è esterna: questa scheda non genera indirizzi e
non implementa il selettore della centralina.

## File da usare

- `CPU8_ADDRESS_BUS_REV_A_GERBER.zip`: file di produzione della scheda nuda.
- `CPU8_ADDRESS_BUS_REV_A_PROJECT.zip`: progetto modificabile e documentazione.
- `source/address_bus_rev_a.kicad_pro`: progetto da aprire in KiCad.
- `address_bus_rev_a_schematic.pdf`: schema elettrico, quattro pagine.
- `address_bus_rev_a_preview.png`: anteprima del PCB senza componenti montati.
- `address_bus_rev_a_layout.svg`: piste, piazzole e serigrafia.
- `BOM.csv`: componenti, package e dimensioni di montaggio.
- `verification/`: rapporti elettrici, di layout, di verifica digitale e manifest SHA-256.

I componenti vanno acquistati e saldati separatamente. Non è stato
eseguito alcun ordine presso un produttore.

## Connettori indirizzi J1…J8

Header maschi **2×10, passo 2,54 mm, non schermati**. Guardando il lato
componenti con il titolo in alto, il pin 1 quadrato è in alto a sinistra.
Le righe sono 1/2, 3/4, ecc. Collegare i cavi pin-a-pin, senza inversioni.

| Riga | Sinistra | Destra |
| --- | --- | --- |
| 1 | 1: A0 | 2: A1 |
| 2 | 3: A2 | 4: A3 |
| 3 | 5: A4 | 6: A5 |
| 4 | 7: A6 | 8: A7 |
| 5 | 9: A8 | 10: A9 |
| 6 | 11: A10 | 12: A11 |
| 7 | 13: A12 | 14: A13 |
| 8 | 15: A14 | 16: A15 |
| 9 | 17: GND | 18: GND |
| 10 | 19: GND | 20: GND |

A0 è il bit meno significativo dell'indirizzo; A15 è il più significativo.
Queste porte **non contengono +5 V** e non hanno la stessa piedinatura delle
porte da 10 pin del bus dati. A0…A15 qui indicano indirizzi, non l'operando
A della ALU: non collegare queste porte agli ingressi A/B dell'ALU.

## Alimentazione J9

Header 2×2 con pin **1/3 = +5 V**, **2/4 = GND**. È la stessa piedinatura
del J9 del bus dati e del J6 dell'ALU. Alimentare tutte le schede da una
sorgente comune a 5 V regolati e collegare le masse. I moduli ricevono
+5 V dai loro connettori di alimentazione, non attraverso le porte indirizzi.
I pin duplicati di J9 appartengono alla stessa rete.

## Monitor LED e trasmissione degli indirizzi

U1 legge A0…A7 e U2 legge A8…A15. Le loro uscite pilotano soltanto i LED
attraverso resistori da 2,2 kΩ; nessuna uscita del monitor pilota il bus.
SW1 pilota insieme i pin 1 e 19 di U1 e U2: ON li porta a GND e abilita
i 16 LED; OFF li lascia alti tramite R18 da 10 kΩ e disabilita le uscite LED.
I due buffer separano il carico dei LED dalle linee di indirizzo; **non
rigenerano il segnale lungo i collegamenti del bus**. La piedinatura segue
il [datasheet TI SN74HCT244](https://www.ti.com/lit/ds/symlink/sn74hct244.pdf).

RN1 e RN2 aggiungono un pull-down da 10 kΩ per ogni bit, con carico
nominale di 0,5 mA per linea alta a 5 V. Con la scheda da sola e senza
una sorgente, i LED indirizzo restano spenti. Questo non distingue un
indirizzo 0000 trasmesso da un bus non pilotato.

I LED sono ordinati da sinistra **A15, A14, …, A1, A0** e mostrano il valore
istantaneo, senza memorizzarlo. Con dati statici o clock manuale si legge
il numero binario; a velocità elevate si vede una luminosità media. Per
catturare un indirizzo a un preciso istante serve un latch o un analizzatore.

**Abilitare una sola sorgente di indirizzo alla volta.** Le uscite di PC,
MAR e IDX devono raggiungere il bus tramite buffer tri-state o un selettore
appropriato. Non collegare in parallelo tre uscite push-pull sempre attive.
RAM e ROM leggono gli indirizzi dai propri ingressi; i comandi di memoria
/CE, /OE, /WE e i dati D0…D7 viaggiano separatamente.

Nel progetto CPU8, `ADDR_SEL` sceglie `00=IDX`, `01=PC`, `10=MAR`,
`11=nessuna sorgente`: vedere [la centralina](../../docs/control-unit-microcode.md).
Il decoder di queste abilitazioni resta sui moduli o nella centralina,
non su questa scheda bus. La mappa degli indirizzi e la selezione RAM/ROM/I/O
restano compito dei rispettivi decoder.

Esempio di assegnazione, modificabile perché tutte le porte sono uguali:

| Porta | Modulo |
| --- | --- |
| J1 | PC, uscita tri-state |
| J2 | MAR, uscita tri-state |
| J3 | IDX, uscita tri-state |
| J4 | RAM, ingressi indirizzo |
| J5 | ROM, ingressi indirizzo |
| J6 | Decoder di indirizzi |
| J7 | Modulo I/O o video, con adattamento dei livelli dove necessario |
| J8 | Espansione o strumento di misura |

Il bus è a 5 V: per FPGA e dispositivi a 3,3 V usare adattamento dei livelli
compatibile con i dispositivi effettivi. Iniziare con pochi moduli e cavi
corti. Frequenza massima, integrità del segnale e carichi dei cavi non sono
stati misurati sul prototipo.

## LED ravvicinati e interruttore SW1

I LED hanno un interasse di **4 mm**, con **2 mm aggiuntivi ogni quattro bit**:
A15 A14 A13 A12 | A11 A10 A9 A8 | A7 A6 A5 A4 | A3 A2 A1 A0.
I LED dati/indirizzo hanno i piedini disposti verticalmente, distanti 2,54 mm:
**pin 1 catodo in alto, pin 2 anodo in basso**. PWR mantiene i piedini
orizzontali con catodo a sinistra. Le piazzole quadrate identificano il pin 1.

**SW1 = C&K SDA01H0BD**, SPST a una posizione, through-hole, file distanti
7,62 mm; pin 1 = `LED_OE_n`, pin 2 = GND. **ON chiude il contatto**.
R18 è un resistore assiale **10 kΩ**, 1/4 W, passo 7,62 mm, tra +5 V e OE_n.
Un solo switch governa tutti i buffer LED di questa scheda.

- **ON:** OE_n basso; i LED mostrano i bit del bus.
- **OFF:** OE_n alto; le uscite dei 74HCT244 sono in alta impedenza e i LED
  dei bit sono inattivi. La spia PWR resta accesa.
- L'interruttore non interrompe dati, indirizzi o alimentazione degli altri
  moduli; i pull-down del bus restano presenti. Non è un interruttore generale.

Il livello alto/basso e lo stato tri-state seguono il
[datasheet TI SN74HCT244](https://www.ti.com/lit/ds/symlink/sn74hct244.pdf).
Ingombro e piedinatura di SW1 seguono il
[datasheet C&K SDA](https://www.ckswitches.com/media/1327/sda.pdf).

## Distinta e montaggio

52 componenti: due SN74HCT244N, otto header 2×10, un header 2×2, 17 LED
verdi da 3 mm, 17 resistori da 2,2 kΩ, due reti resistive e tre condensatori, più SW1 e il pull-up R18 da 10 kΩ.
Aggiungere **due zoccoli DIP-20**, con file distanti 7,62 mm.

- U1/U2: package PDIP-20, tacca in alto; pin 1 quadrato.
- D1…D16: rispettivamente LED dei bit A0…A15. Seguire il nome A del bit
  sotto il LED: ad esempio il componente D16 è la spia A15.
- D17: spia PWR. LED passo 2,54 mm: **pin 1 catodo**, pin 2 anodo;
  la linea piatta in serigrafia indica il catodo.
- R1…R17: 2,2 kΩ, 1/4 W, passo 7,62 mm, corpo entro 6,3 × 2,5 mm.
  Usare LED ad alta efficienza: corrente nell'ordine di 1 mA.
- RN1/RN2: **SIP-9 bussed, otto resistenze da 10 kΩ**, comune al pin 1,
  passo 2,54 mm. Le reti a resistenze isolate non sono compatibili.
- C1/C2: 100 nF ceramici, passo 2,50 mm, corpo entro 4 × 3 mm.
- C3: 10 µF, almeno 16 V, passo 2,50 mm, diametro entro 5 mm;
  **pin 1 positivo**, pin 2 GND. Il PCB riporta il simbolo +.
- I pin GND sono collegati ai piani con connessioni solide: usare una
  punta da saldatura adeguata al trasferimento di calore.

## Ordine e verifiche

| Parametro | Valore |
| --- | --- |
| Dimensioni | **300 × 46 mm** |
| Materiale / spessore | FR-4 / 1,6 mm |
| Rame | Due strati, 1 oz |
| Maschera / serigrafia | Verde / bianca sul fronte |
| Finitura | HASL senza piombo o ENIG |
| Assemblaggio / stencil | Nessuno, montaggio manuale |
| Piste / clearance | 0,30 mm, restringimenti fino a 0,15 mm / 0,25 mm |
| Minimo assoluto di clearance | 0,20 mm |
| Via | Diametro 0,70 mm, foro 0,30 mm |
| Fori componenti | 0,80 e 0,90 mm, metallizzati |
| Montaggio | Quattro fori da 3,20 mm, non metallizzati |

Caricare il solo ZIP Gerber e controllare nell'anteprima del produttore
300 × 46 mm, due strati di rame e i due file di foratura.

- ERC: **0 violazioni**.
- DRC: **0 violazioni**, **0 collegamenti mancanti**.
- Parità PCB/schema: **0 problemi**.
- Verifica di **131.072 casi**, tutti i 65.536 indirizzi da 0000 a FFFF
  con SW1 ON e OFF (indicatori inattivi e porte bus invariate quando OFF),
  con controllo delle otto porte, polarità dei LED e isolamento del monitor.
- Export KiCad 10.0.7 e integrità dei pacchetti ZIP verificata.

**Il prototipo fisico deve ancora essere montato e collaudato.** Prima di
inserire gli IC verificare alimentazione e polarità degli zoccoli. Accendere
inizialmente con corrente limitata e moduli esterni scollegati; provare poi
una sola sorgente con indirizzi statici prima di aggiungere gli altri moduli.

| Indirizzo di prova | LED accesi |
| --- | --- |
| 0000 | Nessuno, PWR resta acceso |
| 8001 | A15 e A0 |
| 5555 | A14, A12, A10, A8, A6, A4, A2, A0 |
| AAAA | A15, A13, A11, A9, A7, A5, A3, A1 |
| FFFF | Tutti i 16 LED indirizzo |

Per le prove dei LED portare **SW1 ON**. Gli indirizzi nella tabella sono esadecimali. I LED non provano da soli
che una sorgente sia disabilitata o che non esista un conflitto tra driver.

Gli script in `tools/` documentano generazione e controlli. Il generatore
preserva il PCB esistente salvo `--rebuild-unrouted`; quel comando richiede
nuovo instradamento DSN/SES, controlli ed export. Per le normali modifiche
usare i sorgenti KiCad finali, preservando le piste.

## Disposizione meccanica del layout slim

- Quattro fori di montaggio da 3,2 mm: (4,4), (296,4), (4,42), (296,42) mm; origine nell'angolo superiore sinistro.
- J1…J8: pin 1 a x=10,35,60,85,110,135,160,185 mm, y=8 mm.
- U1/U2: pin 1 rispettivamente (217,8) e (242,8) mm.
- LED da sinistra A15…A0, pin 1 a x=68,72,76,80,86,90,94,98,104,108,112,116,122,126,130,134 mm e y=39 mm; alimentazione J9 a destra.
- Componenti sempre sul fronte, integrati con tacca verso l'alto. I valori
  di header, resistori, reti resistive e switch sono sul layer F.Fab.
  I riferimenti dei LED indirizzo sono su F.Fab, lasciando soltanto A15…A0 sul fronte.
- Lo spazio per i corpi dei connettori è riferito agli header non schermati
  della BOM; verificare l'ingombro dei terminali del cavo scelti per il case.

Questa revisione A sostituisce il precedente layout A da 240 × 60 mm.
Il manifest riporta layout_id `2026-10-07-slim-led-switch` per distinguerli: usare
solo i Gerber e le forature rigenerati insieme in questa consegna.

Questa consegna sostituisce anche il precedente layout slim senza SW1.
Il manifest identifica `2026-10-07-slim-led-switch`: usare gli ZIP rigenerati
insieme allo schema e alla BOM di questa versione. Le dimensioni esterne
e i fori di montaggio restano quelli del layout slim.
