# Scheda video FPGA: bus CPU, VRAM e caratteri

Stato: RTL video integrato, test passati e bitstream generato; collaudo fisico da eseguire.
Data: 14 ottobre 2026.

## 1. Comportamento richiesto

La CPU scrive un byte sul bus `D[7:0]` tramite `STA` o `STAI`.
Se l'indirizzo appartiene alla VRAM, la FPGA memorizza quel byte nella
cella indicata. Il generatore video legge la cella, usa il byte come
codice di carattere e disegna il relativo glifo sul monitor.

Non serve un registro separato per riga o colonna: entrambe sono contenute
nell'indirizzo. Scrivere una cella sostituisce il carattere precedente;
non avanza automaticamente un cursore e non interpreta newline.
Il segnale HDMI deve continuare anche senza scritture CPU: si abilita
l'accesso alla VRAM, non si accende e spegne il generatore video.

## 2. Mappa memoria e selezione

| Indirizzi inclusivi | Destinazione |
| --- | --- |
| `0x0000–0x3FFF` | RAM/ROM di sistema, 16 KiB |
| `0x4000–0x7FFF` | VRAM FPGA, 16 KiB |
| `0x8000–0xFEFF` | Riservato |
| `0xFF00–0xFF0F` | Registri FPGA di tastiera e timer |
| `0xFF10–0xFFFF` | Riservato |

```text
RAM_SEL   = BUS_ENABLE AND NOT A15 AND NOT A14
VIDEO_SEL = BUS_ENABLE AND NOT A15 AND     A14
READ      = NOT /RD AND     /WR
WRITE     =     /RD AND NOT /WR

/OE_RAM   = NOT (RAM_SEL AND READ)
/WE_RAM   = NOT (RAM_SEL AND WRITE)
VIDEO_RD  = VIDEO_SEL AND READ
VIDEO_WR  = VIDEO_SEL AND WRITE
VIDEO_D_OE = VIDEO_RD
```

`BUS_ENABLE` e' un permesso positivo di accesso: deve essere zero durante
reset e isolamento del bus. `/RD` e `/WR` sono strobe generali di memoria
provenienti dalla CU, prima della selezione del dispositivo. Nel cablaggio
attuale corrispondono alle richieste `RAM_OE` e `RAM_WE`: queste richieste
vanno decodificate, non applicate indiscriminatamente ai chip RAM.
Quando entrambi gli strobe sono bassi, il ciclo e' invalido e il decoder
disabilita tutte le operazioni.

**La selezione deve raggiungere anche la RAM fisica.** Se un chip usa solo
le linee basse e ha `/CS` sempre attivo, puo' rispondere anche agli indirizzi
video, producendo alias in scrittura e contesa in lettura. Qualificare
`/CS`, `/OE` e `/WE` secondo il cablaggio e la polarita' del chip.
La ROM conserva la sua abilitazione separata nel BOOT: durante la copia
EPROM → RAM, il decoder permette le scritture RAM, mentre l'uscita EPROM
segue `EPROM_OE`. Non usare la regola di lettura RUN per abilitare la ROM.
Il decoder usa l'indirizzo effettivo sul bus (PC, MAR oppure IDX).

I registri `0xFF00–0xFF0F` hanno un decoder separato: non attivano la VRAM.
Quando saranno integrati, l'abilitazione totale delle uscite FPGA sara'
l'OR delle sole letture selezionate video/I/O.

## 3. Mappa e semantica della VRAM

La VRAM contiene 128 × 128 celle da un byte. Le coordinate partono da zero.

```text
indirizzo CPU = 0x4000 + riga * 128 + colonna
indirizzo VRAM = A[13:0]
riga          = A[13:7]   (0–127)
colonna       = A[6:0]    (0–127)
```

| Cella | Indirizzo |
| --- | --- |
| riga 0, colonna 0 | `0x4000` |
| riga 0, colonna 79 | `0x404F` |
| riga 1, colonna 0 | `0x4080` |
| riga 2, colonna 5 | `0x4105` |
| riga 59, colonna 79 | `0x5DCF` |
| riga 127, colonna 127 | `0x7FFF` |

La finestra visibile implementata e' 80 × 60 caratteri da 8 × 8 pixel
in 640 × 480 pixel. Il passo della VRAM rimane **128 byte**, anche se
sullo schermo si vedono soltanto 80 colonne. Le celle fuori dalla finestra
sono indirizzi VRAM validi, ma non compaiono nella visualizzazione iniziale.

