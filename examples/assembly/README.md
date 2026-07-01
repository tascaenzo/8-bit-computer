# Programmi assembly

Questa cartella contiene programmi di esempio per la CPU a 8 bit.

I file `.asm` saranno compilati dall'assembler in `tools/assembler`.

## Esempio

```asm
LDI R0, 0x0A
STA R0, 0x000E
OUT R0
HLT
```
