# Collegamento CPU HC → Tang Nano 9K con SN74LVC8T245

14 ottobre 2026. Scelta finale: quattro SN74LVC8T245PWR su adattatori
TSSOP-24 → foro passante. Progetto FPGA aggiornato, simulazione e bitstream
verificati; cablaggio reale e HDMI ancora da collaudare.

## Alimentazioni e pin del chip

La sigla PWR indica TSSOP-24 (PW), passo 0,65 mm. Usare adattatori compatibili,
non scegliere il footprint in base al solo termine SOP dell'inserzione.
Numerazione del chip **vista dall'alto**, verificata sul
[datasheet TI](https://www.ti.com/lit/ds/symlink/sn74lvc8t245.pdf):

| Funzione | Pin TSSOP-24 | Collegamento |
| --- | --- | --- |
| VCCA | 1 | +3,3 V Tang, lato A |
| DIR | 2 | 0: B → A; 1: A → B, comando a 3,3 V |
| A1–A8 | 3–10 | Lato FPGA a 3,3 V |
| GND | 11, 12, 13 | Tutti alla massa comune |
| B1–B8 | 21, 20, 19, 18, 17, 16, 15, 14 | Lato CPU a 5 V |
| /OE | 22 | Alto disabilita entrambe le porte; comando a 3,3 V |
| VCCB | 23, 24 | Entrambi a +5 V CPU, lato B |

Su ogni chip: un condensatore 100 nF da VCCA a GND e uno da VCCB a GND,
vicini al chip. DIR e /OE fanno riferimento a VCCA. Pull-up /OE da 10 kΩ
verso 3,3 V: non verso 5 V. Gli adattatori passivi portano i pin al passo
2,54 mm, ma non effettuano la conversione: questa e' svolta dal chip saldato.

## I quattro traduttori

| Chip | Lato B CPU | Lato A FPGA | DIR |
| --- | --- | --- | --- |
| U1 | Indirizzi A0–A7 | cpu_addr[0]–cpu_addr[7] | GND, fisso B → A |
| U2 | Indirizzi A8–A15 | cpu_addr[8]–cpu_addr[15] | GND, fisso B → A |
| U3 | Dati D0–D7 | cpu_data[0]–cpu_data[7] | FPGA pin 63/J6-1 |
| U4 | RAM_OE, RAM_WE, permesso CPU | cpu_rd_n, cpu_wr_n, cpu_enable | GND, fisso B → A |

Per U1/U2/U3, il bit piu' basso del gruppo usa il canale 1, il successivo
il canale 2, fino al canale 8. Il nome A del traduttore identifica il lato
FPGA, non il bus indirizzi CPU.

Su U4 usare B1 → A1 per RAM_OE, B2 → A2 per RAM_WE, B3 → A3 per CPU_ENABLE.
I canali inutilizzati A4–A8/B4–B8 possono essere fissati a GND mantenendo
DIR=0: entrambi i lati del canale hanno lo stesso valore zero. Non lasciare
flottanti gli ingressi inutilizzati. Sul lato FPGA di CPU_ENABLE mantenere
un pull-down da 10 kΩ, per bloccare l'interfaccia quando U4 e' disabilitato.

I tre chip U1/U2/U4 devono tradurre sempre le richieste generali, anche
quando l'accesso e' rivolto alla RAM: non abilitarli con il select video.
Per il primo prototipo, mettere un pull-up /OE da 10 kΩ a 3,3 V su ciascuno
e un jumper comune fra i loro /OE e GND. Jumper aperto = disabilitati;
chiuderlo con alimentazioni stabili e CPU ferma, prima di avviare la CPU.
Un controllo automatico futuro deve usare un permesso di alimentazioni
valide. Il /OE di U3 resta invece indipendente e comandato dalla FPGA.

## Bus dati, canale per canale

```text
          SN74LVC8T245 U3
FPGA Dn ------- An  <----->  Bn ------- CPU bus Dn
                 A: 3,3 V     B: 5 V
FPGA pin 63 ---------------- DIR (pin 2)
FPGA pin 32 ---------------- /OE (pin 22)
```

| Bit CPU | Pin B di U3 | Pin A di U3 | Pin FPGA | Header schema Tang |
| --- | ---: | ---: | ---: | --- |
| D0 | 21 | 3 | 38 | J5-1 |
| D1 | 20 | 4 | 37 | J5-2 |
| D2 | 19 | 5 | 36 | J5-3 |
| D3 | 18 | 6 | 39 | J5-4 |
| D4 | 17 | 7 | 56 | J5-21 |
| D5 | 16 | 8 | 57 | J5-22 |
| D6 | 15 | 9 | 48 | J6-19 |
| D7 | 14 | 10 | 49 | J6-20 |

La FPGA abilita B → A soltanto per le scritture video valide, aspetta la
propagazione e acquisisce il byte. Per la lettura prepara DIR=1 con /OE=1,
legge la VRAM, pilota i propri GPIO dati, aspetta un clock e poi pone /OE=0.
La CPU non deve pilotare D durante una lettura. I cicli RAM, riservati,
inattivi e invalidi mantengono U3 disabilitato. Lo strobe e il permesso bus
fisici disabilitano immediatamente /OE al termine del ciclo, senza attendere
la sincronizzazione; rispettare comunque 1 µs fra transazioni.

Pull-down da 10 kΩ fra DIR di U3 e GND, per definirlo prima della configurazione;
pull-up da 10 kΩ fra /OE di U3 e VCCA, per tenerlo disabilitato. Quando il bus
resta flottante su entrambi i lati, usare bias deboli verso la rispettiva
alimentazione, ad esempio 47 kΩ sui nodi A a 3,3 V e B a 5 V, valutando
quelli gia' presenti sul bus CPU. Questo evita ingressi CMOS indefiniti.
Rimuovere partitori, 4050 e HCT244 dai percorsi sostituiti da U3.

## Pinout e indicazione pronto della Tang

La [tabella completa](../hardware/tang-nano-9k-video/README.md#pinout-cpu)
riporta indirizzi, dati e controlli. Le posizioni J5/J6 derivano dallo
[schema ufficiale Sipeed](https://dl.sipeed.com/fileList/TANG/Nano%209K/2_Schematic/Tang_Nano_9k_3672_Schematic.pdf).
Verificare il proprio PCB: la revisione fisica non e' ancora nota.
I file .cst sono gia' aggiornati allo stesso pinout.

Rispetto al bitstream precedente, pin 32/J6-22 e' ora /OE_DATA e
pin 63/J6-1 e' DIR_DATA, **non VIDEO_READY**. Memoria pronta e' indicata
con **LED1 acceso** a bordo (GPIO 10, banca 1,8 V, uscita video_ready_n).
Non portare GPIO 10 al bus CPU o a un traduttore con VCCA=3,3 V.

Clock 27 MHz pin 52, reset pulsante pin 4 (1,8 V) e HDMI pin 68–75 sono
cablaggi onboard; non richiedono fili CPU. Il permesso CPU_ENABLE sul pin 31
si usa per bloccare il bus in reset/isolamento CPU. Non inserire microSD,
LCD RGB o SPI LCD: condividono pin gia' usati dal bus video.

## Collegamenti CU e RAM

`A[15:0]` viene dal bus condiviso dopo selezione PC/MAR/IDX. `/WR` viene
dalla richiesta generale `RAM_WE` e `/RD` da `RAM_OE`, **prima** della
qualificazione del chip RAM. Usare i segnali stabili della CU, non
assumere che le uscite EEPROM grezze siano prive di glitch.
La [mappa CU](control-unit-eeprom-output-map.md) identifica l'origine logica:
`RAM_WE` dalla ROM 0 D5 e `RAM_OE` dalla ROM 2 D3.

### Prelievo dalla CU e selezione autonoma della FPGA

La selezione RAM esterna non viene portata alla FPGA. Collegare le richieste
generali di memoria, prelevate dalla CU prima della logica di selezione RAM:

| Richiesta CU in cu-bytecode | Polarita' | Ingresso FPGA |
| --- | --- | --- |
| `RAM_OE` (ROM 2, D3) | Attiva bassa | `cpu_rd_n` |
| `RAM_WE` (ROM 0, D5) | Attiva bassa | `cpu_wr_n` |
| Bus indirizzi dopo selezione PC/MAR/IDX | 16 bit | `cpu_addr[15:0]` |

I nomi RAM_OE/RAM_WE sono quelli storici della CU: in questo collegamento
sono richieste generali di lettura/scrittura per lo spazio memory-mapped.
La FPGA decodifica internamente `A15:A14=01` e accetta soltanto gli accessi
a `0x4000–0x7FFF`. La RAM conserva il decoder cablato `A15:A14=00`.
Non occorrono nuovi opcode, segnali CU dedicati al video o una selezione
video esterna. `LDAI` e `STAI` usano le stesse richieste con IDX sul bus.

```text
CU RAM_OE --------+--> logica cablata RAM --> abilitazione lettura RAM
                 +--> adattamento livelli --> FPGA cpu_rd_n

CU RAM_WE --------+--> logica cablata RAM --> abilitazione scrittura RAM
                 +--> adattamento livelli --> FPGA cpu_wr_n

Bus A[15:0] -----+--> decoder cablato RAM
                +--> adattamento livelli --> decoder interno FPGA
```

`cpu_enable` e' un permesso globale di bus durante reset/isolamento, non
il chip select della RAM e non un chip select video. **Non collegarlo
all'EN della RAM gia' qualificato per indirizzo**, altrimenti il permesso
verrebbe tolto proprio negli indirizzi video. Le uscite richieste sono
quelle stabilizzate della CU, prima della selezione RAM, non necessariamente
i pin grezzi delle EEPROM. Tutti i percorsi CU → Tang richiedono adattamento
da 5 V alla banca GPIO a 3,3 V.

Sul lato CPU, decodificare localmente:

```text
RAM_SEL = BUS_ENABLE AND NOT A15 AND NOT A14
/OE_RAM = NOT (RAM_SEL AND NOT /RD AND /WR)
/WE_RAM = NOT (RAM_SEL AND /RD AND NOT /WR)
```

La RAM non deve rispondere a `0x4000–0x7FFF` nemmeno se il chip fisico
usa soltanto le linee indirizzo basse. Applicare la selezione a CS/OE/WE
secondo il chip effettivo. Il decoder non e' un'uscita sincronizzata FPGA:
non introduce la latenza del ricevitore video nel controllo della RAM.
L'EPROM conserva il controllo separato `EPROM_OE` durante BOOT → RAM.

## Prima prova

Usare il [bitstream e contratto temporale aggiornati](../hardware/tang-nano-9k-video/README.md).
Prima configurare la FPGA in SRAM, poi abilitare U1/U2/U4 a CPU ferma.
Avviare il [programma IDX](../examples/assembly/video_idx.asm) quando LED1
indica memoria pronta. L'aggiornamento controlla DIR e /OE di U3: non
occorrono nuovi segnali video o opcode nella Control Unit.

Lo schema completo della board CPU non e' nel repository: chip RAM e
numerazione del connettore CPU restano da identificare. La selezione RAM
cablata deve continuare a escludere 0x4000–0x7FFF.
