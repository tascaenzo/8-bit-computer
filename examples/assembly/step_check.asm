; STEP_CHECK: 1 + 4 = 5, poi HLT. Guida: docs/step-check-guide.md.
; EEPROM PROGRAMMA; byte invariati: 26 04 27 01 C7 CE 67 00.
; CU ALU: T2 prepara ALU, T3 salva MDR+flag, T4 prepara MDR,
; T5 copia MDR in RA, T6 mantiene MDR e torna al fetch.
; LDI invariata: MDR in T2, Rn in T3, ritorno in T4.
; Dopo BOOT: RUN, PC=0000, microstep=000, clock manuale fermo BASSO.
; T1=000 (il tuo T0), T2=001, T3=010, T4=011, T5=100, T6=101.
; Misura PRIMA, dai UN impulso basso->alto->basso, verifica DOPO.
; 21 impulsi utili RUN; punto 22 fermo dopo HLT.
; Tester V DC, nero su GND; byte in hex (binario nella guida).
; 01=00000001, 04=00000100, 05=00000101, ordine bit7..0.
; MDR leggibile ai punti 3/7/18-20; R7 al 10, R6 al 13.
; Con /OE alto le Q non mostrano il contenuto del registro.
; Alla fine RA=MDR=05, RB=R6=04, R7=01, flag C/Z/N/O=0000.
; ALU dopo RA=05 puo dare 09: sul bus resta MDR=05 in T5/T6.

.code 0x0000
; LDI R6, 4
; N. | Step | Operazione | Tester PRIMA | DOPO
;  1 | T1 000 | RAM -> IR; PC++ | DB=26 dalla RAM | IR=26; PC=0001
;  2 | T2 001 | RAM -> MDR; PC++ | DB=04 dalla RAM | MDR=04; PC=0002
;  3 | T3 010 | MDR -> R6 | MDR in lettura: DB=04; ingresso R6 uguale | R6 memorizza 04
;  4 | T4 011 | Ritorno al fetch | Nessuna sorgente DB | T1 000; PC=0002
LDI R6, 4

; LDI R7, 1
; N. | Step | Operazione | Tester PRIMA | DOPO
;  5 | T1 000 | RAM -> IR; PC++ | DB=27 dalla RAM | IR=27; PC=0003
;  6 | T2 001 | RAM -> MDR; PC++ | DB=01 dalla RAM | MDR=01; PC=0004
;  7 | T3 010 | MDR -> R7 | MDR in lettura: DB=01; ingresso R7 uguale | R7 memorizza 01
;  8 | T4 011 | Ritorno al fetch | Nessuna sorgente DB | T1 000; PC=0004
LDI R7, 1

; MOV RA, R7
; N. | Step | Operazione | Tester PRIMA | DOPO
;  9 | T1 000 | RAM -> IR; PC++ | DB=C7 dalla RAM | IR=C7; PC=0005
; 10 | T2 001 | R7 -> RA | R7 in lettura: Q R7 e DB=01 | RA memorizza 01
; 11 | T3 010 | Ritorno al fetch | Nessuna sorgente DB | T1 000; PC=0005
MOV RA, R7

; MOV RB, R6
; N. | Step | Operazione | Tester PRIMA | DOPO
; 12 | T1 000 | RAM -> IR; PC++ | DB=CE dalla RAM | IR=CE; PC=0006
; 13 | T2 001 | R6 -> RB | R6 in lettura: Q R6 e DB=04 | RB memorizza 04
; 14 | T3 010 | Ritorno al fetch | Nessuna sorgente DB | T1 000; PC=0006
MOV RB, R6

; ADD
; N. | Step | Operazione | Tester PRIMA | DOPO
; 15 | T1 000 | RAM -> IR; PC++ | DB=67 dalla RAM | IR=67; PC=0007
; 16 | T2 001 | Prepara ALU; nessuna scrittura | ALU A=01, B=04; uscita e DB=05 | RA resta 01; ALU pronto per MDR
; 17 | T3 010 | ALU -> MDR; salva flag | DB e ingresso MDR=05; RA=01 | MDR=05; C Z N O=0 0 0 0; RA invariato
; 18 | T4 011 | Prepara MDR sul bus; nessuna scrittura | MDR in lettura: DB=05; ingresso RA uguale | MDR=05; dato pronto per RA
; 19 | T5 100 | MDR -> RA | DB e ingresso RA=05 da MDR | RA=05; MDR=05; flag invariati
; 20 | T6 101 | Mantiene MDR; ritorno al fetch | DB=05 da MDR; RA=05 | T1 000; PC=0007
ADD

; HLT
; N. | Step | Operazione | Tester PRIMA | DOPO
; 21 | T1 000 | RAM -> IR; PC++ | DB=00 dalla RAM | IR=00; PC=0008; T2 001 fermo
; 22 | T2 001 | Arresto; nessun impulso necessario | PC=0008; IR=00; flag=0000 (C/Z/N/O) | Nessun cambiamento
HLT
