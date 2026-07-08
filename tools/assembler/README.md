# CPU8 Assembler

Assembler in C per la CPU didattica a 8 bit.

Questa prima versione implementa una pipeline minima ma funzionante: legge assembly, risolve label e costanti, genera byte macchina e scrive gli output `.bin`, `.hex`, `.bits` e `.h`.

## Obiettivo

Il tool dovra trasformare programmi assembly in file caricabili nella ROM/EEPROM della CPU.

Esempio:

```asm
.code 0x0000
LDI R0, 0x0A
STA R0, counter
OUT R0
HLT

.data 0x0010
counter: .byte 0x00
```

Output generati:

- `.bin`: byte macchina raw;
- `.hex`: dump leggibile per debug;
- `.bits`: dump binario testuale per debug visivo;
- `.h`: array C/C++ da includere in uno sketch Arduino.

Esempio di riga `.bits`:

```text
0000: 00100000  ; 0x20
```

In caso di errore sintattico, l'assembler prova a indicare la riga:

```text
cpu8asm: line 2: invalid MOV form; use MOV RA, Rn, MOV RB, Rn or MOV Rn, RA
```

## Comandi Make

I comandi possono essere eseguiti dalla root del repository usando `-C tools/assembler`.

| Comando | Effetto |
| --- | --- |
| `make -C tools/assembler` | compila l'assembler |
| `make -C tools/assembler test` | compila ed esegue i test |
| `make -C tools/assembler clean` | elimina la cartella di build dell'assembler |

Se sei gia dentro `tools/assembler`, i comandi equivalenti sono:

```sh
make
make test
make clean
```

### Build

Compila l'eseguibile:

```sh
make -C tools/assembler
```

Output:

```text
tools/assembler/build/cpu8asm
```

### Test

Esegue la suite di test:

```sh
make -C tools/assembler test
```

Il test:

- assembla `tests/smoke.asm`;
- assembla `tests/labels.asm`;
- confronta gli `.hex` e `.bits` generati con i file in `tests/expected`;
- verifica che `tests/invalid.asm` fallisca con un errore che include il numero di riga.

### Clean

Rimuove i file compilati:

```sh
make -C tools/assembler clean
```

## Studio del codice

Per una spiegazione didattica dei file, dei moduli e del percorso consigliato di studio, leggere:

```text
tools/assembler/STUDY_GUIDE.md
```

## Uso

Se sei nella cartella `tools/assembler`:

```sh
build/cpu8asm ../../examples/assembly/demo.asm -o build/demo
```

Questo genera:

```text
build/demo.bin
build/demo.hex
build/demo.bits
build/demo.h
```

Dalla root del repository puoi usare lo stesso eseguibile con il path completo:

```sh
tools/assembler/build/cpu8asm examples/assembly/demo.asm -o tools/assembler/build/demo
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
│   ├── expected/
│   ├── invalid.asm
│   ├── labels.asm
│   └── smoke.asm
├── Makefile
├── STUDY_GUIDE.md
└── README.md
```
