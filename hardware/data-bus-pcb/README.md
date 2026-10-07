# CPU8 — bus dati a 8 bit, revisione A

Layout slim con LED compatti e switch del 7 ottobre 2026: **235 × 40 mm**, rispetto ai precedenti 180 × 60 mm.
Il 74HCT244 segue la fila degli otto connettori sul lato destro.
Serigrafia sul fronte: **Progettato da Enzo Tasca**. Questa versione usa la
revisione **A**, come richiesto, e sostituisce il precedente layout B.
Le piedinature elettriche rimangono compatibili con ALU J4/J6.

PCB da saldare con **otto porte bidirezionali** J1…J8, **otto LED D7…D0**,
un buffer per gli indicatori e una spia PWR. Tutte le porte sono collegate
in parallelo: qualunque porta può essere usata da un modulo che legge
oppure da un modulo che scrive. Il connettore dati è compatibile con
**J4 dell'ALU revisione A** del repository.

La scheda distribuisce dati e massa. L'alimentazione del monitor entra da
J9; il clock, i comandi LOAD e le abilitazioni delle uscite viaggiano
separatamente, dalla centralina ai rispettivi moduli.

## File consegnati

- `CPU8_DATA_BUS_REV_A_GERBER.zip`: da caricare sul servizio di produzione PCB.
- `CPU8_DATA_BUS_REV_A_PROJECT.zip`: sorgenti KiCad, librerie, schema, BOM e rapporti.
- `source/data_bus_rev_a.kicad_pro`: progetto da aprire in KiCad.
- `data_bus_rev_a_schematic.pdf`: schema elettrico, tre pagine.
- `data_bus_rev_a_preview.png`: anteprima della scheda nuda, senza modelli dei componenti.
- `data_bus_rev_a_layout.svg`: piste e serigrafia.
- `BOM.csv`: distinta con valori, package e dimensioni per il montaggio.
- `verification/`: controlli elettrici, di layout, di collegamento e integrità degli export.

Lo ZIP Gerber ordina una **scheda vuota**: i componenti e gli zoccoli vanno
acquistati e saldati separatamente. Non è stato effettuato alcun ordine.

## Piedinatura

Guardando il lato componenti con il titolo in alto, il pin 1 è la piazzola
quadrata in alto a sinistra. Tutti i connettori hanno due colonne a passo
2,54 mm: righe 1/2, 3/4, 5/6, ecc.

| Porta dati J1…J8 | Colonna sinistra | Colonna destra |
| --- | --- | --- |
| Riga 1 | Pin 1: D0 | Pin 2: D1 |
| Riga 2 | Pin 3: D2 | Pin 4: D3 |
| Riga 3 | Pin 5: D4 | Pin 6: D5 |
| Riga 4 | Pin 7: D6 | Pin 8: D7 |
| Riga 5 | Pin 9: GND | Pin 10: GND |

**Le porte dati non contengono +5 V.** Usare header maschi non schermati
2×5 e cavi con collegamento pin-a-pin. Non ruotare il connettore di 180°;
controllare i cavi con il tester prima dell'accensione.

| J9 POWER_5V | Colonna sinistra | Colonna destra |
| --- | --- | --- |
| Riga 1 | Pin 1: +5 V | Pin 2: GND |
| Riga 2 | Pin 3: +5 V | Pin 4: GND |

J9 è un header 2×2 con la stessa piedinatura di J6 dell'ALU. Alimentare
monitor e moduli da una sorgente comune a **5 V regolati** e collegare le
masse. I moduli ricevono +5 V dai loro connettori di alimentazione, non
attraverso J1…J8. I pin duplicati di J9 sono la stessa rete, non due ingressi
di alimentazione indipendenti.

## Come si legge e si scrive sul bus

**Lettura:** collegare gli ingressi dati di un registro o di un altro
circuito a una porta. Quel modulo acquisisce il dato quando riceve il suo
clock/comando LOAD. Il bus non genera questi comandi.

**Scrittura:** collegare le uscite di un buffer tri-state del modulo a una
porta. La centralina abilita quel buffer quando il modulo deve trasmettere
il dato; lo disabilita negli altri momenti. Esempi sono un registro con
buffer 74HCT244/245, l'uscita della RAM opportunamente controllata o J4
dell'ALU. **Può essere abilitato un solo modulo che scrive alla volta**;
più moduli possono leggere contemporaneamente.

Non collegare direttamente sul bus uscite push-pull sempre attive di
registri o porte logiche. Questa scheda non contiene un arbitro e non
rileva due moduli che pilotano il bus contemporaneamente. Anche se i LED
mostrano un valore, non significa che le abilitazioni siano corrette.

