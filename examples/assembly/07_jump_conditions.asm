; ESEMPIO ASSEMBLY 07: panoramica dei salti condizionali.
;
; CMP aggiorna i flag confrontando RA e RB.
; Le istruzioni JZ, JNZ, JC e JNC sono le piu utili per confronti unsigned.
; JN, JNN, JO e JNO leggono invece i flag N e O.

.code 0x0000
LDI R0, 5
LDI R1, 5
MOV RA, R0
MOV RB, R1
CMP

JZ equal
JNZ not_equal
JC carry_set
JNC carry_clear
JN negative
JNN not_negative
JO overflow
JNO no_overflow

equal:
LDI R2, 0x00
JMP done

not_equal:
LDI R2, 0x01
JMP done

carry_set:
LDI R2, 0x02
JMP done

carry_clear:
LDI R2, 0x03
JMP done

negative:
LDI R2, 0x04
JMP done

not_negative:
LDI R2, 0x05
JMP done

overflow:
LDI R2, 0x06
JMP done

no_overflow:
LDI R2, 0x07

done:
HLT
