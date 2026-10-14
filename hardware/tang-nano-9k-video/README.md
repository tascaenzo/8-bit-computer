# Scheda video CPU 8-bit — Tang Nano 9K

Progetto RTL completo per il sottosistema video. Bitstream generato con
Yosys/nextpnr/Apicula; non ancora provato su una Tang collegata alla CPU.

## Funzioni

- HDMI in modalita' video DVI, senza audio: 640 × 480, 60 Hz, pixel clock 25,2 MHz.
- Testo bianco su nero, 80 × 60 caratteri da 8 × 8 pixel.
- VRAM 16 KiB a `0x4000–0x7FFF`, 128 × 128 celle, un byte per cella.
- `indirizzo = 0x4000 + riga * 128 + colonna`; coordinate a partire da zero.
- ASCII stampabile `0x20–0x7E`; altri codici visualizzati come celle vuote,
  ma conservati integralmente e rileggibili dalla CPU.
- Letture e scritture tramite `LDA`/`STA` e `LDAI`/`STAI`, senza auto-incremento IDX.
- Inizializzazione a spazio dopo reset; video nero fino al completamento.
- Una sola scrittura per strobe, nessuna risposta fuori dal range video.
- CPU ferma: HDMI continua a visualizzare la VRAM.

Tastiera e timer `0xFF00–0xFF0F` non sono inclusi in questa build video e
non producono una risposta sul bus. La loro specifica rimane separata.
La RAM di sistema deve essere esclusa dal range video da un decoder TTL locale.

## Build e test

Dalla radice del repository:

```sh
make -C hardware/tang-nano-9k-video test
make -C hardware/tang-nano-9k-video bitstream
```

Strumenti richiesti: `iverilog`, `vvp`, `yosys`, `nextpnr-himbaechel` con backend
Gowin e `gowin_pack` (Apicula), presenti in OSS CAD Suite. Il submodule vendor
deve essere inizializzato, se si parte da un clone nuovo:

```sh
git submodule update --init --recursive
```

File generato: **`build/cpu8_video.fs`**. Log: `build/synth.log`, `build/pnr.log`;
report di timing: `build/timing.json`. Device: `GW1NR-LV9QN88PC6/I5`, family
`GW1N-9C`. Non usare i vecchi `video_text.fs` presenti in build: appartengono
al precedente smoke test e non contengono questa interfaccia CPU.

`video.gprj` e' incluso per Gowin IDE, top module `top_video`, con
`constraints/video-gowin.cst`. Il percorso di build effettivamente verificato
qui e' OSS CAD Suite, che usa `constraints/video.cst`. Le due varianti
hanno lo stesso pinout e differiscono nella dichiarazione delle coppie HDMI.
Il pin 55 e' usato come GPIO: disabilitare SSPI anche nelle opzioni Gowin IDE.
La build Makefile passa i flag `sspi_as_gpio` a nextpnr e al packer.

## Pinout CPU

Assegnazione derivata dallo
[schema ufficiale Sipeed](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf).
Tutti i pin CPU elencati appartengono a banche a 3,3 V. I numeri QN88
identificano il pin del chip FPGA; J5/J6 identificano il connettore nello schema,
non una numerazione da indovinare contando dal lato USB. Verificare le
serigrafie della propria revisione, che non e' ancora nota.

