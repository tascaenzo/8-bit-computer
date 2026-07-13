; ESEMPIO ASSEMBLY 03: somma due numeri a 8 bit.
;
; Obiettivo:
; - caricare due valori nei registri generali R0 e R1;
; - copiarli nei registri operandi della ALU, RA e RB;
; - eseguire ADD;
; - copiare il risultato da RA a R2.

.code 0x0000
LDI R0, 7
LDI R1, 5

MOV RA, R0
MOV RB, R1
ADD
MOV R2, RA

HLT
