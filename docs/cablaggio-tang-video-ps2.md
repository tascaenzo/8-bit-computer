# Cablaggio Tang Nano 9K, video e tastiera PS/2

Assegnazione della build FPGA video + PS/2 con tutti gli indirizzi A3–A15. La revisione del 13 novembre 2026 aggiunge /CPU_RESET su GPIO 85 (J6-3), attivo basso. Prima del collaudo caricare il nuovo bitstream `hardware/tang-nano-9k-video/build/cpu8_video.fs`.

## Selezione sulla CPU

- A0 → A del 74238 (pin 1), A1 → B (pin 2), A2 → C (pin 3).
- /G2A (pin 4) e /G2B (pin 5) → GND nel cablaggio base. Eventuali interblocchi già presenti vanno mantenuti.
- A3–A15 vanno alla Tang tramite traduttori; A3 seleziona il primo bit del registro interno. A0–A2 non vanno alla Tang.
- S = A15 OR A14 OR A13 → G1 (pin 6) e /CE attivo basso della RAM, rispettando gli interblocchi della CPU.
- Y0 (pin 15) seleziona il video, ID 000. Y1 (pin 14) seleziona la tastiera, ID 001.
- VCC (pin 16) → 5 V, GND (pin 8) → massa comune, 100 nF fra VCC e GND.

