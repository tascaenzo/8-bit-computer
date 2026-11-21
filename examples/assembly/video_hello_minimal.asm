; HELLO WORLD / FROM 8 BIT COMPUTER - spiegazione passo passo.
;
; PRIMA DI ESEGUIRE
; Resettare la Tang e attendere READY. Completare il BOOT della CPU,
; poi partire in RUN con PC=0000, microstep T1 e clock manuale basso.
; Il BOOT copia il programma dalla EPROM alla RAM; queste istruzioni
; vengono eseguite solo nella successiva fase RUN.
;
; STATO VIDEO DOPO IL RESET
; Posizione iniziale: riga 0, colonna 0 (coordinate da zero).
; COLOR=0x0F: testo bianco su sfondo nero.
; CONTROL=0x1C: avanzamento, ritorno a capo e scorrimento automatici.
; Il programma usa questi valori senza modificarli. Non legge STATUS
; e non cancella lo schermo: l'attesa iniziale di READY e esterna al codice.
;
; COME PASSANO I DATI
; LDX carica in IDX l'indirizzo del registro video da raggiungere.
; LDI carica un byte in R0: questa istruzione non scrive nella FPGA.
; STAI scrive R0 all'indirizzo contenuto in IDX, usando il bus dati
; e la richiesta /WR. La CPU trasferisce il byte tramite il registro MDR.
; A IDX=0x2000, la FPGA interpreta il byte come un carattere (DATA).
; A IDX=0x2020, la FPGA interpreta il byte come un comando (CMD).
; STAI non incrementa IDX: e il puntatore interno della FPGA ad avanzare
; dopo un carattere. Le scritture successive usano sempre DATA=0x2000.
;
; RISULTATO ATTESO
; Riga 0: HELLO WORLD
; Riga 1: FROM 8 BIT COMPUTER
; 101 byte. Alla fine: IDX=0x2000, R0=0x52, PC=0x0065, CPU in HLT.
; Dopo l'ultima lettera il puntatore video e a riga 1, colonna 19.

.code 0x0000            ; Colloca il primo byte del programma in RAM a 0x0000.

; 1. PRIMA RIGA: HELLO WORLD.
LDX 0x2000              ; IDX=DATA: le prossime STAI invieranno caratteri alla FPGA.
LDI R0, 0x48            ; Prepara in R0 il codice ASCII di 'H': 01001000.
STAI R0                 ; Scrive 'H' a riga 0, colonna 0; la FPGA avanza a colonna 1.
LDI R0, 0x45            ; Prepara in R0 il codice ASCII di 'E': 01000101.
STAI R0                 ; Scrive 'E' a riga 0, colonna 1; la FPGA avanza a colonna 2.
LDI R0, 0x4C            ; Prepara in R0 il codice ASCII di 'L': 01001100.
STAI R0                 ; Scrive 'L' a riga 0, colonna 2; la FPGA avanza a colonna 3.
STAI R0                 ; Riusa R0='L': scrive la seconda L a colonna 3 e avanza a 4.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STAI R0                 ; Scrive 'O' a riga 0, colonna 4; la FPGA avanza a colonna 5.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STAI R0                 ; Scrive uno spazio a riga 0, colonna 5; la FPGA avanza a colonna 6.
LDI R0, 0x57            ; Prepara in R0 il codice ASCII di 'W': 01010111.
STAI R0                 ; Scrive 'W' a riga 0, colonna 6; la FPGA avanza a colonna 7.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STAI R0                 ; Scrive 'O' a riga 0, colonna 7; la FPGA avanza a colonna 8.
LDI R0, 0x52            ; Prepara in R0 il codice ASCII di 'R': 01010010.
STAI R0                 ; Scrive 'R' a riga 0, colonna 8; la FPGA avanza a colonna 9.
LDI R0, 0x4C            ; Prepara in R0 il codice ASCII di 'L': 01001100.
STAI R0                 ; Scrive 'L' a riga 0, colonna 9; la FPGA avanza a colonna 10.
LDI R0, 0x44            ; Prepara in R0 il codice ASCII di 'D': 01000100.
STAI R0                 ; Scrive 'D' a riga 0, colonna 10; la FPGA avanza a colonna 11.

