; Programma dimostrativo iniziale.

.code 0x0000
LDI R0, 0x0A
STA R0, counter
LDA R1, counter
OUT R0
OUT R1
HLT

.data 0x0010
counter: .byte 0x00