| Segnale | Pin FPGA QN88 | Connettore schema Sipeed |
| --- | ---: | --- |
| `A0` | 25 | J5-5 |
| `A1` | 26 | J5-6 |
| `A2` | 27 | J5-7 |
| `A3` | 28 | J5-8 |
| `A4` | 29 | J5-9 |
| `A5` | 30 | J5-10 |
| `A6` | 33 | J5-11 |
| `A7` | 34 | J5-12 |
| `A8` | 40 | J5-13 |
| `A9` | 35 | J5-14 |
| `A10` | 41 | J5-15 |
| `A11` | 42 | J5-16 |
| `A12` | 51 | J5-17 |
| `A13` | 53 | J5-18 |
| `A14` | 54 | J5-19 |
| `A15` | 55 | J5-20 |
| `D0` | 38 | J5-1 |
| `D1` | 37 | J5-2 |
| `D2` | 36 | J5-3 |
| `D3` | 39 | J5-4 |
| `D4` | 56 | J5-21 |
| `D5` | 57 | J5-22 |
| `D6` | 48 | J6-19 |
| `D7` | 49 | J6-20 |
| `/RD` | 77 | J6-10 |
| `/WR` | 76 | J6-11 |
| `CPU_ENABLE` | 31 | J6-21 |
| `/OE_DATA` | 32 | J6-22 |
| `DIR_DATA` | 63 | J6-1 |
| `video_ready_n` | 10 | LED1 onboard, banca 1,8 V |

Il clock locale e' il pin FPGA 52, gia' collegato all'oscillatore a 27 MHz.
`resetn` usa il pulsante sul pin 4, nella banca a **1,8 V**, ed e' configurato
come `LVCMOS18`: non collegarlo al reset TTL a 5 V o 3,3 V. Per sospendere
l'interfaccia CPU usare `CPU_ENABLE=0`; il reset del pulsante cancella la VRAM.
Il rilascio reset e' sincronizzato al pixel clock e dipende dal lock PLL.
HDMI usa i pin gia' cablati a bordo 68–75. Non sono GPIO disponibili al bus CPU.
J6-23 e' GND; J6-24 e' +3V3 nello schema citato. Usare massa comune.

Non collegare una scheda microSD o un display RGB/SPI contemporaneamente:
questi segnali condividono GPIO del bus. Le resistenze onboard delle linee
microSD restano presenti e devono essere considerate nell'interfaccia.
Nessun pin JTAG, MODE0/1 o flash SPI viene usato come linea dati CPU.

## Interfaccia elettrica scelta: SN74LVC8T245PWR

La build corrente usa **quattro SN74LVC8T245PWR** su adattatori
**TSSOP-24, passo 0,65 mm → foro passante passo 2,54 mm**. Il codice PWR
identifica il package PW, non SOP generico. La numerazione dell'adattatore
va verificata rispetto al chip, vista dall'alto.

- VCCA=3,3 V e porte A verso FPGA; VCCB=5 V e porte B verso CPU.
- Due chip traducono A0–A15 del bus indirizzi CPU; DIR=0, B → A.
- Un chip traduce RD, WR e CPU_ENABLE; DIR=0, B → A.
- Il quarto traduce D0–D7 con DIR e /OE comandati dalla FPGA.
- Rimuovere i partitori e l'HCT244 del precedente progetto dalle linee sostituite.

| Accesso selezionato | DIR_DATA | /OE_DATA | GPIO dati FPGA |
| --- | ---: | ---: | --- |
| Scrittura CPU → VRAM | 0 | 0 dopo preparazione | Ingresso |
| Lettura VRAM → CPU | 1 | 0 dopo dato pronto | Uscita |
| Inattivo, indirizzo RAM/riservato, reset o ciclo invalido | Stabile / irrilevante | 1 | Alta impedenza |

Il pin FPGA 32/J6-22 controlla /OE del traduttore dati; il pin
63/J6-1 controlla DIR. DIR cambia mentre /OE e' alto. In ricezione il
traduttore viene abilitato prima di campionare D; in trasmissione la FPGA
prepara i dati per un clock prima di abilitare le uscite verso CPU.
Il rilascio di /OE e' inoltre qualificato dagli strobe fisici e dall'enable.

**Il pin 63 non e' piu' VIDEO_READY.** Per aggiungere DIR senza occupare un
GPIO a 1,8 V del bus, VIDEO_READY e' ora mostrato dal **LED1 onboard**,
GPIO 10 a 1,8 V, attivo basso: LED acceso = memoria pronta. Non collegare
questa linea al bus CPU o al traduttore configurato a 3,3 V.
Il reset sul pin 4 resta nel dominio a 1,8 V.

