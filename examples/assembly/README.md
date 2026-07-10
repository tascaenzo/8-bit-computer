# Programmi assembly

Questa cartella contiene programmi di esempio per la CPU a 8 bit.

I file `.asm` vengono assemblati dallo strumento in `tools/assembler`.

La sintassi usata negli esempi e descritta in [`docs/assembly-language.md`](../../docs/assembly-language.md). La semantica e la codifica macchina delle istruzioni sono definite in [`docs/isa.md`](../../docs/isa.md).

## Esempi disponibili

| File | Cosa mostra |
| --- | --- |
| `demo.asm` | panoramica commentata di `.equ`, `.code`, `.data`, label, variabili, `LDI`, `STA`, `LDA` e little-endian |
| `add_two_numbers.asm` | uso dei registri `RA` e `RB` come operandi della ALU e copia del risultato da `RA` a un registro generale |
| `alu_operations.asm` | operazioni ALU `AND`, `OR`, `XOR`, `NOR`, `NAND`, `XNOR`, `NOT` e `SUB` |
| `compare_unsigned.asm` | confronto unsigned con `CMP`, `JZ`, `JC` e `JMP` |
| `jump_conditions.asm` | panoramica di `JZ`, `JNZ`, `JC`, `JNC`, `JN`, `JNN`, `JO` e `JNO` |
| `01_numeric_formats.asm` | esempio commentato per il video: valori decimali, esadecimali e binari |
| `02_memory_and_directives.asm` | esempio commentato per il video: direttive, costanti, label e memoria |
| `03_labels_and_two_passes.asm` | esempio commentato per il video: label in avanti e doppia passata |

## Sequenza per il video sull'assembler

I file `01`, `02` e `03` sono pensati per essere mostrati in questo ordine durante la registrazione. I commenti possono essere letti o evidenziati mentre si analizzano le singole righe.

| File | Risultato previsto |
| --- | --- |
| `01_numeric_formats.asm` | `R0`...`R3` contengono tutti `0x2A` |
| `02_memory_and_directives.asm` | `R0` e `R1` contengono entrambi `0x0A` |
| `03_labels_and_two_passes.asm` | `R2` contiene `1` quando i valori sono uguali |

Compilazione dell'assembler:

```sh
make -C tools/assembler
```

Assemblaggio dei tre esempi dalla root del repository:

```sh
tools/assembler/build/cpu8asm examples/assembly/01_numeric_formats.asm -o tools/assembler/build/video-01
tools/assembler/build/cpu8asm examples/assembly/02_memory_and_directives.asm -o tools/assembler/build/video-02
tools/assembler/build/cpu8asm examples/assembly/03_labels_and_two_passes.asm -o tools/assembler/build/video-03
```

Dimensioni attese:

```text
01_numeric_formats.asm           9 byte
02_memory_and_directives.asm    10 byte
03_labels_and_two_passes.asm    18 byte
```

Durante la registrazione si puo seguire questa sequenza:

1. Confrontare le quattro scritture dello stesso valore in `01_numeric_formats.asm`.
2. Aprire `video-01.hex` e verificare che il byte immediato sia sempre `2A`.
3. Usare `02_memory_and_directives.asm` per distinguere istruzioni e direttive.
4. Aprire `video-02.hex` e mostrare la label `counter`, calcolata automaticamente e tradotta in `09 00` little-endian.
5. Usare `03_labels_and_two_passes.asm` per spiegare la tabella dei simboli.
6. Aprire `video-03.hex` e mostrare gli indirizzi `0F 00` per `equal` e `11 00` per `done`.

## Copertura ISA

| Area | Esempi |
| --- | --- |
| Sistema | tutti i programmi terminano con `HLT` |
| Load immediate | `demo.asm`, `add_two_numbers.asm`, `compare_unsigned.asm`, `alu_operations.asm`, `jump_conditions.asm` e gli esempi numerati coprono `LDI` |
| Memoria | `demo.asm` e `02_memory_and_directives.asm` coprono `LDA`, `STA`, `.data` e `.byte` |
| ALU | `add_two_numbers.asm` copre `ADD`; `alu_operations.asm` copre le altre operazioni; `compare_unsigned.asm` copre `CMP` |
| Salti | `compare_unsigned.asm` copre i salti unsigned principali; `jump_conditions.asm` elenca tutti i salti condizionali; `03_labels_and_two_passes.asm` mostra le label in avanti |
| Trasferimenti | `add_two_numbers.asm`, `compare_unsigned.asm` e `alu_operations.asm` coprono `MOV RA, Rn`, `MOV RB, Rn` e `MOV Rn, RA` |

## Esempio minimo

```asm
.code 0x0000
LDI R0, 0x0A
STA R0, counter
LDA R1, counter
HLT

.data
counter: .byte 0x00
```
