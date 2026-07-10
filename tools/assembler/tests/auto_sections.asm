; Verifica degli indirizzi automatici per .code e .data.
.code
LDI R0, 0x0A
STA R0, counter
LDA R1, counter
OUT R0
OUT R1
HLT

.data
counter: .byte 0x00
