# Programmi assembly

Questa cartella contiene programmi di esempio per la CPU a 8 bit.

I file `.asm` saranno compilati dall'assembler in `tools/assembler`.

## Esempi disponibili

| File | Cosa mostra |
| --- | --- |
| `demo.asm` | uso base di `.code`, `.data`, `LDI`, `STA`, `LDA` e `OUT` |
| `add_two_numbers.asm` | uso dei registri `RA` e `RB` come operandi della ALU e copia del risultato da `RA` a un registro generale |
| `alu_operations.asm` | operazioni ALU `AND`, `OR`, `XOR`, `NOR`, `NAND`, `XNOR`, `NOT` e `SUB` |
| `compare_unsigned.asm` | confronto unsigned con `CMP`, `JZ`, `JC` e `JMP` |
| `input_output.asm` | istruzioni `NOP`, `IN`, `OUT` e `HLT` |
| `jump_conditions.asm` | panoramica di `JZ`, `JNZ`, `JC`, `JNC`, `JN`, `JNN`, `JO` e `JNO` |

## Copertura ISA

| Area | Esempi |
| --- | --- |
| Sistema | `input_output.asm` copre `NOP` e `HLT` |
| Load immediate | `demo.asm`, `add_two_numbers.asm`, `compare_unsigned.asm`, `alu_operations.asm` e `jump_conditions.asm` coprono `LDI` |
| Memoria | `demo.asm` copre `LDA`, `STA`, `.data` e `.byte` |
| ALU | `add_two_numbers.asm` copre `ADD`; `alu_operations.asm` copre le altre operazioni; `compare_unsigned.asm` copre `CMP` |
| Input/output | `input_output.asm` copre `IN`; vari esempi coprono `OUT` |
| Salti | `compare_unsigned.asm` copre i salti unsigned principali; `jump_conditions.asm` elenca tutti i salti condizionali |
| Trasferimenti | `add_two_numbers.asm`, `compare_unsigned.asm` e `alu_operations.asm` coprono `MOV RA, Rn`, `MOV RB, Rn` e `MOV Rn, RA` |

## Esempio minimo

```asm
.code 0x0000
LDI R0, 0x0A
STA R0, counter
LDA R1, counter
OUT R0
OUT R1
HLT

.data 0x0010
counter: .byte 0x00
```
