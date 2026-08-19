; Demo minimale con mappa del codice macchina solo in binario.
; I commenti qui sotto non producono byte: l'output e identico a demo.asm.

.equ INITIAL_VALUE, 0x0A :0b00001010

.code 0x0000
LDI R0, INITIAL_VALUE  ; 2 byte: opcode + valore immediato
STA R0, counter        ; 3 byte: opcode + indirizzo a 16 bit
LDA R1, counter        ; 3 byte: opcode + indirizzo a 16 bit
HLT                    ; 1 byte: solo opcode

.data
counter: .byte 0x00 ; 1 byte di dato

; =============================================================================
; BYTE GENERATI: PC / bus dati
; =============================================================================
;
; Ogni riga e un byte della memoria. Quando il PC assume l'indirizzo nella
; prima colonna, la memoria mette gli 8 bit della colonna "Binario" sul bus dati.
;
; +-------------------+-----------+--------+-----------------------------------+
; | Indirizzo (16 bit)| Bus dati  | Byte   | Significato                       |
; +-------------------+-----------+--------+-----------------------------------+
; | 0000 0000 0000 0000 | 0010 0000 | 2      | LDI R0: opcode                  |
; | 0000 0000 0000 0001 | 0000 1010 |        | LDI R0: valore immediato        |
; | 0000 0000 0000 0010 | 0100 1000 | 3      | STA R0: opcode                  |
; | 0000 0000 0000 0011 | 0000 1001 |        | STA R0: indirizzo byte basso    |
; | 0000 0000 0000 0100 | 0000 0000 |        | STA R0: indirizzo byte alto     |
; | 0000 0000 0000 0101 | 0100 0001 | 3      | LDA R1: opcode                  |
; | 0000 0000 0000 0110 | 0000 1001 |        | LDA R1: indirizzo byte basso    |
; | 0000 0000 0000 0111 | 0000 0000 |        | LDA R1: indirizzo byte alto     |
; | 0000 0000 0000 1000 | 0000 0001 | 1      | HLT: solo opcode                |
; +---------------------+-----------+--------+---------------------------------+
; | 0000 0000 0000 1001 | 0000 0000 | 1      | counter: valore iniziale        |
; +---------------------+-----------+--------+---------------------------------+
;
; Le istruzioni con un indirizzo a 16 bit usano il formato:
;
;     opcode  byte_basso  byte_alto
;
; Per questo counter viene letto come 0000 1001, poi 0000 0000.
