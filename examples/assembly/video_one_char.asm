; Prova video minima: una H, senza letture STATUS, salti, clear o IDX.
; Prima del test resettare la Tang e attendere READY in RUN (LED1 acceso).
; BOOT CPU completato, PC=0000, T1=000, clock manuale basso.
; La richiesta di scrittura compare al punto 10, STA/T6 (101).
; A=2000, DB=48, Y0=1, /RD=1, /WR=0, DIR dati=0, /OE dati=0.
; La Tang acquisisce con il suo clock: H puo apparire PRIMA del fronte CPU.
; 13 impulsi totali, poi punto 14 fermo in HLT/T2.
; Senza reset Tang, una nuova esecuzione scrive nella cella successiva.
.code 0x0000
LDI R0, 0x48
STA R0, 0x2000
HLT
