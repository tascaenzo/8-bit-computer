# Programmi assembly

Questa cartella contiene programmi di esempio per la CPU a 8 bit.

I file `.asm` vengono assemblati dallo strumento in `tools/assembler`.

La sintassi usata negli esempi e descritta in [`docs/assembly-language.md`](../../docs/assembly-language.md). La semantica e la codifica macchina delle istruzioni sono definite in [`docs/isa.md`](../../docs/isa.md).

## Esempi disponibili

| File | Cosa mostra |
| --- | --- |
| `demo.asm` | template generale commentato con `.equ`, sezioni, label, variabili e schema della memoria |
| `01_numeric_formats.asm` | valori decimali, esadecimali e binari |
| `02_memory_and_directives.asm` | direttive, costanti, label e memoria |
| `03_add_two_numbers.asm` | somma con `RA`, `RB`, `ADD` e copia del risultato in un registro generale |
| `04_alu_operations.asm` | operazioni `AND`, `OR`, `XOR`, `NOR`, `NAND`, `XNOR`, `NOT` e `SUB` |
| `05_compare_unsigned.asm` | confronto unsigned con `CMP`, `JZ`, `JC` e `JMP` |
| `06_labels_and_two_passes.asm` | label in avanti e assemblaggio in due passate |
| `07_jump_conditions.asm` | panoramica di `JZ`, `JNZ`, `JC`, `JNC`, `JN`, `JNN`, `JO` e `JNO` |

`demo.asm` non e numerato perche serve come template autonomo. Gli altri file seguono l'ordine didattico consigliato da `01` a `07`.

## Sequenza per il video sull'assembler

Per il video dedicato all'assembler si possono mostrare `demo.asm`, `01`, `02` e `06`. I commenti possono essere letti o evidenziati mentre si analizzano le singole righe.

| File | Risultato previsto |
| --- | --- |
| `01_numeric_formats.asm` | `R0`...`R3` contengono tutti `0x2A` |
| `02_memory_and_directives.asm` | `R0` e `R1` contengono entrambi `0x0A` |
| `06_labels_and_two_passes.asm` | `R2` contiene `1` quando i valori sono uguali |

Compilazione dell'assembler:

```sh
make -C tools/assembler
```

Assemblaggio dei tre esempi dalla root del repository:

```sh
tools/assembler/build/cpu8asm examples/assembly/01_numeric_formats.asm -o tools/assembler/build/video-01
tools/assembler/build/cpu8asm examples/assembly/02_memory_and_directives.asm -o tools/assembler/build/video-02
tools/assembler/build/cpu8asm examples/assembly/06_labels_and_two_passes.asm -o tools/assembler/build/video-06
```

Dimensioni attese:

```text
01_numeric_formats.asm           9 byte
02_memory_and_directives.asm    10 byte
06_labels_and_two_passes.asm    18 byte
```

Durante la registrazione si puo seguire questa sequenza:

1. Confrontare le quattro scritture dello stesso valore in `01_numeric_formats.asm`.
2. Aprire `video-01.hex` e verificare che il byte immediato sia sempre `2A`.
3. Usare `02_memory_and_directives.asm` per distinguere istruzioni e direttive.
4. Aprire `video-02.hex` e mostrare la label `counter`, calcolata automaticamente e tradotta in `09 00` little-endian.
5. Usare `06_labels_and_two_passes.asm` per spiegare la tabella dei simboli.
6. Aprire `video-06.hex` e mostrare gli indirizzi `0F 00` per `equal` e `11 00` per `done`.

## Copertura ISA

| Area | Esempi |
| --- | --- |
| Sistema | tutti i programmi terminano con `HLT` |
| Load immediate | `demo.asm` e gli esempi numerati coprono `LDI` |
| Memoria | `demo.asm` e `02_memory_and_directives.asm` coprono `LDA`, `STA`, `.data` e `.byte` |
| ALU | `03_add_two_numbers.asm` copre `ADD`; `04_alu_operations.asm` copre le altre operazioni; `05_compare_unsigned.asm` copre `CMP` |
| Salti | `05_compare_unsigned.asm` copre i salti unsigned principali; `07_jump_conditions.asm` elenca tutti i salti condizionali; `06_labels_and_two_passes.asm` mostra le label in avanti |
| Trasferimenti | `03_add_two_numbers.asm`, `04_alu_operations.asm` e `05_compare_unsigned.asm` coprono `MOV RA, Rn`, `MOV RB, Rn` e `MOV Rn, RA` |

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
