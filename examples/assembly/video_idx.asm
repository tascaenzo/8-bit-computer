; Tang Nano 9K: prova HELLO WORLD con la mappa video corrente (Y0).
; Eseguire in RUN. Usa solo istruzioni esistenti della CPU.
; IDX resta su VIDEO_DATA: il puntatore video avanza nella Tang.
.equ VIDEO_DATA, 0x2000
.equ VIDEO_CURSOR_X, 0x2030
.equ VIDEO_CURSOR_Y, 0x2038
.equ VIDEO_STATUS, 0x2018
.equ VIDEO_CMD, 0x2020
.equ VIDEO_COLOR, 0x2028
.equ VIDEO_CONTROL, 0x2040

.code 0x0000
; Attende READY=1 prima di iniziare.
wait_ready:
LDA R0, VIDEO_STATUS
LDI R1, 1
MOV RA, R0
MOV RB, R1
CMP
JNZ wait_ready

; Testo bianco su nero, avanzamento/wrap/scroll attivi, cursore nascosto.
LDI R0, 0x0F
STA R0, VIDEO_COLOR
LDI R0, 0x1C
STA R0, VIDEO_CONTROL
LDI R0, 1
STA R0, VIDEO_CMD

; CLEAR porta il puntatore a zero. Attende il completamento.
wait_clear:
LDA R0, VIDEO_STATUS
LDI R1, 1
MOV RA, R0
MOV RB, R1
CMP
JNZ wait_clear

LDX VIDEO_DATA
LDI R0, 0x48         ; H
STAI R0
LDI R0, 0x45         ; E
STAI R0
LDI R0, 0x4C         ; L
STAI R0
LDI R0, 0x4C         ; L
STAI R0
LDI R0, 0x4F         ; O
STAI R0
LDI R0, 0x20         ; spazio
STAI R0
LDI R0, 0x57         ; W
STAI R0
LDI R0, 0x4F         ; O
STAI R0
LDI R0, 0x52         ; R
STAI R0
LDI R0, 0x4C         ; L
STAI R0
LDI R0, 0x44         ; D
STAI R0
LDI R0, 0x20         ; spazio
STAI R0
LDI R0, 0x46         ; F
STAI R0
LDI R0, 0x52         ; R
STAI R0
LDI R0, 0x4F         ; O
STAI R0
LDI R0, 0x4D         ; M
STAI R0
LDI R0, 0x20         ; spazio
STAI R0
LDI R0, 0x38         ; 8
STAI R0
LDI R0, 0x20         ; spazio
STAI R0
LDI R0, 0x42         ; B
STAI R0
LDI R0, 0x49         ; I
STAI R0
LDI R0, 0x54         ; T
STAI R0
LDI R0, 0x20         ; spazio
STAI R0
LDI R0, 0x43         ; C
STAI R0
LDI R0, 0x4F         ; O
STAI R0
LDI R0, 0x4D         ; M
STAI R0
LDI R0, 0x50         ; P
STAI R0
LDI R0, 0x55         ; U
STAI R0
LDI R0, 0x54         ; T
STAI R0
LDI R0, 0x45         ; E
STAI R0
LDI R0, 0x52         ; R
STAI R0

; Riga 2, colonna 5 (coordinate da zero), impostate tramite CURSOR_X/Y.
LDI R0, 0x05
STA R0, VIDEO_CURSOR_X
LDI R0, 0x02
STA R0, VIDEO_CURSOR_Y
LDI R0, 0x0E         ; Oro su nero
STA R0, VIDEO_COLOR
LDI R0, 0x41         ; A
STAI R0
HLT                 ; Il video continua a CPU ferma.