Riferimento: [datasheet 74HC238 Toshiba](https://toshiba.semicon-storage.com/info/docget.jsp?did=13440&prodName=TC74HC238AP).

## Alimentazione e traduttori NH245

Usare quattro SN74LVC8T245PWR: U1/U2/U4 per 19 ingressi, U3 per gli 8 dati bidirezionali. Su tutti: pin 1 (VCCA) → 3V3 della Tang (J6-24); pin 23 **e** 24 (VCCB) → 5 V CPU; pin 11, 12 e 13 → massa comune con J6-23. Mettere 100 nF vicino a ciascuna alimentazione di ciascun chip. I numeri sono quelli del chip TSSOP-24, vista dall'alto.

La Tang può essere alimentata via USB-C. Se si usa invece il contatto 5V della Tang con la stessa alimentazione della CPU, tenere scollegata la USB-C alimentata. Il 3V3 della Tang alimenta i lati a 3,3 V dei traduttori, entro la corrente disponibile del regolatore. Il connettore PS/2 prende 5 V dall'alimentazione CPU.

Su **U1, U2 e U4** fissare DIR (pin 2) a GND. Su **U3** collegare DIR (pin 2) a J6-1 (FPGA 63) con pull-down da 10 kΩ e /OE (pin 22) a J6-22 (FPGA 32). Mettere un pull-up da 10 kΩ a 3,3 V sul pin 22 di tutti e quattro i chip. Per U1/U2/U4, usare un jumper comune da /OE a GND e chiuderlo dopo che entrambe le alimentazioni sono stabili e la CPU è ferma. Sulle linee tradotte, tenere Y0 e Y1 bassi e /RD e /WR alti quando U1/U2/U4 sono disabilitati, usando pull-down e pull-up rispettivamente verso GND e 3,3 V, ad esempio 10 kΩ.

Riferimenti: [datasheet TI SN74LVC8T245](https://www.ti.com/lit/ds/symlink/sn74lvc8t245.pdf), [schema Sipeed Tang Nano 9K](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf).

## Collegamenti filo per filo

J5 e J6 sono i riferimenti dello schema Sipeed. QN88 è il numero del pin FPGA da usare nei vincoli. Identificare i contatti sulla revisione fisica prima di cablare.

| Chip | Segnale | Pin lato B, CPU 5 V | Pin lato A, FPGA 3,3 V | Tang | QN88 |
| --- | --- | ---: | ---: | --- | ---: |
| U4 | A3 | 21 | 3 | J6-21 | 31 |
| U4 | BOOT_RUN | 20 | 4 → partitore 3,3/1,8 V | J6-2 | 86 |
| U4 | /CPU_RESET | 19 | 5 → partitore 3,3/1,8 V | J6-3 | 85 |
| U1 | A4 | 21 | 3 | J5-9 | 29 |
| U1 | A5 | 20 | 4 | J5-10 | 30 |
| U1 | A6 | 19 | 5 | J5-11 | 33 |
| U1 | A7 | 18 | 6 | J5-12 | 34 |
| U1 | A8 | 17 | 7 | J5-13 | 40 |
| U1 | A9 | 16 | 8 | J5-14 | 35 |
| U1 | A10 | 15 | 9 | J5-15 | 41 |
| U1 | A11 | 14 | 10 | J5-16 | 42 |
| U2 | A12 | 21 | 3 | J5-17 | 51 |
| U2 | A13 | 20 | 4 | J5-18 | 53 |
| U2 | A14 | 19 | 5 | J5-19 | 54 |
| U2 | A15 | 18 | 6 | J5-20 | 55 |
| U2 | Y0 video | 17 | 7 | J5-5 | 25 |
| U2 | Y1 tastiera | 16 | 8 | J5-6 | 26 |
| U2 | /RD | 15 | 9 | J6-10 | 77 |
| U2 | /WR | 14 | 10 | J6-11 | 76 |
| U3 | D0 | 21 | 3 | J5-1 | 38 |
| U3 | D1 | 20 | 4 | J5-2 | 37 |
| U3 | D2 | 19 | 5 | J5-3 | 36 |
| U3 | D3 | 18 | 6 | J5-4 | 39 |
| U3 | D4 | 17 | 7 | J5-21 | 56 |
| U3 | D5 | 16 | 8 | J5-22 | 57 |
| U3 | D6 | 15 | 9 | J6-19 | 48 |
| U3 | D7 | 14 | 10 | J6-20 | 49 |

J6-21 (FPGA 31) riceve A3 da U4. Su U4 collegare gli ingressi B4–B8 (pin 18–14) a GND e lasciare le uscite A4–A8 (pin 6–10) scollegate. B3/A3 ora trasportano /CPU_RESET: rimuovere il precedente collegamento di B3 a GND. U4 usa le stesse alimentazioni e lo stesso enable di U1/U2. La OR dei bit alti qualifica Y0/Y1 per lo spazio I/O. Durante boot/reset mantenere inattive le richieste verso le periferiche con gli interblocchi della CPU. La build deve mantenere il pin 55 come GPIO (SSPI disabilitata). Le linee del bus condivise con microSD o display esterni restano dedicate al bus. HDMI usa la presa a bordo.

| Ciclo valido | DIR U3 | /OE U3 | Direzione |
| --- | ---: | ---: | --- |
| Scrittura selezionata | 0 | 0 | CPU → FPGA |
| Lettura selezionata, dato pronto | 1 | 0 | FPGA → CPU |
| Riposo, reset, RAM o indirizzo non implementato | irrilevante | 1 | Bus scollegato |

La FPGA cambia DIR con /OE alto. In lettura deve presentare il dato entro il tempo di acquisizione della CPU e rilasciare il bus a fine ciclo. In scrittura acquisisce il byte una sola volta. Il timing va collaudato con la CPU reale.

## Ingresso BOOT/RUN e schermata di avvio

Collegare **BOOT_RUN** con la polarità richiesta dalla Tang: **1 = BOOT,
0 = RUN**. Non è A12 del bus indirizzi CPU. La selezione dei banchi delle
EEPROM della CU resta quella prevista dal microcodice: A12=0 per BOOT e
A12=1 per RUN. Se il segnale viene prelevato da quella linea, usare il suo
complementare per la Tang.

Il GPIO 86 (J6-2) appartiene alla banca a **1,8 V**. Collegamento:

```text
BOOT_RUN CPU (5 V) → U4 B2 (pin 20)
U4 A2 (pin 4, 3,3 V) ── 3,3 kΩ ──┬── GPIO 86, J6-2
                                  │
                                3,9 kΩ
                                  │
                                 GND
```

Usare resistenze all'1%: il livello alto sul GPIO è circa 1,79 V.
Il partitore adatta questo segnale lento e non alimenta la FPGA.
Non collegare 5 V o 3,3 V direttamente al GPIO 86. Non collegare un display
LCD al connettore che condivide questa linea. U4 mantiene DIR a GND,
VCCA a 3,3 V e VCCB a 5 V come già previsto per A3.

Durante BOOT il video mostra **Enzo Tasca**, **8 BIT COMPUTER** e **BOOTING...**
in un pannello a colori con indicatore animato, senza scadenza. Le richieste CPU sono isolate: nessuna scrittura modifica
VRAM o puntatore e nessuna lettura consuma eventi della tastiera. READY è basso.
In RUN la schermata scompare e viene mostrata la VRAM; READY sale quando
l'inizializzazione VRAM è terminata e il motore clear/scroll è libero. Il passaggio di modalità conserva VRAM,
puntatore ed eventuale evento tastiera; un reset FPGA reinizializza lo stato.
La ricezione PS/2 resta attiva anche in BOOT.
Se BOOT_RUN non è collegato, la resistenza verso GND seleziona RUN.

## Reset della CPU condiviso con la FPGA

**/CPU_RESET = 0 durante RESET, 1 durante il funzionamento normale.**
Il nuovo ingresso è **GPIO 85 / IOT8B / J6-3**, subito dopo BOOT_RUN (GPIO 86 / J6-2),
sullo stesso lato di 5V, GND e 3V3. Il GPIO appartiene alla banca a **1,8 V**,
come documentato nello [schema ufficiale Sipeed](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf).

Usare la linea logica di reset già condizionata della CPU, non il nodo RC del pulsante.

```text
/RESET CPU (0/5 V) → U4 B3 (pin 19)
U4 A3 (pin 5, 0/3,3 V) ── 3,3 kΩ ──┬── GPIO 85, J6-3
                                    │
                                  3,9 kΩ
                                    │
                                   GND
```

Resistenze all'1%, massa comune. Livello alto nominale sul GPIO: circa 1,79 V.
**Non collegare 5 V o 3,3 V direttamente al GPIO 85.** Rimuovere il precedente
filo B3 → GND su U4: quel canale è ora dedicato al reset. DIR di U4 rimane a GND;
le alimentazioni restano VCCA=3,3 V e VCCB=5 V.
Il reset CPU deve essere pilotato alto a riposo, anche quando il clock CPU è fermo.
Se U4 è disabilitato o non alimentato, il partitore tiene il reset FPGA attivo.
Il solo GPIO lasciato scollegato, senza partitore, ha un pull-up interno a 1,8 V.

Il reset isola subito il bus dati, anche senza clock pixel. Al rilascio la FPGA
attende quattro cicli pixel prima di ripartire e inizializza i 16384 caratteri
VRAM a spazio e gli attributi a 0F (testo bianco su nero), in circa **0,65 ms**
con il video 640×480. Azzera puntatore/cursore e gli eventi, modificatori ed errori
PS/2, ripristina colori e controlli video e cancella le transazioni in corso.
READY rimane basso durante l'inizializzazione; la CPU deve attendere almeno
**1 ms** prima della prima scrittura video dopo il rilascio del reset.
Il clock HDMI continua, ma durante il reset il flusso video viene reinizializzato:
il monitor può richiedere tempo per riagganciare il segnale.

La schermata BOOTING continua a dipendere da BOOT_RUN: **il reset non forza BOOT**.
Con BOOT_RUN=0, dopo il reset si vede lo schermo vuoto pronto per la CPU;
con BOOT_RUN=1 ricompare BOOTING. Il pulsante di reset sulla Tang resta funzionante.
Questo ingresso resetta le periferiche FPGA; la protezione delle scritture RAM CPU
durante reset richiede ancora il relativo interblocco hardware sulla CPU.

## Tastiera PS/2

Usare due canali di un adattatore per linee open-collector, ad esempio due canali BSS138 con pull-up su entrambi i lati. Collegare HV a 5 V, LV a 3V3 e GND alla massa comune.

| Mini-DIN PS/2 | Collegamento |
| ---: | --- |
| 1 DATA | Adattatore HV DATA → LV DATA → J5-8 (FPGA 28) |
| 3 GND | Massa comune |
| 4 VCC | 5 V CPU |
| 5 CLK | Adattatore HV CLK → LV CLK → J5-7 (FPGA 27) |
| 2, 6 | Lasciare scollegati |

Identificare i contatti usando la numerazione del proprio connettore. Il lato saldature è speculare rispetto alla vista frontale. In questa revisione i GPIO PS/2 sono ingressi. [Riferimento Mini-DIN PS/2, AMD/Xilinx UG037](https://docs.amd.com/api/khub/documents/l3jv54IAj53EOqnQaauo~w/content).

## Collaudo

Con U3 disabilitato, verificare Y0 su 0x2000 e Y1 su 0x2001, sul lato a 3,3 V. Verificare che entrambe siano basse per un accesso RAM e durante boot/reset. Dopo aver caricato il nuovo bitstream, verificare la scrittura di un carattere in VIDEO_DATA (0x2000), poi la lettura di KEY_DATA (0x2001), che restituisce zero a buffer vuoto e un evento dopo una pressione.

[Mappa dei registri](io-bus.md#selezione-delle-periferiche-e-indirizzi) · [Specifica tastiera](io-ps2-timer.md).

[Registri video a colori, cursore e comandi](video-registers.md). Il cablaggio resta valido per questa estensione.
