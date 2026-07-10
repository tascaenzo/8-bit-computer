; Esempio didattico: operazioni principali della ALU.
;
; La ALU lavora sui registri RA e RB.
; Dopo ogni operazione il risultato resta in RA e viene copiato in R2.
; L'operazione successiva sostituisce il valore precedente; al termine R2
; contiene il risultato dell'ultima operazione, R0 - R1.

.code 0x0000
LDI R0, 0x0C
LDI R1, 0x0A

; RA = R0 AND R1
MOV RA, R0
MOV RB, R1
AND
MOV R2, RA

; RA = R0 OR R1
MOV RA, R0
MOV RB, R1
OR
MOV R2, RA

; RA = R0 XOR R1
MOV RA, R0
MOV RB, R1
XOR
MOV R2, RA

; RA = R0 NOR R1
MOV RA, R0
MOV RB, R1
NOR
MOV R2, RA

; RA = R0 NAND R1
MOV RA, R0
MOV RB, R1
NAND
MOV R2, RA

; RA = R0 XNOR R1
MOV RA, R0
MOV RB, R1
XNOR
MOV R2, RA

; RA = NOT R0
MOV RA, R0
NOT
MOV R2, RA

; RA = R0 - R1
MOV RA, R0
MOV RB, R1
SUB
MOV R2, RA

HLT
