; Test minimale per label e salti.
.code 0x0000
LDI R0, 0x01
LDI R1, 0x01
MOV RA, R0
MOV RB, R1
CMP
JZ equal
LDI R2, 0x00
JMP done

equal:
LDI R2, 0x01

done:
OUT R2
HLT
