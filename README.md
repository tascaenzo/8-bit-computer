# CPU 8-bit

Repository di supporto alla serie didattica YouTube in cui viene progettata e costruita una CPU a 8 bit partendo dai blocchi logici fondamentali.

In questa fase il repository contiene documentazione, una prima ISA, esempi assembly, un assembler in C e strumenti di supporto per programmare le memorie della CPU.

## Contenuto

```text
.
├── docs/
├── examples/
│   └── assembly/
├── hardware/
│   ├── alu-pcb/
│   ├── data-bus-pcb/
│   ├── address-bus-pcb/
│   └── tang-nano-9k-video/
├── tools/
│   ├── assembler/
│   ├── cu-bytecode/
│   └── eeprom-programmer/
├── wiki/
│   ├── blog/
│   └── videos/
└── README.md
```

### `docs`

Contiene la documentazione tecnica della CPU:

- [`docs/isa.md`](docs/isa.md) definisce architettura, istruzioni e opcode;
- [`docs/assembly-language.md`](docs/assembly-language.md) definisce la sintassi dei programmi assembly.
- [`docs/control-unit-microcode.md`](docs/control-unit-microcode.md) definisce segnali e microsequenze della Control Unit.
- [`docs/video-hdmi.md`](docs/video-hdmi.md) definisce VRAM e uscita HDMI della Tang Nano 9K.
- [`docs/io-ps2-timer.md`](docs/io-ps2-timer.md) definisce registri I/O, tastiera PS/2 e timer della Tang Nano 9K.

### `examples/assembly`

Contiene programmi assembly didattici usati per provare l'assembler e spiegare le istruzioni della CPU.

### Schede PCB in `hardware`

Progetti KiCad e pacchetti Gerber per l'[ALU con LED e comandi locali](hardware/alu-pcb/rev-b/README.md),
il [bus dati a otto porte con monitor LED](hardware/data-bus-pcb/README.md)
e il [bus indirizzi a 16 bit](hardware/address-bus-pcb/README.md).
I due bus usano il layout slim del 7 ottobre 2026, entrambi **REV A**:
**235 × 40 mm** per i dati e **300 × 46 mm** per gli indirizzi,
con la firma «Progettato da Enzo Tasca» sul fronte, LED ravvicinati a gruppi
di quattro bit e uno switch SW1 per spegnere gli indicatori del bus.
ALU e bus dati hanno connettori dati compatibili; il bus indirizzi usa porte 2×10 dedicate. I controlli software sono
completati; i prototipi fisici devono ancora essere montati e collaudati.

### `hardware/tang-nano-9k-video`

Contiene il progetto Gowin per la Tang Nano 9K. Il primo milestone verifica
l'uscita HDMI prima di introdurre VRAM e interfaccia al bus TTL.

### `tools/assembler`

Contiene `cpu8asm`, l'assembler in C che traduce i programmi assembly in byte macchina.

### `tools/eeprom-programmer`

Contiene sketch e documentazione per programmare EEPROM parallele usate dalla CPU, come la AT28C64.

La guida passo passo per il programmatore AT28C64 con Arduino Mega e in:

```text
docs/at28c64-arduino-mega-programmer.md
```

### `tools/cu-bytecode`

Contiene `cpu8microcode`, il generatore C delle tre Control ROM e della ROM di
dispatch. La guida di build e la mappa dei bit sono in
[`tools/cu-bytecode/README.md`](tools/cu-bytecode/README.md).

### `tools/simulator-web`

Contiene il simulatore web step-by-step della ISA: permette di assemblare ed
eseguire programmi nel browser, osservando registri, flag, RAM e la memoria
video mappata nella FPGA. La guida di avvio è in
[`tools/simulator-web/README.md`](tools/simulator-web/README.md).

### `wiki/videos`

Contiene le trascrizioni autogenerate dei video della serie.

Le trascrizioni sono materiale grezzo: possono contenere errori di riconoscimento, frasi incomplete o termini tecnici interpretati male. Servono come base di lavoro per ricostruire gli argomenti trattati nei video.

### `wiki/blog`

Contiene articoli tecnici in italiano ricavati dalle trascrizioni e dagli argomenti gia affrontati.

Gli articoli seguono il percorso reale della serie e non anticipano parti non ancora consolidate.

## Argomenti documentati

Finora la documentazione copre:

- operazioni logiche della ALU: `AND`, `OR`, `XOR`, `NOR`, `NAND`, `XNOR`, `NOT`;
- pull-up, pull-down e comportamento dei livelli logici;
- buffer tri-state e collegamento al bus dati;
- somma binaria con half adder e full adder;
- complemento a due e numeri con segno;
- somma e sottrazione con il 74283;
- flag `Carry`, `Negative`, `Zero` e `Overflow`;
- operazioni di confronto tramite flag;
- codice operazione della ALU;
- segnale di clock;
- flip-flop `SR` e `D`.

## Convenzioni

- La documentazione principale e in italiano.
- I nomi tecnici possono restare in inglese quando corrispondono meglio a datasheet, segnali o architettura.
- Le trascrizioni autogenerate non sono considerate documentazione definitiva: vanno ripulite e corrette quando vengono trasformate in articoli.