Il monitor U1 è un [SN74HCT244N](https://www.ti.com/lit/ds/symlink/sn74hct244.pdf):
i suoi ingressi leggono il bus, le sue uscite alimentano soltanto i LED.
Il carico dei LED è quindi separato dalle linee dati. Le due abilitazioni
del monitor, pin 1 e 19, sono collegate alla rete `LED_OE_n`: **SW1 ON**
le porta a GND e abilita gli indicatori; **SW1 OFF** le lascia alte tramite
R10 da 10 kΩ e disabilita le uscite LED. Nessuna uscita attiva del monitor pilota D0…D7.

RN1 aggiunge un pull-down da 10 kΩ per bit, con carico nominale di 0,5 mA
quando un bit è a 5 V. Con questa scheda da sola e senza un trasmettitore,
i LED dati sono spenti. Gli indicatori non distinguono uno zero trasmesso
da un bus non pilotato. Con moduli esterni, verificare il carico totale e
le tensioni effettive del bus durante il collaudo.

I LED visualizzano il valore istantaneo e non lo memorizzano: sono utili
con dati statici e clock manuale. A velocità elevate l'occhio vede una
luminosità media; per catturare un byte a un preciso istante occorre un
registro o un analizzatore logico. La scheda non include un latch del display.

Gli ingressi del monitor accettano livelli TTL. Il bus resta un'interfaccia
logica a 5 V: per FPGA e altri dispositivi a 3,3 V usare adattamento dei
livelli adeguato ai dispositivi effettivi. Nessuna frequenza massima è
stata misurata. Per iniziare usare pochi moduli e cavi corti.

## Collegamento all'ALU esistente

1. Collegare **ALU J4 → BUS J1**, pin-a-pin. J2…J8 restano disponibili.
2. Alimentare **ALU J6** e **BUS J9** con la stessa sorgente a 5 V e GND.
3. Sul bus mettere **SW1 ON** per accendere gli indicatori. Sull'ALU mettere SW4 ON per gli operandi locali, inizialmente SW5 OFF.
4. Impostare A = `00000101`, B = `00000011`, OP = `0111` (ADD).
5. Abilitare l'ALU con SW5 ON: 5 + 3 = 8, quindi si accende **D3** sul bus.
6. Disabilitare l'ALU prima di abilitare un altro modulo che scrive.

Gli ingressi A/B dell'ALU, J1/J2, normalmente ricevono i valori dai
registri A e B: **non sono le porte per l'uscita dell'ALU sul bus**.
J7 dell'ALU è un'uscita del risultato interno sempre attiva: non usarla
come porta bus al posto di J4.

Con un registro collegato, il percorso è:

```text
ALU J4 ── BUS J1 ── linee D0…D7 comuni ── BUS J2 ── ingressi del registro
                     │
                     └── U1 ── resistori ── LED D7…D0
```

Per far leggere quel byte al registro, la centralina deve inviare al
registro il suo comando di acquisizione. Per farlo scrivere in un altro
momento, serve un'uscita tri-state del registro controllata separatamente.

## LED ravvicinati e interruttore SW1

I LED hanno un interasse di **4 mm**, con **2 mm aggiuntivi ogni quattro bit**:
D7 D6 D5 D4 | D3 D2 D1 D0.
I LED dati/indirizzo hanno i piedini disposti verticalmente, distanti 2,54 mm:
**pin 1 catodo in alto, pin 2 anodo in basso**. PWR mantiene i piedini
orizzontali con catodo a sinistra. Le piazzole quadrate identificano il pin 1.

**SW1 = C&K SDA01H0BD**, SPST a una posizione, through-hole, file distanti
7,62 mm; pin 1 = `LED_OE_n`, pin 2 = GND. **ON chiude il contatto**.
R10 è un resistore assiale **10 kΩ**, 1/4 W, passo 7,62 mm, tra +5 V e OE_n.
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

## Componenti e montaggio

33 componenti: un SN74HCT244N, otto connettori 2×5, un connettore 2×2,
nove LED verdi da 3 mm, nove resistori da 2,2 kΩ, una rete resistiva SIP-9,
un condensatore ceramico, un elettrolitico, SW1 e un pull-up da 10 kΩ. Aggiungere uno zoccolo DIP-20
con file distanti 7,62 mm. Tutti i componenti sono through-hole.

- **U1:** PDIP-20, tacca in alto e pin 1 quadrato. Non sostituire con SOIC.
- **D1…D8:** rispettivamente D0…D7; sul PCB la fila è ordinata da sinistra
  **D7, D6, D5, D4, D3, D2, D1, D0**. La sigla componente D8 identifica
  quindi il LED del bit D7: seguire il testo del bit sotto ciascun LED.
- **D9:** spia PWR. Tutti i LED hanno **pin 1 catodo**, **pin 2 anodo**;
  la linea piatta in serigrafia indica il catodo. Passo 2,54 mm.
- **R1…R9:** 2,2 kΩ, 1/4 W, passo 7,62 mm. Corrente LED nell'ordine
  di 1 mA; usare LED ad alta efficienza.
- **RN1:** rete **bussed SIP-9, otto resistenze da 10 kΩ**, comune al pin 1
  quadrato verso GND. Passo 2,54 mm. Una rete con resistenze isolate non
  è compatibile.
- **C1:** 100 nF ceramico, passo 2,50 mm, corpo entro 4 × 3 mm.
- **C2:** 10 µF, almeno 16 V, passo 2,50 mm, diametro entro 5 mm;
  **pin 1 positivo**, pin 2 GND. Il PCB riporta anche il simbolo +.
- I piani GND usano connessioni solide: saldare i pin di massa con una
  punta adeguata e sufficiente trasferimento di calore.

## Ordine PCB e verifiche

| Parametro | Valore |
| --- | --- |
| Dimensioni | **235 × 40 mm** |
| Rame | Due strati, 1 oz |
| Materiale / spessore | FR-4 / 1,6 mm |
| Maschera / serigrafia | Verde / bianca sul fronte |
| Finitura | HASL senza piombo o ENIG |
| Assemblaggio / stencil | Nessuno, montaggio manuale |
| Piste | 0,30 mm, restringimenti minimi 0,15 mm |
| Clearance | 0,25 mm; minimo assoluto di progetto 0,20 mm |
| Via | Diametro 0,70 mm, foro 0,30 mm |
| Fori componenti | 0,80 e 0,90 mm, metallizzati |
| Montaggio | Quattro fori 3,20 mm, non metallizzati |

Caricare il solo ZIP Gerber e controllare che l'anteprima del produttore
riconosca 235 × 40 mm, due strati di rame e i due file di foratura.

- ERC: **0 violazioni**.
- DRC: **0 violazioni**, **0 collegamenti mancanti**.
- Parità PCB/schema: **0 problemi**.
- Verifica di **512 casi**: 256 valori del bus × due stati di SW1; display
  corretto quando ON, uscite LED in alta impedenza quando OFF, porte bus invariate.
- Controllo dell'isolamento del monitor: nessuna sua uscita pilota il bus.
- Export KiCad 10.0.7, pacchetti con controllo d'integrità e manifest SHA-256.

**Il prototipo fisico non è ancora stato montato e collaudato.** Prima di
inserire U1 verificare polarità e alimentazione dello zoccolo. Accendere
inizialmente con alimentatore a corrente limitata e gli altri moduli
scollegati. Provare poi un solo trasmettitore, con dati statici, prima di
aggiungere registri e clock. Misurare livelli e tempi sotto carico prima
di aumentare la frequenza.

Gli script in `tools/` documentano costruzione e controlli. Il generatore
ricrea una scheda **senza piste** soltanto con `--rebuild-unrouted`;
per le normali modifiche aprire i sorgenti KiCad finali e preservare le piste.
La ricostruzione completa richiede nuovo export XML, `prepare_board.py`
con pcbnew, instradamento DSN/SES, `finish_board.py`, verifiche ed export.

## Disposizione meccanica del layout slim

- Quattro fori di montaggio da 3,2 mm: (4,4), (231,4), (4,36), (231,36) mm; origine nell'angolo superiore sinistro.
- J1…J8: pin 1 a x=10,33,56,79,102,125,148,171 mm, y=10 mm.
- U1: pin 1 a (195,10) mm; RN1 a destra dei connettori.
- LED da sinistra D7…D0, pin 1 a x=72,76,80,84,90,94,98,102 mm e y=30 mm; alimentazione J9 a destra.
- Componenti sempre sul fronte, integrati con tacca verso l'alto. I valori
  di header, rete resistiva e switch sono sul layer F.Fab. I riferimenti
  dei LED dati sono su F.Fab, lasciando soltanto D7…D0 visibili sul fronte.
- Lo spazio per i corpi dei connettori è riferito agli header non schermati
  della BOM; verificare l'ingombro dei terminali del cavo scelti per il case.

Usare solo lo ZIP Gerber di questa consegna: gli export precedenti della
revisione B non rappresentano queste dimensioni.

Questa consegna sostituisce anche il precedente layout slim senza SW1.
Il manifest identifica `2026-10-07-slim-led-switch`: usare gli ZIP rigenerati
insieme allo schema e alla BOM di questa versione. Le dimensioni esterne
e i fori di montaggio restano quelli del layout slim.
