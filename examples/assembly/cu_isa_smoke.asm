; Prova hardware della CU senza periferiche IN/OUT.
; Richiede le tre nuove Control ROM, SYS_STEP_n OR IR[2:0] e la EPROM
; programma assemblata con gli opcode correnti (SUB=0x78, JNZ=0xB8).
; Dopo il BOOT e l'esecuzione devono valere:
; RAM[0x0100]=0x05, RAM[0x0101]=0x5A, RAM[0x0102]=0x05.
; Se JNZ non funziona, RAM[0x0101] diventa 0xE1 invece di 0x5A.

.code 0x0000
LDI R0, 9
LDI R1, 4
MOV RA, R0
MOV RB, R1
SUB
MOV R2, RA
STA R2, 0x0100
LDA R3, 0x0100
MOV RA, R3
CMP
JNZ success
LDI R7, 0xE1
STA R7, 0x0101
HLT

success:
LDX 0x0102
STAI R3
LDAI R4
LDI R7, 0x5A
STA R7, 0x0101
HLT