Esempio: una `A` nella riga 2, colonna 5.

```asm
.equ VIDEO_R2_C5, 0x4105
.code 0x0000
LDI R0, 0x41
STA R0, VIDEO_R2_C5
HLT
```

Il byte `0x41` seleziona il glifo `A`; non e' il valore di un singolo pixel.
La ROM font implementata supporta:
ASCII stampabile `0x20–0x7E`, spazio per le celle vuote e glifo vuoto
per i codici non supportati. Nessun attributo colore e' incluso nel byte.

## 4. Blocchi integrati nella FPGA

```text
CPU → traslatori di livello → acquisizione transazione → decoder → VRAM
                                                                  ↓
HDMI ← encoder video ← pixel del glifo ← ROM font ← lettura VRAM
```

La VRAM richiede una porta CPU e una porta di lettura video. Il percorso
video deve allineare le latenze di VRAM e ROM font con le coordinate pixel,
il segnale di area attiva e i sincronismi. La lettura CPU restituisce il
codice memorizzato. Una scrittura CPU deve generare **un solo impulso**
di write-enable nel dominio FPGA per ciascuno strobe, anche se `/WR`
rimane basso per molti clock FPGA.

L'interfaccia integrata e' in `cpu8_video_bus.v`: acquisisce indirizzo,
dato e strobe, aspetta la finestra di stabilita', genera una sola scrittura
per transazione e legge la VRAM tramite la porta CPU. Gli accessi fuori
range non attivano l'OE e non modificano la VRAM. La VRAM viene inizializzata
a spazio dopo reset; Il LED1 onboard indica quando e' utilizzabile.

Il decoder combinatorio resta disponibile per verificare la mappa; il
ricevitore integrato esegue la selezione sulla transazione acquisita.
Il top `top_video.v` usa otto GPIO dati bidirezionali, con DIR e OE esterni
per SN74LVC8T245. L'OE e'
qualificato anche dagli strobe fisici, indirizzo, enable, reset e lock PLL.
La CPU deve fornire strobi di almeno 1 µs e rispettare il
[contratto temporale](../hardware/tang-nano-9k-video/README.md#contratto-temporale-del-bus).
La coerenza dei bit dipende da questa finestra di stabilita', non soltanto
da registri di sincronizzazione indipendenti. Vedere le
[indicazioni CDC Intel](https://www.intel.com/content/www/us/en/docs/programmable/683353/23-4/clock-domain-crossing-constraint-guidelines).

Il [progetto completo](../hardware/tang-nano-9k-video/README.md) contiene
font, renderer, top HDMI, pinout `.cst`, progetto Gowin e Makefile.
Lo [schema di collegamento](video-cablaggio.md) descrive l'interfaccia con
quattro SN74LVC8T245PWR su adattatori TSSOP-24 per il prototipo. I GPIO CPU scelti sono a 3,3 V;
il reset onboard e' invece a 1,8 V. Non collegare segnali HC a 5 V direttamente
alla Tang. Le collisioni di lettura video/scrittura possono mostrare un
transitorio nel frame corrente; non e' previsto il doppio buffer.

## 5. Decoder e verifica

Il modulo [cpu8_video_decode.v](../hardware/tang-nano-9k-video/rtl/cpu8_video_decode.v)
realizza selezione esclusiva RAM/video, qualifica gli strobe ed estrae le
coordinate. Il test esaustivo controlla 65.536 indirizzi con tutte le otto
combinazioni di permesso e strobe, inclusi i limiti e i cicli invalidi.

Dal repository:

```sh
iverilog -g2012 -s cpu8_video_decode_tb -o /tmp/cpu8_video_decode_tb hardware/tang-nano-9k-video/rtl/cpu8_video_decode.v hardware/tang-nano-9k-video/tests/cpu8_video_decode_tb.v
vvp /tmp/cpu8_video_decode_tb
```

Per la suite completa e il bitstream:

```sh
make -C hardware/tang-nano-9k-video test
make -C hardware/tang-nano-9k-video bitstream
```

Sintesi e place/route confermano inferenza della memoria e timing interno
pixel clock; i test coprono bus, VRAM, fotogramma e TMDS. Il funzionamento
sul bus TTL reale e sul monitor deve ancora essere collaudato. Gli avvisi
della toolchain e i limiti della verifica sono nel README FPGA.
