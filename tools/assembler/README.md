# CPU8 Assembler

Assembler in C per la CPU didattica a 8 bit.

Questa prima versione e solo scaffolding: definisce struttura, moduli e punto di ingresso CLI. La logica completa di parsing e generazione binaria verra aggiunta nei prossimi passi.

## Obiettivo

Il tool dovra trasformare programmi assembly in file caricabili nella ROM/EEPROM della CPU.

Esempio futuro:

```asm
LDI R0, 0x0A
STA R0, 0x000E
OUT R0
HLT
```

Output previsti:

- `.bin`: byte macchina raw;
- `.hex`: dump leggibile per debug;
- `.h`: array C/C++ da includere in uno sketch Arduino.

## Build

```sh
make -C tools/assembler
```

## Studio del codice

Per una spiegazione didattica dei file, dei moduli e del percorso consigliato di studio, leggere:

```text
tools/assembler/STUDY_GUIDE.md
```

## Uso previsto

```sh
tools/assembler/build/cpu8asm examples/assembly/demo.asm -o build/demo
```

## Struttura

```text
tools/assembler/
├── include/
│   ├── assembler.h
│   ├── errors.h
│   ├── isa.h
│   ├── output.h
│   └── parser.h
├── src/
│   ├── assembler.c
│   ├── errors.c
│   ├── isa.c
│   ├── main.c
│   ├── output.c
│   └── parser.c
├── tests/
│   └── smoke.asm
├── Makefile
├── STUDY_GUIDE.md
└── README.md
```