; 2. CAMBIO RIGA: lo stesso bus dati ora trasporta un comando.
LDX 0x2020              ; IDX=CMD: seleziona il registro comandi, senza eseguirne ancora uno.
LDI R0, 0x03            ; Prepara in R0 il comando NEWLINE: 00000011.
STAI R0                 ; Invia 0x03 a CMD: passa a riga 1, colonna 0. Non stampa un carattere.

; 3. SECONDA RIGA: FROM 8 BIT COMPUTER.
LDX 0x2000              ; IDX=DATA: le prossime STAI invieranno caratteri alla FPGA.
LDI R0, 0x46            ; Prepara in R0 il codice ASCII di 'F': 01000110.
STAI R0                 ; Scrive 'F' a riga 1, colonna 0; la FPGA avanza a colonna 1.
LDI R0, 0x52            ; Prepara in R0 il codice ASCII di 'R': 01010010.
STAI R0                 ; Scrive 'R' a riga 1, colonna 1; la FPGA avanza a colonna 2.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STAI R0                 ; Scrive 'O' a riga 1, colonna 2; la FPGA avanza a colonna 3.
LDI R0, 0x4D            ; Prepara in R0 il codice ASCII di 'M': 01001101.
STAI R0                 ; Scrive 'M' a riga 1, colonna 3; la FPGA avanza a colonna 4.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STAI R0                 ; Scrive uno spazio a riga 1, colonna 4; la FPGA avanza a colonna 5.
LDI R0, 0x38            ; Prepara in R0 il codice ASCII di '8': 00111000.
STAI R0                 ; Scrive '8' a riga 1, colonna 5; la FPGA avanza a colonna 6.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STAI R0                 ; Scrive uno spazio a riga 1, colonna 6; la FPGA avanza a colonna 7.
LDI R0, 0x42            ; Prepara in R0 il codice ASCII di 'B': 01000010.
STAI R0                 ; Scrive 'B' a riga 1, colonna 7; la FPGA avanza a colonna 8.
LDI R0, 0x49            ; Prepara in R0 il codice ASCII di 'I': 01001001.
STAI R0                 ; Scrive 'I' a riga 1, colonna 8; la FPGA avanza a colonna 9.
LDI R0, 0x54            ; Prepara in R0 il codice ASCII di 'T': 01010100.
STAI R0                 ; Scrive 'T' a riga 1, colonna 9; la FPGA avanza a colonna 10.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STAI R0                 ; Scrive uno spazio a riga 1, colonna 10; la FPGA avanza a colonna 11.
LDI R0, 0x43            ; Prepara in R0 il codice ASCII di 'C': 01000011.
STAI R0                 ; Scrive 'C' a riga 1, colonna 11; la FPGA avanza a colonna 12.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STAI R0                 ; Scrive 'O' a riga 1, colonna 12; la FPGA avanza a colonna 13.
LDI R0, 0x4D            ; Prepara in R0 il codice ASCII di 'M': 01001101.
STAI R0                 ; Scrive 'M' a riga 1, colonna 13; la FPGA avanza a colonna 14.
LDI R0, 0x50            ; Prepara in R0 il codice ASCII di 'P': 01010000.
STAI R0                 ; Scrive 'P' a riga 1, colonna 14; la FPGA avanza a colonna 15.
LDI R0, 0x55            ; Prepara in R0 il codice ASCII di 'U': 01010101.
STAI R0                 ; Scrive 'U' a riga 1, colonna 15; la FPGA avanza a colonna 16.
LDI R0, 0x54            ; Prepara in R0 il codice ASCII di 'T': 01010100.
STAI R0                 ; Scrive 'T' a riga 1, colonna 16; la FPGA avanza a colonna 17.
LDI R0, 0x45            ; Prepara in R0 il codice ASCII di 'E': 01000101.
STAI R0                 ; Scrive 'E' a riga 1, colonna 17; la FPGA avanza a colonna 18.
LDI R0, 0x52            ; Prepara in R0 il codice ASCII di 'R': 01010010.
STAI R0                 ; Scrive 'R' a riga 1, colonna 18; la FPGA avanza a colonna 19.

; 4. FINE: il generatore video lavora con il proprio clock.
HLT                     ; Ferma la CPU. La FPGA continua a mostrare le due righe.
