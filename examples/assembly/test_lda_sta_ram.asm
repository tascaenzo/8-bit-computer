; Test isolato LDA / STA sulla RAM, senza I/O, IDX, ALU o salti.
; Codice: 10 byte (0000-0009). Dati: 0100=5A, 0201=A5.
; Il BOOT deve copiare almeno fino a 0201 incluso.
; Dopo BOOT: RUN, PC=0000, microstep T1=000, clock manuale basso.
; Atteso: R0=5A, R1=5A, RAM[0201]=5A, MAR=0201, PC=000A.
; 19 impulsi RUN; punto 20 = HLT/T2, solo misura.
; Il file .sparse.hex contiene solo i 12 byte necessari.
.code 0x0000
LDA R0, source
STA R0, destination
LDA R1, destination
HLT

.data 0x0100
source: .byte 0x5A

.data 0x0201
destination: .byte 0xA5
