; =============================================================================
; PROGRAMMA DIMOSTRATIVO
; =============================================================================
;
; Questo esempio mostra i concetti fondamentali del linguaggio assembly:
;
; - costanti simboliche con .equ;
; - blocco di codice con .code;
; - blocco dati con .data;
; - valori immediati;
; - label ed indirizzi calcolati automaticamente;
; - definizione di una variabile a 8 bit con .byte;
; - accesso alla memoria con STA e LDA;
; - rappresentazione little-endian degli indirizzi a 16 bit.
;
; La CPU usa un'architettura di Von Neumann: codice e dati condividono lo
; stesso spazio di memoria. .code e .data organizzano l'immagine generata
; dall'assembler, ma non rappresentano due memorie fisicamente separate.

; =============================================================================
; COSTANTI
; =============================================================================

; .equ associa un nome a un valore numerico.
; INITIAL_VALUE vale 0x0A, cioe 10 decimale.
; La direttiva non genera byte e non occupa memoria.
.equ INITIAL_VALUE, 0x0A

; =============================================================================
; BLOCCO CODE
; =============================================================================

; .code 0x0000 indica che la prima istruzione viene collocata all'indirizzo
; 0x0000. Questa scelta e importante perche il Program Counter parte da
; 0x0000 dopo il reset della CPU.
.code 0x0000

; LDI carica un valore immediato in un registro generale.
; INITIAL_VALUE viene sostituito dall'assembler con il valore 0x0A.
; Al termine dell'istruzione: R0 = 0x0A.
LDI R0, INITIAL_VALUE

; STA scrive il contenuto di R0 nella cella identificata dalla label counter.
; counter viene definita piu avanti: l'assembler ne calcola l'indirizzo con
; la prima passata e lo inserisce nell'istruzione durante la seconda passata.
STA R0, counter

; LDA legge la stessa cella di memoria e copia il valore nel registro R1.
; Dopo l'esecuzione: R0 = 0x0A, counter = 0x0A e R1 = 0x0A.
LDA R1, counter

; HLT arresta l'esecuzione. E importante terminare il codice prima dei dati,
; altrimenti la CPU potrebbe interpretare i byte delle variabili come opcode.
HLT

; =============================================================================
; BLOCCO DATA
; =============================================================================

; .data senza indirizzo colloca il blocco dati subito dopo l'ultimo byte del
; codice. In questo esempio il codice termina a 0x0008, quindi il primo byte
; libero e 0x0009.
;
; Se fosse necessario rispettare una mappa di memoria specifica, potremmo
; usare un indirizzo esplicito, per esempio: .data 0x0100
.data

; Una label e un nome simbolico associato all'indirizzo corrente.
; La sintassi generale e:
;
;     nome_variabile: .byte valore_iniziale
;
; counter: non genera byte, ma assegna il nome counter all'indirizzo 0x0009.
; .byte 0x00 riserva un byte e lo inizializza a zero.
; La CPU non conosce il nome counter: durante l'esecuzione vede solo 0x0009.
counter: .byte 0x00

; =============================================================================
; IMMAGINE FINALE DELLA MEMORIA
; =============================================================================
;
; L'assembler genera questa disposizione contigua:
;
; +-----------+--------+-----------------------------------------------+
; | Indirizzo | Byte   | Significato                                   |
; +-----------+--------+-----------------------------------------------+
; | 0x0000    | 0x20   | opcode LDI R0                                |
; | 0x0001    | 0x0A   | valore immediato INITIAL_VALUE               |
; | 0x0002    | 0x48   | opcode STA R0                                |
; | 0x0003    | 0x09   | byte basso dell'indirizzo di counter         |
; | 0x0004    | 0x00   | byte alto dell'indirizzo di counter          |
; | 0x0005    | 0x41   | opcode LDA R1                                |
; | 0x0006    | 0x09   | byte basso dell'indirizzo di counter         |
; | 0x0007    | 0x00   | byte alto dell'indirizzo di counter          |
; | 0x0008    | 0x01   | opcode HLT                                   |
; +-----------+--------+-----------------------------------------------+
; | 0x0009    | 0x00   | counter: primo byte del blocco data          |
; +-----------+--------+-----------------------------------------------+
;
; Gli indirizzi a 16 bit sono salvati in little-endian. L'indirizzo di
; counter e 0x0009, quindi viene scritto come:
;
;     byte basso = 0x09
;     byte alto  = 0x00
;
; Le istruzioni che usano counter diventano quindi:
;
;     STA R0, counter  -> 48 09 00
;     LDA R1, counter  -> 41 09 00
;
; Prima dell'esecuzione counter contiene il valore iniziale 0x00.
; Durante l'esecuzione STA sostituisce 0x00 con il valore 0x0A contenuto in R0.
