; HELLO WORLD / FROM 8 BIT COMPUTER - indirizzamento diretto tramite MAR.
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
; Il programma imposta esplicitamente CONTROL=0x1C prima di scrivere.
; Usa posizione e colore di reset. Non legge STATUS e non cancella
; lo schermo: l'attesa iniziale di READY e esterna al codice.
;
; COME PASSANO INDIRIZZO E DATO
; LDI carica un byte in R0: questa istruzione non scrive nella FPGA.
; STA contiene direttamente l'indirizzo del registro video da raggiungere.
; La CPU legge i due byte dell'indirizzo e li carica in MAR: prima il byte
; basso, poi quello alto. Esempio: 00 e 20 formano l'indirizzo 0x2000.
; Poi copia R0 in MDR, presenta MAR sul bus indirizzi e MDR sul bus dati,
; e attiva /WR per richiedere la scrittura alla FPGA.
; Con la CU corrente: T1 legge l'opcode, T2/T3 caricano MAR, T4 carica MDR,
; T5 prepara i bus, T6 attiva /WR, T7 chiude /WR mantenendo i bus,
; T8 rilascia i bus e torna al fetch. STA dura quindi 8 microstep.
;
; STA R0, 0x2000 scrive DATA: la FPGA interpreta R0 come carattere.
; STA R0, 0x2020 scrive CMD: la FPGA interpreta R0 come comando.
; STA R0, 0x2040 scrive CONTROL: configura cursore e avanzamento.
; Il puntatore interno della FPGA avanza dopo ogni carattere. MAR contiene
; sempre l'indirizzo del registro di accesso, non la posizione sullo schermo.
; Rispetto a video_hello_minimal.asm, qui non si usano LDX e STAI:
; ogni STA specifica la destinazione e IDX rimane invariato.
;
; RISULTATO ATTESO
; Riga 0: HELLO WORLD
; Riga 1: FROM 8 BIT COMPUTER
; 159 byte. Alla fine: PC=0x009F, MAR=0x2000, R0=MDR=0x52, CPU in HLT.
; Dopo l'ultima lettera il puntatore video e a riga 1, colonna 19.

.code 0x0000            ; Colloca il primo byte del programma in RAM a 0x0000.

; 0. CONFIGURAZIONE: abilita esplicitamente l'avanzamento automatico.
; CONTROL: D4=SCROLL, D3=WRAP, D2=AUTO_INCREMENT, D1=BLINK, D0=CURSORE.
; 00011100 abilita avanzamento, ritorno a capo e scorrimento, cursore nascosto.
LDI R0, 0x1C            ; Prepara 00011100: D2=1 abilita AUTO_INCREMENT.
STA R0, 0x2040          ; Scrive CONTROL: dopo ogni carattere la FPGA avanzera.

; 1. PRIMA RIGA: HELLO WORLD.
LDI R0, 0x48            ; Prepara in R0 il codice ASCII di 'H': 01001000.
STA R0, 0x2000          ; Scrive 'H' a riga 0, colonna 0; la FPGA avanza a colonna 1.
LDI R0, 0x45            ; Prepara in R0 il codice ASCII di 'E': 01000101.
STA R0, 0x2000          ; Scrive 'E' a riga 0, colonna 1; la FPGA avanza a colonna 2.
LDI R0, 0x4C            ; Prepara in R0 il codice ASCII di 'L': 01001100.
STA R0, 0x2000          ; Scrive 'L' a riga 0, colonna 2; la FPGA avanza a colonna 3.
STA R0, 0x2000          ; Riusa R0='L': scrive la seconda L a colonna 3 e avanza a 4.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STA R0, 0x2000          ; Scrive 'O' a riga 0, colonna 4; la FPGA avanza a colonna 5.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STA R0, 0x2000          ; Scrive uno spazio a riga 0, colonna 5; la FPGA avanza a colonna 6.
LDI R0, 0x57            ; Prepara in R0 il codice ASCII di 'W': 01010111.
STA R0, 0x2000          ; Scrive 'W' a riga 0, colonna 6; la FPGA avanza a colonna 7.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STA R0, 0x2000          ; Scrive 'O' a riga 0, colonna 7; la FPGA avanza a colonna 8.
LDI R0, 0x52            ; Prepara in R0 il codice ASCII di 'R': 01010010.
STA R0, 0x2000          ; Scrive 'R' a riga 0, colonna 8; la FPGA avanza a colonna 9.
LDI R0, 0x4C            ; Prepara in R0 il codice ASCII di 'L': 01001100.
STA R0, 0x2000          ; Scrive 'L' a riga 0, colonna 9; la FPGA avanza a colonna 10.
LDI R0, 0x44            ; Prepara in R0 il codice ASCII di 'D': 01000100.
STA R0, 0x2000          ; Scrive 'D' a riga 0, colonna 10; la FPGA avanza a colonna 11.