Mettere un pull-up esterno da 10 kΩ verso **VCCA=3,3 V** su /OE di ciascun
chip, e un pull-down da 10 kΩ su DIR del chip dati. Prima della configurazione
questi resistori tengono disabilitato il traduttore dati e definita la direzione.
I tre chip a direzione fissa devono essere abilitati con /OE basso dopo
che le alimentazioni sono stabili: per il primo prototipo usare un jumper
comune verso GND, lasciando i rispettivi pull-up verso 3,3 V.
Tenere la CPU ferma mentre si abilita quel jumper, poi avviarla dopo LED1.
Per una futura abilitazione automatica usare un permesso di alimentazioni
valide: non il /OE_DATA, che dipende dall'indirizzo della transazione.

CPU_ENABLE e' un permesso globale, non il select della RAM. Il suo ingresso
FPGA deve essere definito basso mentre il traduttore controlli e' disabilitato,
per esempio con pull-down da 10 kΩ sul lato FPGA. Per tenere definiti i dati
quando entrambi i lati sono in alta impedenza, usare bias deboli (ad esempio
47 kΩ verso la rispettiva alimentazione su ciascun lato), tenendo conto
di quelli eventualmente gia' presenti sulla board CPU. Il datasheet richiede
livelli definiti agli ingressi anche quando le uscite sono disabilitate.

Ogni chip richiede tutti i GND collegati e condensatori 100 nF vicini a
VCCA e VCCB. Lo [schema di cablaggio](../../docs/video-cablaggio.md) riporta
il pinout completo TSSOP-24 e i collegamenti canale per canale.

## Contratto temporale del bus

I valori seguenti si riferiscono ai segnali **gia' adattati ai pin FPGA**:

| Requisito | Minimo / limite |
| --- | --- |
| Durata `/WR=0` o `/RD=0` | 1 µs |
| Pausa fra transazioni, entrambi gli strobe alti | 1 µs |
| Indirizzo valido, e dato valido in scrittura | Entro 100 ns dall'asserzione dello strobe |
| Stabilita' indirizzo/dato scritto | Fino al rilascio dello strobe e per altri 100 ns |
| Campionamento del dato letto dalla CPU | Almeno 1 µs dopo `/RD=0`, includendo ritardo del traduttore esterno |
| Inizio accessi dopo reset FPGA | Dopo LED1 acceso (memoria pronta), con bus prima inattivo per 1 µs |

Indirizzo e dati attraversano due registri di acquisizione; dopo la
sincronizzazione dello strobe il ricevitore aspetta otto cicli, inclusi
preparazione DIR, abilitazione del traduttore e acquisizione dei dati,
prima di catturare la transazione. La coerenza della parola dipende dalla
finestra di stabilita' sopra: la sincronizzazione indipendente dei bit,
da sola, non sarebbe sufficiente. Non si usa `CLK_CPU` per campionare:
il ricevitore lavora nel dominio pixel clock. Non e' richiesta una linea ACK,
ma strobi piu' brevi di questo contratto non sono supportati.

Il rilascio del pin dati e dell'OE esterno e' qualificato direttamente da
`/RD`, `/WR`, indirizzo, enable, reset e PLL lock: non aspetta la catena
sincronizzata. Il turnaround di 1 µs consente anche la disabilitazione fisica
dello SN74LVC8T245 prima che un altro dispositivo piloti il bus. Entrambi gli
strobe bassi sono invalidi; per riprendere serve una fase inattiva.

Il reset riempie 16.384 celle a un byte per pixel clock: circa **650 µs**
dopo il rilascio del reset interno, oltre al tempo di lock PLL. Durante
il riempimento gli accessi sono ignorati e LED1 e' spento. Uno strobe
iniziato durante il riempimento non viene accettato automaticamente alla fine:
serve prima tornare al bus inattivo.

