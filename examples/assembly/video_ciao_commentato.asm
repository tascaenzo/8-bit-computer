; Scrive CIAO alla colonna 5, riga 2 (coordinate da zero).
; Testo oro su sfondo blu scuro. Eseguire con CPU in RUN.
; Mappa video corrente: posizione tramite CURSOR_X/Y, senza PTR_L/H.

.code 0x0000            ; Il programma inizia all'indirizzo 0 della RAM

; Attende che la scheda video sia pronta
attendi:
LDA R0, 0x2018          ; Legge VIDEO_STATUS e salva il valore in R0
LDI R1, 1               ; Carica il valore atteso: READY=1, BUSY=0
MOV RA, R0              ; Copia lo stato letto nel primo ingresso della ALU
MOV RB, R1              ; Copia il valore atteso nel secondo ingresso della ALU
CMP                     ; Confronta RA e RB: se sono uguali, Z diventa 1
JNZ attendi             ; Se Z=0, torna ad attendi e rilegge lo stato

; Abilita avanzamento, ritorno a capo e scorrimento
LDI R0, 0x1C            ; Prepara 00011100: INC, WRAP e SCROLL attivi
STA R0, 0x2040          ; Scrive CONTROL; il cursore visibile resta disattivato

; Sceglie dove iniziare a scrivere
LDI R0, 5               ; Carica il numero della colonna iniziale
STA R0, 0x2030          ; Scrive CURSOR_X: colonna = 5
LDI R0, 2               ; Carica il numero della riga
STA R0, 0x2038          ; Scrive CURSOR_Y: riga = 2

; Sceglie i colori delle prossime scritture
LDI R0, 0x1E            ; Prepara 0001 1110: sfondo blu scuro, testo oro
STA R0, 0x2028          ; Scrive COLOR; il valore rimane memorizzato

; Scrive il testo, un carattere alla volta
LDI R0, 0x43            ; Carica il codice ASCII di C
STA R0, 0x2000          ; Scrive C alla colonna 5, poi avanza alla 6
LDI R0, 0x49            ; Carica il codice ASCII di I
STA R0, 0x2000          ; Scrive I alla colonna 6, poi avanza alla 7
LDI R0, 0x41            ; Carica il codice ASCII di A
STA R0, 0x2000          ; Scrive A alla colonna 7, poi avanza alla 8
LDI R0, 0x4F            ; Carica il codice ASCII di O
STA R0, 0x2000          ; Scrive O alla colonna 8, poi avanza alla 9

HLT                     ; Ferma la CPU; la FPGA continua a mostrare il testo