; 2. CAMBIO RIGA: il byte 0x03 viene inviato al registro CMD.
LDI R0, 0x03            ; Prepara in R0 il comando NEWLINE: 00000011.
STA R0, 0x2020          ; Invia 0x03 a CMD: passa a riga 1, colonna 0. Non stampa un carattere.

; 3. SECONDA RIGA: FROM 8 BIT COMPUTER. Le STA tornano su DATA.
LDI R0, 0x46            ; Prepara in R0 il codice ASCII di 'F': 01000110.
STA R0, 0x2000          ; Scrive 'F' a riga 1, colonna 0; la FPGA avanza a colonna 1.
LDI R0, 0x52            ; Prepara in R0 il codice ASCII di 'R': 01010010.
STA R0, 0x2000          ; Scrive 'R' a riga 1, colonna 1; la FPGA avanza a colonna 2.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STA R0, 0x2000          ; Scrive 'O' a riga 1, colonna 2; la FPGA avanza a colonna 3.
LDI R0, 0x4D            ; Prepara in R0 il codice ASCII di 'M': 01001101.
STA R0, 0x2000          ; Scrive 'M' a riga 1, colonna 3; la FPGA avanza a colonna 4.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STA R0, 0x2000          ; Scrive uno spazio a riga 1, colonna 4; la FPGA avanza a colonna 5.
LDI R0, 0x38            ; Prepara in R0 il codice ASCII di '8': 00111000.
STA R0, 0x2000          ; Scrive '8' a riga 1, colonna 5; la FPGA avanza a colonna 6.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STA R0, 0x2000          ; Scrive uno spazio a riga 1, colonna 6; la FPGA avanza a colonna 7.
LDI R0, 0x42            ; Prepara in R0 il codice ASCII di 'B': 01000010.
STA R0, 0x2000          ; Scrive 'B' a riga 1, colonna 7; la FPGA avanza a colonna 8.
LDI R0, 0x49            ; Prepara in R0 il codice ASCII di 'I': 01001001.
STA R0, 0x2000          ; Scrive 'I' a riga 1, colonna 8; la FPGA avanza a colonna 9.
LDI R0, 0x54            ; Prepara in R0 il codice ASCII di 'T': 01010100.
STA R0, 0x2000          ; Scrive 'T' a riga 1, colonna 9; la FPGA avanza a colonna 10.
LDI R0, 0x20            ; Prepara in R0 lo spazio ASCII: 00100000.
STA R0, 0x2000          ; Scrive uno spazio a riga 1, colonna 10; la FPGA avanza a colonna 11.
LDI R0, 0x43            ; Prepara in R0 il codice ASCII di 'C': 01000011.
STA R0, 0x2000          ; Scrive 'C' a riga 1, colonna 11; la FPGA avanza a colonna 12.
LDI R0, 0x4F            ; Prepara in R0 il codice ASCII di 'O': 01001111.
STA R0, 0x2000          ; Scrive 'O' a riga 1, colonna 12; la FPGA avanza a colonna 13.
LDI R0, 0x4D            ; Prepara in R0 il codice ASCII di 'M': 01001101.
STA R0, 0x2000          ; Scrive 'M' a riga 1, colonna 13; la FPGA avanza a colonna 14.
LDI R0, 0x50            ; Prepara in R0 il codice ASCII di 'P': 01010000.
STA R0, 0x2000          ; Scrive 'P' a riga 1, colonna 14; la FPGA avanza a colonna 15.
LDI R0, 0x55            ; Prepara in R0 il codice ASCII di 'U': 01010101.
STA R0, 0x2000          ; Scrive 'U' a riga 1, colonna 15; la FPGA avanza a colonna 16.
LDI R0, 0x54            ; Prepara in R0 il codice ASCII di 'T': 01010100.
STA R0, 0x2000          ; Scrive 'T' a riga 1, colonna 16; la FPGA avanza a colonna 17.
LDI R0, 0x45            ; Prepara in R0 il codice ASCII di 'E': 01000101.
STA R0, 0x2000          ; Scrive 'E' a riga 1, colonna 17; la FPGA avanza a colonna 18.
LDI R0, 0x52            ; Prepara in R0 il codice ASCII di 'R': 01010010.
STA R0, 0x2000          ; Scrive 'R' a riga 1, colonna 18; la FPGA avanza a colonna 19.

; 4. FINE: il generatore video lavora con il proprio clock.
HLT                     ; Ferma la CPU. La FPGA continua a mostrare le due righe.
