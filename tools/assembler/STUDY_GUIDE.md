# Guida allo studio dell'assembler

Questa guida serve a chi vuole capire il progetto dell'assembler partendo da zero.

L'assembler e un programma scritto in C che dovra leggere un file assembly, riconoscere le istruzioni della CPU a 8 bit e generare i byte macchina da caricare in ROM/EEPROM.

## Idea generale

Un programma assembly e testo leggibile:

```asm
LDI R0, 0x0A
OUT R0
HLT
```

L'assembler deve trasformarlo in byte:

```text
0x20 0x0A 0x88 0x01
```

Il lavoro dell'assembler puo essere diviso in passaggi:

1. Leggere il file `.asm`.
2. Leggere una riga alla volta.
3. Rimuovere commenti e spazi inutili.
4. Separare mnemonic e operandi.
5. Cercare il mnemonic nella tabella ISA.
6. Calcolare opcode e byte aggiuntivi.
7. Scrivere gli output finali.

## Da dove iniziare

L'ordine consigliato di lettura e:

1. `src/main.c`
2. `include/assembler.h`
3. `src/assembler.c`
4. `include/parser.h` e `src/parser.c`
5. `include/isa.h` e `src/isa.c`
6. `include/output.h` e `src/output.c`
7. `include/errors.h` e `src/errors.c`

## `src/main.c`

Questo e il punto di ingresso del programma.

Contiene la funzione:

```c
int main(int argc, char **argv)
```

Il suo compito e:

- leggere gli argomenti da terminale;
- controllare che siano corretti;
- preparare le opzioni dell'assembler;
- chiamare la funzione che assembla il file;
- chiamare la funzione che scrive gli output.

Il `main` non deve conoscere i dettagli della ISA o del formato `.bin`. Deve solo coordinare gli altri moduli.

## `include/assembler.h`

Questo file definisce le strutture principali dell'assembler.

La struttura piu importante e:

```c
typedef struct {
    uint8_t bytes[CPU8_MAX_PROGRAM_BYTES];
    size_t length;
} Cpu8Program;
```

`bytes` contiene il programma compilato in byte macchina.

`length` indica quanti byte sono stati generati davvero.

## `src/assembler.c`

Questo file conterra il cuore dell'assembler.

In futuro dovra:

- aprire il file assembly;
- leggere tutte le righe;
- usare il parser per capire cosa c'e scritto;
- usare la tabella ISA per generare gli opcode;
- riempire `Cpu8Program`.

Per ora e ancora uno scaffold: apre il file, prepara il flusso e imposta `program->length = 0`.

## `include/parser.h` e `src/parser.c`

Il parser e il modulo che legge e interpreta il testo assembly.

Per ora contiene solo la lettura di una riga:

```c
Cpu8Status cpu8_read_source_line(void *file, Cpu8SourceLine *line, int *has_line);
```

In futuro dovra riconoscere righe come:

```asm
LDI R0, 0x2A
MOV RA, R0
JMP 0x0100
```

e trasformarle in una forma piu facile da usare dal resto del programma.

## `include/isa.h` e `src/isa.c`

La ISA descrive le istruzioni disponibili.

Il file `src/isa.c` contiene una tabella che collega un mnemonic a un opcode:

```c
{"NOP", 0x00, 0xFF, CPU8_FORMAT_IMP, false}
```

Il significato dei campi e:

- `mnemonic`: nome dell'istruzione scritta in assembly;
- `opcode_base`: valore base dell'opcode;
- `opcode_mask`: bit fissi dell'opcode;
- `format`: formato dell'istruzione;
- `uses_register`: indica se l'opcode contiene anche il codice di un registro.

Questa tabella andra allineata a `docs/isa.md`, che e il documento di riferimento della ISA.

## `include/output.h` e `src/output.c`

Il modulo output scrivera i file generati dall'assembler.

I formati previsti sono:

- `.bin`: byte raw da caricare in ROM/EEPROM;
- `.hex`: vista leggibile per controllare gli opcode;
- `.h`: array C/C++ da usare in Arduino IDE.

Per ora il modulo contiene solo la funzione vuota di scaffolding.

## `include/errors.h` e `src/errors.c`

Questi file gestiscono gli errori.

In C una funzione non puo lanciare eccezioni come in altri linguaggi. Per questo molte funzioni restituiscono un valore di tipo:

```c
Cpu8Status
```

Esempi:

```c
CPU8_OK
CPU8_ERROR_INVALID_ARGUMENT
CPU8_ERROR_IO
CPU8_ERROR_PARSE
CPU8_ERROR_ASSEMBLE
```

`cpu8_status_message` converte questi codici in messaggi leggibili.

## Concetti C da conoscere

Per studiare questo progetto conviene conoscere:

- `main`, `argc`, `argv`;
- puntatori;
- `struct`;
- `enum`;
- array;
- stringhe C terminate da `'\0'`;
- file con `FILE`, `fopen`, `fgets`, `fclose`;
- header `.h` e implementazioni `.c`;
- compilazione con `make`.

## Stato attuale

Il progetto assembler e ancora uno scaffold.

Funziona come struttura di base, ma non genera ancora byte macchina reali.

Le prossime parti da implementare saranno:

1. parsing di mnemonic e operandi;
2. parsing dei numeri (`0x`, `0b`, decimale);
3. codifica dei registri `R0`...`R7`, `RA`, `RB`;
4. generazione degli opcode secondo `docs/isa.md`;
5. output `.bin`, `.hex` e `.h`.