## Esempio CPU

[video_idx.asm](../../examples/assembly/video_idx.asm) scrive `HELLO WORLD FROM 8 BIT COMPUTER` nella
prima riga e `A` in riga 2, colonna 5; poi rilegge `A` in R1 e ferma la CPU.
Assemblaggio dalla radice del repository:

```sh
make -C tools/assembler
tools/assembler/build/cpu8asm examples/assembly/video_idx.asm -o /tmp/cpu8-video-idx
```

IDX non si incrementa automaticamente nella ISA attuale. L'esempio ricarica
l'indirizzo con `LDX`; non richiede nuove istruzioni o modifiche alla CU.
La scrittura alla colonna 79 non avanza alla riga successiva: la nuova riga
inizia 128 byte dopo la precedente.

## Caricamento per il primo test

Con cablaggio verificato e CPU inizialmente scollegata, caricare in SRAM:

```sh
openFPGALoader -b tangnano9k build/cpu8_video.fs
```

Questo comando non e' stato eseguito in questa sessione. La programmazione
SRAM e' temporanea e si perde togliendo alimentazione. Collegare il monitor
alla porta HDMI onboard: dopo il reset deve agganciare 640 × 480 a 60 Hz e
mostrare nero. Poi collegare l'interfaccia di livello, abilitarla a CPU ferma e mantenere bus inattivo,
attendere LED1 acceso e avviare il programma demo sulla CPU.
Non programmare permanentemente la flash prima del collaudo SRAM.

## Validazione e limiti

Verifica aggiornata il 14 ottobre 2026 per SN74LVC8T245:

- Decoder esaustivo: 524.288 combinazioni di indirizzo, enable e strobe.
- Core: reset/clear, lettura e scrittura, una scrittura per strobe lungo,
  estremi di range, alias fuori range, cicli invalidi e rilascio immediato OE.
  Modello digitale LVC8T245 con ritardo di 12 ns, strobi minimi da 1 µs,
  cambio DIR con /OE alto e setup dati prima della trasmissione verificati.
- Renderer: un fotogramma completo 800 × 525, 307.200 pixel attivi,
  glifo A in tre posizioni, codice non supportato, passo 128 e sincronismi.
- TMDS vendor: quattro simboli di controllo e decodifica dei 256 byte possibili.
- Demo assemblata con l'assembler C ed eseguita nel simulatore CPU: testo,
  cella `0x4105` e R1=`0x41` verificati.
- Lint del core con Verilator: passato.
- Sintesi, place/route e pack: completati. Utilizzo: 467 LUT4, 303 DFF,
  17/26 blocchi BSRAM. Timing interno pixel clock: PASS a 25,2 MHz;
  limite stimato dal report post-route circa 109 MHz (non un clock d'uso).

La toolchain emette warning sulle sezioni non usate delle porte RAM durante
il mapping Yosys, e due warning nextpnr sul routing dedicato di due rami
di `addr_i[9]`. Nella build aggiornata non compare il precedente warning
sul routing di `clk_5x`. Il router completa tramite risorse globali/
generali e non riporta errori; gli avvisi sono conservati nei log.
Il report interno non verifica metastabilita', ritardi del cablaggio TTL,
traduttori reali o integrita' del segnale HDMI. Il funzionamento elettrico e la
serializzazione HDMI devono ancora essere provati sulla Tang fisica.

Le scritture durante una scansione possono cambiare un carattere nel frame
corrente: non c'e' doppio buffer. Una collisione di lettura video e scrittura
CPU puo' produrre un transitorio locale; il frame successivo legge la nuova
cella. Non usare il risultato di una lettura durante una scrittura CPU
simultanea: il protocollo lo vieta.

Il font e l'encoder TMDS derivano dal core SVO incluso nel submodule Sipeed.
`rtl/cpu8_font.v` conserva la licenza originale ISC di Clifford Wolf;
`vendor/.../svo_tmds.v` rimane invariato.
