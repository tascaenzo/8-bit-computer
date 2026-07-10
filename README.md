# CPU 8-bit

Repository di supporto alla serie didattica YouTube in cui viene progettata e costruita una CPU a 8 bit partendo dai blocchi logici fondamentali.

In questa fase il repository contiene documentazione, una prima ISA, esempi assembly, un assembler in C e strumenti di supporto per programmare le memorie della CPU.

## Contenuto

```text
.
├── docs/
├── examples/
│   └── assembly/
├── tools/
│   ├── assembler/
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

### `examples/assembly`

Contiene programmi assembly didattici usati per provare l'assembler e spiegare le istruzioni della CPU.

### `tools/assembler`

Contiene `cpu8asm`, l'assembler in C che traduce i programmi assembly in byte macchina.

### `tools/eeprom-programmer`

Contiene sketch e documentazione per programmare EEPROM parallele usate dalla CPU, come la AT28C64.

La guida passo passo per il programmatore AT28C64 con Arduino Mega e in:

```text
docs/at28c64-arduino-mega-programmer.md
```

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
