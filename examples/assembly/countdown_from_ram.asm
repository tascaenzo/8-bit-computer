.code 0x0000
LDI R1, 1
LDA R0, start
MOV RA, R0
MOV RB, R1

loop:
SUB
; JNZ = Jump if Not Zero: torna a loop se Z = 0.
; SUB aggiorna Z: con risultato 2 o 1 ripete il ciclo;
; con risultato 0, Z = 1 e prosegue con HLT. Non serve CMP.
JNZ loop
HLT

.data
start: .byte 3
