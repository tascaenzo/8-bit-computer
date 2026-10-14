; Tang Nano 9K: HELLO WORLD FROM 8 BIT COMPUTER nella prima riga.
; Avviare dopo LED1 acceso (VRAM pronta). Le coordinate partono da zero.
; IDX non si incrementa automaticamente: LDX carica ogni nuovo indirizzo.
.equ VIDEO, 0x4000
.equ R2_C5, 0x4105
.code 0x0000
LDX VIDEO
LDI R0, 0x48         ; H
STAI R0
LDX 0x4001
LDI R0, 0x45         ; E
STAI R0
LDX 0x4002
LDI R0, 0x4C         ; L
STAI R0
LDX 0x4003
LDI R0, 0x4C         ; L
STAI R0
LDX 0x4004
LDI R0, 0x4F         ; O
STAI R0
LDX 0x4005
LDI R0, 0x20         ; spazio
STAI R0
LDX 0x4006
LDI R0, 0x57         ; W
STAI R0
LDX 0x4007
LDI R0, 0x4F         ; O
STAI R0
LDX 0x4008
LDI R0, 0x52         ; R
STAI R0
LDX 0x4009
LDI R0, 0x4C         ; L
STAI R0
LDX 0x400A
LDI R0, 0x44         ; D
STAI R0
LDX 0x400B
LDI R0, 0x20         ; spazio
STAI R0
LDX 0x400C
LDI R0, 0x46         ; F
STAI R0
LDX 0x400D
LDI R0, 0x52         ; R
STAI R0
LDX 0x400E
LDI R0, 0x4F         ; O
STAI R0
LDX 0x400F
LDI R0, 0x4D         ; M
STAI R0
LDX 0x4010
LDI R0, 0x20         ; spazio
STAI R0
LDX 0x4011
LDI R0, 0x38         ; 8
STAI R0
LDX 0x4012
LDI R0, 0x20         ; spazio
STAI R0
LDX 0x4013
LDI R0, 0x42         ; B
STAI R0
LDX 0x4014
LDI R0, 0x49         ; I
STAI R0
LDX 0x4015
LDI R0, 0x54         ; T
STAI R0
LDX 0x4016
LDI R0, 0x20         ; spazio
STAI R0
LDX 0x4017
LDI R0, 0x43         ; C
STAI R0
LDX 0x4018
LDI R0, 0x4F         ; O
STAI R0
LDX 0x4019
LDI R0, 0x4D         ; M
STAI R0
LDX 0x401A
LDI R0, 0x50         ; P
STAI R0
LDX 0x401B
LDI R0, 0x55         ; U
STAI R0
LDX 0x401C
LDI R0, 0x54         ; T
STAI R0
LDX 0x401D
LDI R0, 0x45         ; E
STAI R0
LDX 0x401E
LDI R0, 0x52         ; R
STAI R0
LDX R2_C5
LDI R0, 0x41         ; A in riga 2, colonna 5: verifica indirizzamento.
STAI R0
LDAI R1             ; R1 deve diventare 0x41.
HLT                 ; il video continua anche con CPU ferma.
