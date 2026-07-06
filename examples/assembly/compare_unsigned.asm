; Esempio didattico: confronto unsigned tra due numeri.
;
; Obiettivo:
; - confrontare RA e RB con CMP;
; - usare JZ per il caso RA == RB;
; - usare JC per il caso RA < RB;
; - usare il percorso rimanente per il caso RA >= RB.
;
; Valori di output:
; - 0x00 se R0 == R1;
; - 0x01 se R0 < R1;
; - 0x02 se R0 >= R1.

.code 0x0000
LDI R0, 3
LDI R1, 9

MOV RA, R0
MOV RB, R1
CMP

JZ equal
JC less_than

greater_or_equal:
LDI R2, 0x02
JMP done

equal:
LDI R2, 0x00
JMP done

less_than:
LDI R2, 0x01

done:
OUT R2
HLT
