; Test progressivo del registro IDX e del bus indirizzi A15..A0.
; Sequenza: 0000, 0001, 0003, 0007, ... , 7FFF, FFFF.
; Ogni valore richiede LDX per caricare IDX e LDAI per esporlo sul bus.
; Osservare il bus durante T2 di LDAI (clock manuale / microstep).
; Durante il fetch il bus mostra PC, non IDX.
; Le letture in R0 vengono ignorate. Il programma non scrive in memoria.
; Fuori RAM si generano richieste /RD: eventuali periferiche selezionate
; possono avere effetti di lettura. Per il solo collaudo indirizzi, mantenere
; le periferiche scollegate o bloccate tramite la loro abilitazione.
; Dopo HLT IDX resta FFFF, ma il bus non e necessariamente pilotato da IDX.

.code 0x0000

; A15..A0 = 0000000000000000 (0 bit accesi)
LDX 0x0000
LDAI R0

; A15..A0 = 0000000000000001 (1 bit accesi)
LDX 0x0001
LDAI R0

; A15..A0 = 0000000000000011 (2 bit accesi)
LDX 0x0003
LDAI R0

; A15..A0 = 0000000000000111 (3 bit accesi)
LDX 0x0007
LDAI R0

; A15..A0 = 0000000000001111 (4 bit accesi)
LDX 0x000F
LDAI R0

; A15..A0 = 0000000000011111 (5 bit accesi)
LDX 0x001F
LDAI R0

; A15..A0 = 0000000000111111 (6 bit accesi)
LDX 0x003F
LDAI R0

; A15..A0 = 0000000001111111 (7 bit accesi)
LDX 0x007F
LDAI R0

; A15..A0 = 0000000011111111 (8 bit accesi)
LDX 0x00FF
LDAI R0

; A15..A0 = 0000000111111111 (9 bit accesi)
LDX 0x01FF
LDAI R0

; A15..A0 = 0000001111111111 (10 bit accesi)
LDX 0x03FF
LDAI R0

; A15..A0 = 0000011111111111 (11 bit accesi)
LDX 0x07FF
LDAI R0

; A15..A0 = 0000111111111111 (12 bit accesi)
LDX 0x0FFF
LDAI R0

; A15..A0 = 0001111111111111 (13 bit accesi)
LDX 0x1FFF
LDAI R0

; A15..A0 = 0011111111111111 (14 bit accesi)
LDX 0x3FFF
LDAI R0

; A15..A0 = 0111111111111111 (15 bit accesi)
LDX 0x7FFF
LDAI R0

; A15..A0 = 1111111111111111 (16 bit accesi)
LDX 0xFFFF
LDAI R0

HLT
