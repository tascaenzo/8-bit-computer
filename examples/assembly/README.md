# Programmi assembly

Questa cartella contiene programmi di esempio per la CPU a 8 bit.

I file `.asm` saranno compilati dall'assembler in `tools/assembler`.

## Esempio

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
