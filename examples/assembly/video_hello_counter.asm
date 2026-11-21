; Tang Nano 9K: HELLO WORLD, poi una variabile incrementata a ogni ciclo.
; CPU/CU attuali: accessi RAM/video tramite IDX; i salti usano ancora MAR.
; Eseguire dopo BOOT, in RUN. Il programma attende READY e cancella il video.
; Output: HELLO WORLD, poi VAR = 000, VAR = 001, ... VAR = 255, VAR = 000...
; counter e' un byte RAM a 0100, inizializzato dal codice (non dalla EEPROM).
; La conversione decimale usa CMP/JC e sottrazioni ripetute, senza divisione.
; Nessun HLT: ciclo infinito. DELAY_COUNT regola la pausa, non e' un timer.
.equ VIDEO_DATA, 0x2000
.equ VIDEO_STATUS, 0x2018
.equ VIDEO_CMD, 0x2020
.equ VIDEO_COLOR, 0x2028
.equ VIDEO_CONTROL, 0x2040
.equ COUNTER, 0x0100
.equ DELAY_COUNT, 32

.code 0x0000
LDX VIDEO_STATUS
wait_ready:
LDAI R0
LDI R1, 1
MOV RA, R0
MOV RB, R1
CMP
JNZ wait_ready

; Bianco su nero; avanzamento, wrap e scroll; cursore nascosto.
LDI R0, 0x0F
LDX VIDEO_COLOR
STAI R0
LDI R0, 0x1C
LDX VIDEO_CONTROL
STAI R0
LDI R0, 1
LDX VIDEO_CMD
STAI R0

LDX VIDEO_STATUS
wait_clear:
LDAI R0
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
LDI R0, 0x20
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
LDI R0, 3           ; NEWLINE; VIDEO_DATA non interpreta LF/CR.
LDX VIDEO_CMD
STAI R0

LDX COUNTER
LDI R4, 0
STAI R4

loop:
; Attende anche eventuale scroll avviato dalla NEWLINE precedente.
LDX VIDEO_STATUS
wait_line:
LDAI R0
LDI R1, 1
MOV RA, R0
MOV RB, R1
CMP
JNZ wait_line

LDX COUNTER
LDAI R4
LDI R5, 0x30        ; Cifra ASCII delle centinaia.
LDI R6, 0x30        ; Cifra ASCII delle decine.
LDI R2, 1
LDI R1, 100
hundreds:
MOV RA, R4
MOV RB, R1
CMP
JC tens_setup       ; C = borrow: il resto e' minore di 100.
SUB
MOV R4, RA
MOV RA, R5
MOV RB, R2
ADD
MOV R5, RA
JMP hundreds

tens_setup:
LDI R1, 10
tens:
MOV RA, R4
MOV RB, R1
CMP
JC digits_ready
SUB
MOV R4, RA
MOV RA, R6
MOV RB, R2
ADD
MOV R6, RA
JMP tens

digits_ready:
; R4 e' il resto 0..9: lo converte nella cifra ASCII delle unita'.
LDI R1, 0x30
MOV RA, R4
MOV RB, R1
ADD
MOV R4, RA

LDX VIDEO_DATA
LDI R0, 0x56        ; V
STAI R0
LDI R0, 0x41        ; A
STAI R0
LDI R0, 0x52        ; R
STAI R0
LDI R0, 0x20
STAI R0
LDI R0, 0x3D        ; =
STAI R0
LDI R0, 0x20
STAI R0
STAI R5
STAI R6
STAI R4
LDI R0, 3
LDX VIDEO_CMD
STAI R0

; Pausa per rendere visibili le righe con CK automatico circa 1 kHz.
; Cambiare DELAY_COUNT tra 1 e 255. La durata varia con il clock CPU.
LDI R0, DELAY_COUNT
MOV RA, R0
MOV RB, R2
delay:
SUB
JNZ delay

; Rilegge il vero contatore RAM: R4 era stato usato per la conversione.
LDX COUNTER
LDAI R4
MOV RA, R4
MOV RB, R2
ADD
MOV R4, RA
STAI R4
JMP loop
